//! `AdminTakeDispute`: sending it, reading the node's answer, and what the
//! answer changes (the dispute row and this key's standing on the node).
//!
//! **Markers.** mostrod answers a take it refuses with
//! `CantDo(InvalidPubkey)` (`admin_take_dispute.rs`, `pubkey_event_can_solve`)
//! whether the key is no solver, or a solver who may not take that dispute
//! over. The 38386 does not say who holds a dispute, so the marker follows
//! the dispute's public status (CLAUDE.md → "Am I a solver on this node?"):
//!
//! | Status | Answer | Marker | Node |
//! |---|---|---|---|
//! | `initiated` | `InvalidPubkey` | `NotSolver` | solver: no |
//! | `in-progress` | `InvalidPubkey` | `CannotTakeOver` | unchanged (ambiguous) |
//! | any | `AdminTookDispute` | `Taken` | solver: yes |
//!
//! The status is the one stored when the take was sent, read again when the
//! answer arrives: a dispute another solver took meanwhile is `in-progress`
//! for the node, and its refusal must not call this key no solver.
//!
//! **Permission** is never learned here: mostrod gives an `in-progress`
//! dispute to the solver who holds it before it looks at permissions, so a
//! Read solver recovering its own dispute gets the same `AdminTookDispute` as
//! a Read-Write take-over (D12; phase 6 learns it from settle and cancel).
//!
//! **PoW.** The take carries the larger of the node's `pow` and
//! `pow_first_contact` (its kind 38385). mostrod 0.20 drops, unanswered, a
//! kind 14 from a key outside its spam gate that falls short of
//! `pow_first_contact` (`app.rs`, `accept_event`), and a solver key is in
//! the gate only while it holds an active dispute (`is_active_trade_pubkey`).
//! Mostrix sends admin actions with the base `pow` only
//! (`is_v2_first_contact_protocol_action`).

use mostro_core::dispute::SolverDisputeInfo;
use mostro_core::error::CantDoReason;
use mostro_core::message::{Action, Message, Payload};
use nostr_sdk::prelude::*;

use super::replies::{self, Request};
use crate::api::disputes::{DisputeStatus, DisputeSummary};
use crate::api::node_info::ProtocolSupport;
use crate::api::take::{
    InProgressDisputes, SolverStatus, TakeError, TakeOutcome, TakeResult, TakenDisputeSummary,
};
use crate::disputes::feed::Feed;
use crate::disputes::{oldest_first, DisputeRecord, TakenDispute};

/// How long a take waits for the node's answer: Mostrix's
/// `FETCH_EVENTS_TIMEOUT`.
pub(crate) const ANSWER_WAIT: std::time::Duration = std::time::Duration::from_secs(15);

/// How long the order's kind 38383 is looked for, for its fiat code.
const FIAT_CODE_WAIT: std::time::Duration = std::time::Duration::from_secs(5);

/// Kind of the node's public orders, which carry the fiat code.
const KIND_ORDER: u16 = 38383;

/// What the node's message says about one take.
#[derive(Debug, Clone)]
pub(crate) enum Answer {
    Took(Box<SolverDisputeInfo>),
    CantDo(Option<CantDoReason>),
    /// Anything else carrying the take's request id.
    Other,
}

/// Read `message` as the answer to a take of `dispute_id`.
pub(crate) fn read_answer(dispute_id: &str, message: &Message) -> Answer {
    let kind = message.get_inner_message_kind();
    match (&kind.action, &kind.payload) {
        (Action::AdminTookDispute, Some(Payload::Dispute(id, Some(info))))
            if id.to_string() == dispute_id =>
        {
            Answer::Took(Box::new(info.clone()))
        }
        (Action::CantDo, Some(Payload::CantDo(reason))) => Answer::CantDo(reason.clone()),
        (Action::CantDo, None) => Answer::CantDo(None),
        _ => Answer::Other,
    }
}

/// The marker for `answer` to a take sent while the dispute was
/// `status_at_send`, now `status_now` (`None` when no longer stored).
pub(crate) fn classify(
    answer: &Answer,
    status_at_send: DisputeStatus,
    status_now: Option<DisputeStatus>,
) -> (TakeOutcome, Option<String>) {
    match answer {
        Answer::Took(_) => (TakeOutcome::Taken, None),
        Answer::CantDo(Some(CantDoReason::InvalidPubkey)) => {
            let still_waiting = status_at_send == DisputeStatus::Initiated
                && status_now == Some(DisputeStatus::Initiated);
            if still_waiting {
                (TakeOutcome::NotSolver, None)
            } else {
                (TakeOutcome::CannotTakeOver, None)
            }
        }
        Answer::CantDo(reason) => (TakeOutcome::Refused, reason.as_ref().map(reason_marker)),
        Answer::Other => (TakeOutcome::Refused, None),
    }
}

/// A `CantDoReason` as the wire writes it (`not_found`).
fn reason_marker(reason: &CantDoReason) -> String {
    serde_json::to_value(reason)
        .ok()
        .and_then(|v| v.as_str().map(str::to_string))
        .unwrap_or_else(|| format!("{reason:?}"))
}

/// Apply the node's answer to `request`: store the take, or what it says
/// about this key, and return the result the caller sees. Runs whether or
/// not the caller is still waiting, so a late answer is kept too.
pub(crate) async fn settle(feed: &Feed, request: &Request, message: &Message) -> TakeResult {
    let answer = read_answer(&request.dispute_id, message);
    let status_now = match feed.row(&request.node, &request.dispute_id).await {
        Ok(row) => row.map(|r| r.status),
        Err(e) => {
            log::warn!("[take] stored dispute not read: {e}");
            None
        }
    };
    let (outcome, reason) = classify(&answer, request.status_at_send, status_now);
    match (&answer, outcome) {
        (Answer::Took(info), TakeOutcome::Taken) => {
            let existing = feed
                .row(&request.node, &request.dispute_id)
                .await
                .ok()
                .flatten();
            let taken = taken_from(
                info,
                &request.solver,
                existing.as_ref(),
                crate::rt::unix_now(),
            );
            if let Err(e) = feed
                .record_take(&request.node, &request.dispute_id, taken.clone())
                .await
            {
                log::warn!("[take] take not stored: {e}");
            }
            super::standing::set_status(&request.node, &request.solver, SolverStatus::Yes).await;
            if taken.fiat_code.is_none() {
                spawn_fiat_code_lookup(request.clone(), info.id.to_string());
            }
        }
        (_, TakeOutcome::NotSolver) => {
            super::standing::set_status(&request.node, &request.solver, SolverStatus::No).await;
        }
        _ => {}
    }
    log::info!(
        "[take] dispute {}…: {outcome:?}",
        &request.dispute_id[..8.min(request.dispute_id.len())]
    );
    TakeResult {
        mostro_pubkey: request.node.clone(),
        dispute_id: request.dispute_id.clone(),
        outcome,
        reason,
    }
}

/// The take as stored, from the node's `SolverDisputeInfo`. A take of the
/// same order already held by this key keeps when it was first taken and
/// the fiat code read for it.
pub(crate) fn taken_from(
    info: &SolverDisputeInfo,
    solver: &str,
    existing: Option<&DisputeRecord>,
    now: i64,
) -> TakenDispute {
    let order_id = info.id.to_string();
    let previous = existing
        .and_then(|row| row.taken.as_ref())
        .filter(|t| t.solver_pubkey == solver && t.order_id.as_deref() == Some(order_id.as_str()));
    let non_empty = |s: &str| (!s.is_empty()).then(|| s.to_string());
    TakenDispute {
        solver_pubkey: solver.to_string(),
        taken_at: previous.map_or(now, |t| t.taken_at),
        order_id: Some(order_id),
        order_kind: non_empty(&info.kind),
        amount: Some(info.amount),
        fiat_amount: Some(info.fiat_amount),
        fiat_code: previous.and_then(|t| t.fiat_code.clone()),
        payment_method: non_empty(&info.payment_method),
        premium: Some(info.premium),
        fee: Some(info.fee),
        initiator_pubkey: non_empty(&info.initiator_pubkey),
        buyer_pubkey: info.buyer_pubkey.clone(),
        seller_pubkey: info.seller_pubkey.clone(),
    }
}

/// The NIP-13 difficulty a take must carry on `node`.
pub(crate) fn take_pow(pow: Option<u32>, pow_first_contact: Option<u32>) -> u8 {
    let bits = pow.unwrap_or(0).max(pow_first_contact.unwrap_or(0));
    u8::try_from(bits).unwrap_or(u8::MAX)
}

/// A request id the node echoes: random, and within 53 bits so any JSON
/// reader keeps it whole.
fn new_request_id() -> u64 {
    (uuid::Uuid::new_v4().as_u128() as u64) & ((1 << 53) - 1)
}

/// Send `AdminTakeDispute` for `dispute_id` on the active node and wait for
/// the answer (`api::take::take_dispute`).
pub(crate) async fn take(dispute_id: &str) -> Result<TakeResult, TakeError> {
    let keys = crate::solver_slot::SOLVER_SLOT
        .keys()
        .await
        .ok_or(TakeError::NoKey)?;
    let node = crate::config::active_mostro_pubkey().ok_or(TakeError::NoNode)?;
    let pool = crate::api::relays::pool().map_err(|_| TakeError::NoRelays)?;
    let feed = crate::disputes::feed::feed().ok_or(TakeError::NoRelays)?;
    let router = replies::router().ok_or(TakeError::NoRelays)?;
    // The answer must have a subscription to land on before the request
    // leaves (a no-op when the router already follows this node and key).
    router
        .retarget(Some(node.clone()), Some(keys.clone()))
        .await;
    take_on(
        &router,
        &feed,
        &pool.client(),
        &keys,
        &node,
        dispute_id,
        ANSWER_WAIT,
    )
    .await
}

/// The take on explicit parts: the node's PoW first, then the request.
pub(crate) async fn take_on(
    router: &replies::Router,
    feed: &Feed,
    client: &Client,
    keys: &Keys,
    node: &str,
    dispute_id: &str,
    wait: std::time::Duration,
) -> Result<TakeResult, TakeError> {
    let pow = take_pow_on(client, node).await?;
    send_take(router, feed, client, keys, node, dispute_id, pow, wait).await
}

/// The PoW a take needs on `node`, from its cached kind 38385, or read from
/// the relays now when none is cached (a node chosen while they were down).
/// Without the info the PoW is unknown: a take sent with none would be
/// dropped unanswered by a node that asks for some, so it is not sent.
pub(crate) async fn take_pow_on(client: &Client, node: &str) -> Result<u8, TakeError> {
    let cached = crate::api::node_info::cached_node_info(node.to_string())
        .await
        .ok()
        .flatten();
    let info = match cached {
        Some(info) => info,
        None => crate::api::node_info::fetch_node_info_on(client, node)
            .await
            .map_err(|e| {
                log::warn!("[take] node info not read: {e}");
                TakeError::NodeInfoUnavailable
            })?
            .ok_or(TakeError::NodeInfoUnavailable)?,
    };
    if info.protocol_support == ProtocolSupport::Unsupported {
        return Err(TakeError::ProtocolUnsupported);
    }
    Ok(take_pow(info.pow, info.pow_first_contact))
}

/// The take itself, on explicit parts so tests drive it against a relay.
#[allow(clippy::too_many_arguments)]
pub(crate) async fn send_take(
    router: &replies::Router,
    feed: &Feed,
    client: &Client,
    keys: &Keys,
    node: &str,
    dispute_id: &str,
    pow: u8,
    wait: std::time::Duration,
) -> Result<TakeResult, TakeError> {
    let row = feed
        .row(node, dispute_id)
        .await
        .ok()
        .flatten()
        .ok_or(TakeError::UnknownDispute)?;
    if row.status.is_terminal() {
        return Err(TakeError::NotTakeable);
    }
    let dispute_uuid = uuid::Uuid::parse_str(dispute_id).map_err(|_| TakeError::UnknownDispute)?;
    let node_key = PublicKey::from_hex(node).map_err(|_| TakeError::NoNode)?;

    let request_id = new_request_id();
    let request = Request {
        node: node.to_string(),
        solver: keys.public_key().to_hex(),
        dispute_id: dispute_id.to_string(),
        status_at_send: row.status,
    };
    let answer = router.register(request_id, request)?;
    let message = Message::new_dispute(
        Some(dispute_uuid),
        Some(request_id),
        None,
        Action::AdminTakeDispute,
        None,
    );
    let sent = async {
        let event = wrap_mined(keys, &node_key, &message, pow)
            .await
            .map_err(|e| {
                log::warn!("[take] request not built: {e}");
                TakeError::SendFailed
            })?;
        let output = client.send_event(&event).await.map_err(|e| {
            log::warn!("[take] request not sent: {e}");
            TakeError::SendFailed
        })?;
        if output.success.is_empty() {
            log::warn!("[take] no relay took the request");
            return Err(TakeError::SendFailed);
        }
        Ok(())
    }
    .await;
    if let Err(e) = sent {
        router.forget(request_id);
        return Err(e);
    }

    match crate::rt::time::timeout(wait, answer).await {
        Ok(Ok(result)) => Ok(result),
        // Timed out, or the router dropped the request (the node or the
        // key changed). The request stays registered for a late answer.
        _ => Ok(TakeResult {
            mostro_pubkey: node.to_string(),
            dispute_id: dispute_id.to_string(),
            outcome: TakeOutcome::NoAnswer,
            reason: None,
        }),
    }
}

/// Wrap the request, mining its PoW. mostro-core mines on the calling thread
/// (`SingleThreadPow`): natively that runs on the blocking pool, off the
/// runtime's workers; the web has no other thread and the page waits
/// (AGENTS.md → "Accepted limits").
async fn wrap_mined(
    keys: &Keys,
    node: &PublicKey,
    message: &Message,
    pow: u8,
) -> anyhow::Result<Event> {
    #[cfg(not(target_arch = "wasm32"))]
    if pow > 0 {
        let (keys, node, message) = (keys.clone(), *node, message.clone());
        return tokio::task::spawn_blocking(move || {
            tokio::runtime::Handle::current().block_on(
                crate::nostr::transport::wrap_mostro_message(&keys, &node, &message, pow),
            )
        })
        .await?;
    }
    crate::nostr::transport::wrap_mostro_message(keys, node, message, pow).await
}

/// Look for the order's fiat code in its kind 38383 (the take's answer has
/// none, as Mostrix's `fetch_order_fiat_from_relay`), best effort.
fn spawn_fiat_code_lookup(request: Request, order_id: String) {
    crate::rt::spawn(async move {
        let Some(code) = fetch_fiat_code(&request.node, &order_id).await else {
            return;
        };
        if let Some(feed) = crate::disputes::feed::feed() {
            if let Err(e) = feed
                .record_fiat_code(
                    &request.node,
                    &request.dispute_id,
                    &request.solver,
                    &order_id,
                    &code,
                )
                .await
            {
                log::warn!("[take] fiat code not stored: {e}");
            }
        }
    });
}

async fn fetch_fiat_code(node: &str, order_id: &str) -> Option<String> {
    use futures_util::StreamExt;

    let node = PublicKey::from_hex(node).ok()?;
    let client = crate::api::relays::pool().ok()?.client();
    let filter = Filter::new()
        .kind(Kind::Custom(KIND_ORDER))
        .author(node)
        .identifier(order_id)
        .limit(5);
    let stream = client
        .stream_events(filter)
        .timeout(FIAT_CODE_WAIT)
        .await
        .ok()?;
    let authentic = stream.filter_map(move |(_, item)| async move {
        item.ok().filter(|e| {
            e.pubkey == node && e.kind == Kind::Custom(KIND_ORDER) && e.verify().is_ok()
        })
    });
    let newest = crate::nostr::first_answer::newest_answer(
        Box::pin(authentic),
        std::time::Duration::from_millis(750),
        crate::nostr::first_answer::replaceable_rank,
    )
    .await?;
    fiat_code_of(&newest)
}

/// The `f` tag of a kind 38383, upper-cased.
pub(crate) fn fiat_code_of(event: &Event) -> Option<String> {
    event.tags.iter().find_map(|tag| match tag.as_slice() {
        [name, value, ..] if name == "f" && !value.trim().is_empty() => {
            Some(value.trim().to_uppercase())
        }
        _ => None,
    })
}

// ── The lists ────────────────────────────────────────────────────────────────

/// The active node and the loaded key (hex), when both are there.
async fn node_and_solver() -> Option<(String, String)> {
    let node = crate::config::active_mostro_pubkey()?;
    let keys = crate::solver_slot::SOLVER_SLOT.keys().await?;
    Some((node, keys.public_key().to_hex()))
}

pub(crate) async fn in_progress() -> anyhow::Result<Option<InProgressDisputes>> {
    let Some((node, solver)) = node_and_solver().await else {
        return Ok(None);
    };
    let rows = crate::disputes::rows_with_status(&node, DisputeStatus::InProgress).await?;
    Ok(Some(InProgressDisputes {
        disputes: held_by(&rows, &solver, crate::rt::unix_now()),
        mostro_pubkey: node,
    }))
}

/// The rows `solver` holds, oldest first.
pub(crate) fn held_by(rows: &[DisputeRecord], solver: &str, now: i64) -> Vec<TakenDisputeSummary> {
    let mut list: Vec<TakenDisputeSummary> = rows
        .iter()
        .filter(|row| row.status == DisputeStatus::InProgress && !row.is_expired(now))
        .filter_map(|row| {
            let taken = row.taken.as_ref().filter(|t| t.solver_pubkey == solver)?;
            Some(TakenDisputeSummary {
                mostro_pubkey: row.mostro_pubkey.clone(),
                dispute_id: row.dispute_id.clone(),
                status: row.status,
                initiator: row.initiator,
                opened_at: row.opened_at,
                taken_at: taken.taken_at,
                amount: taken.amount,
                fiat_amount: taken.fiat_amount,
                fiat_code: taken.fiat_code.clone(),
            })
        })
        .collect();
    list.sort_by(|a, b| oldest_first((a.opened_at, &a.dispute_id), (b.opened_at, &b.dispute_id)));
    list
}

pub(crate) async fn recover_candidates() -> anyhow::Result<Option<Vec<DisputeSummary>>> {
    let Some((node, solver)) = node_and_solver().await else {
        return Ok(None);
    };
    let rows = crate::disputes::rows_with_status(&node, DisputeStatus::InProgress).await?;
    Ok(Some(not_held_by(&rows, &solver, crate::rt::unix_now())))
}

/// The `in-progress` rows `solver` does not hold here, oldest first: Mostrix's
/// Shift+R candidates (relay `in-progress`, missing from the local list).
pub(crate) fn not_held_by(rows: &[DisputeRecord], solver: &str, now: i64) -> Vec<DisputeSummary> {
    let mut list: Vec<DisputeSummary> = rows
        .iter()
        .filter(|row| row.status == DisputeStatus::InProgress && !row.is_expired(now))
        .filter(|row| row.taken.as_ref().is_none_or(|t| t.solver_pubkey != solver))
        .map(|row| row.summary(now))
        .collect();
    crate::disputes::sort_pending(&mut list);
    list
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use mostro_core::message::MessageKind;

    pub(crate) const DISPUTE: &str = "8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c";
    pub(crate) const ORDER: &str = "5b9e1f7e-6f0e-4b8a-9c3d-2e1f0a9b8c7d";

    pub(crate) fn info() -> SolverDisputeInfo {
        SolverDisputeInfo {
            id: uuid::Uuid::parse_str(ORDER).unwrap(),
            kind: "sell".into(),
            status: "dispute".into(),
            hash: None,
            preimage: None,
            order_previous_status: "active".into(),
            initiator_pubkey: "11".repeat(32),
            buyer_pubkey: Some("22".repeat(32)),
            seller_pubkey: Some("11".repeat(32)),
            initiator_full_privacy: false,
            counterpart_full_privacy: true,
            initiator_info: None,
            counterpart_info: None,
            premium: 2,
            payment_method: "SEPA".into(),
            amount: 75_000,
            fiat_amount: 50,
            fee: 225,
            routing_fee: 0,
            buyer_invoice: None,
            invoice_held_at: 1_700_000_000,
            taken_at: 1_699_999_000,
            created_at: 1_699_990_000,
        }
    }

    pub(crate) fn took(request_id: u64, dispute: &str) -> Message {
        let id = uuid::Uuid::parse_str(dispute).unwrap();
        Message::new_dispute(
            Some(id),
            Some(request_id),
            None,
            Action::AdminTookDispute,
            Some(Payload::Dispute(id, Some(info()))),
        )
    }

    pub(crate) fn cant_do(request_id: u64, reason: Option<CantDoReason>) -> Message {
        Message::cant_do(
            Some(uuid::Uuid::parse_str(DISPUTE).unwrap()),
            Some(request_id),
            Some(Payload::CantDo(reason)),
        )
    }

    use DisputeStatus::{InProgress, Initiated, Settled};

    // ── The marker tables, row by row ────────────────────────────────────

    #[test]
    fn initiated_and_invalid_pubkey_is_not_a_solver() {
        let answer = read_answer(DISPUTE, &cant_do(1, Some(CantDoReason::InvalidPubkey)));
        assert_eq!(
            classify(&answer, Initiated, Some(Initiated)),
            (TakeOutcome::NotSolver, None)
        );
    }

    #[test]
    fn in_progress_and_invalid_pubkey_cannot_take_over() {
        let answer = read_answer(DISPUTE, &cant_do(1, Some(CantDoReason::InvalidPubkey)));
        assert_eq!(
            classify(&answer, InProgress, Some(InProgress)),
            (TakeOutcome::CannotTakeOver, None)
        );
    }

    /// Another solver took it between Pending and the answer: the node
    /// refused a take-over, not a stranger, so this key is not called no
    /// solver.
    #[test]
    fn a_dispute_taken_meanwhile_is_not_read_as_not_a_solver() {
        let answer = read_answer(DISPUTE, &cant_do(1, Some(CantDoReason::InvalidPubkey)));
        assert_eq!(
            classify(&answer, Initiated, Some(InProgress)).0,
            TakeOutcome::CannotTakeOver
        );
    }

    #[test]
    fn admin_took_dispute_is_taken_whatever_the_status() {
        let answer = read_answer(DISPUTE, &took(1, DISPUTE));
        assert!(matches!(answer, Answer::Took(_)));
        for (sent, now) in [(Initiated, Some(Initiated)), (InProgress, Some(InProgress))] {
            assert_eq!(classify(&answer, sent, now), (TakeOutcome::Taken, None));
        }
    }

    #[test]
    fn another_cant_do_is_refused_with_its_reason() {
        let answer = read_answer(DISPUTE, &cant_do(1, Some(CantDoReason::NotFound)));
        assert_eq!(
            classify(&answer, Initiated, Some(Initiated)),
            (TakeOutcome::Refused, Some("not_found".into()))
        );
        let bare = read_answer(DISPUTE, &cant_do(1, None));
        assert_eq!(
            classify(&bare, Initiated, None),
            (TakeOutcome::Refused, None)
        );
    }

    /// An AdminTookDispute about another dispute is not this take's answer.
    #[test]
    fn a_took_for_another_dispute_is_not_a_take() {
        let other = "1f2e3d4c-5b6a-4978-8695-a4b3c2d1e0f9";
        assert!(matches!(
            read_answer(DISPUTE, &took(1, other)),
            Answer::Other
        ));
        let unrelated = Message::Order(MessageKind::new(
            None,
            Some(1),
            None,
            Action::Released,
            None,
        ));
        assert!(matches!(read_answer(DISPUTE, &unrelated), Answer::Other));
    }

    // ── What is stored ───────────────────────────────────────────────────

    #[test]
    fn the_take_keeps_the_order_data_and_the_key() {
        let taken = taken_from(&info(), &"aa".repeat(32), None, 1_800_000_000);
        assert_eq!(taken.solver_pubkey, "aa".repeat(32));
        assert_eq!(taken.taken_at, 1_800_000_000);
        assert_eq!(taken.order_id.as_deref(), Some(ORDER));
        assert_eq!(taken.order_kind.as_deref(), Some("sell"));
        assert_eq!(taken.amount, Some(75_000));
        assert_eq!(taken.fiat_amount, Some(50));
        assert_eq!(taken.fiat_code, None, "the answer carries none");
        assert_eq!(taken.payment_method.as_deref(), Some("SEPA"));
        assert_eq!(taken.premium, Some(2));
        assert_eq!(taken.fee, Some(225));
        assert_eq!(taken.buyer_pubkey, Some("22".repeat(32)));
        assert_eq!(taken.seller_pubkey, Some("11".repeat(32)));
    }

    /// Recovering a dispute this key holds keeps when it was taken and the
    /// fiat code already read; another key's take is not inherited.
    #[test]
    fn a_retake_keeps_the_first_take_time_of_the_same_key() {
        let me = "aa".repeat(32);
        let mut row = crate::disputes::tests::row_with(InProgress);
        row.taken = Some(TakenDispute {
            fiat_code: Some("EUR".into()),
            ..taken_from(&info(), &me, None, 1_000)
        });
        let again = taken_from(&info(), &me, Some(&row), 2_000);
        assert_eq!(again.taken_at, 1_000);
        assert_eq!(again.fiat_code.as_deref(), Some("EUR"));
        let other = taken_from(&info(), &"bb".repeat(32), Some(&row), 2_000);
        assert_eq!(other.taken_at, 2_000);
        assert_eq!(other.fiat_code, None);
    }

    #[test]
    fn the_pow_is_the_larger_of_the_two() {
        assert_eq!(take_pow(None, None), 0);
        assert_eq!(take_pow(Some(8), None), 8);
        assert_eq!(take_pow(Some(0), Some(16)), 16);
        assert_eq!(take_pow(Some(20), Some(16)), 20);
        assert_eq!(take_pow(Some(9_999), None), u8::MAX);
    }

    #[test]
    fn request_ids_fit_53_bits() {
        for _ in 0..1_000 {
            assert!(new_request_id() < (1 << 53));
        }
    }

    // ── The lists ────────────────────────────────────────────────────────

    #[test]
    fn in_progress_is_this_keys_and_recover_is_the_rest() {
        let (me, other) = ("aa".repeat(32), "bb".repeat(32));
        let row = |id: &str, status, solver: Option<&str>, opened: i64| DisputeRecord {
            dispute_id: id.into(),
            opened_at: Some(opened),
            taken: solver.map(|s| taken_from(&info(), s, None, 5)),
            ..crate::disputes::tests::row_with(status)
        };
        let rows = vec![
            row("mine-new", InProgress, Some(&me), 300),
            row("mine-old", InProgress, Some(&me), 100),
            row("other-key", InProgress, Some(&other), 50),
            row("nobody", InProgress, None, 200),
            row("mine-closed", Settled, Some(&me), 10),
            row("waiting", Initiated, None, 10),
        ];
        let held: Vec<_> = held_by(&rows, &me, 0)
            .into_iter()
            .map(|d| d.dispute_id)
            .collect();
        assert_eq!(held, vec!["mine-old", "mine-new"]);
        let candidates: Vec<_> = not_held_by(&rows, &me, 0)
            .into_iter()
            .map(|d| d.dispute_id)
            .collect();
        assert_eq!(candidates, vec!["other-key", "nobody"]);
    }

    #[test]
    fn the_fiat_code_is_the_f_tag() {
        let keys = Keys::generate();
        let event = EventBuilder::new(Kind::Custom(KIND_ORDER), "")
            .tags([Tag::identifier(ORDER), Tag::parse(["f", "eur"]).unwrap()])
            .finalize(&keys)
            .unwrap();
        assert_eq!(fiat_code_of(&event).as_deref(), Some("EUR"));
        let bare = EventBuilder::new(Kind::Custom(KIND_ORDER), "")
            .finalize(&keys)
            .unwrap();
        assert_eq!(fiat_code_of(&bare), None);
    }
}
