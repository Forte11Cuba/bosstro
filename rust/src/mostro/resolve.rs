//! `AdminSettle` / `AdminCancel`: sending them, reading the node's answer,
//! and what the answer changes (the dispute row and this key's standing).
//!
//! **The order id.** mostrod finds the order from the message's `id`
//! (`admin_settle.rs`, `get_order`), so the request carries the order id the
//! take stored from `SolverDisputeInfo`, never the dispute id. Without one,
//! nothing is sent. No payload: mostrod reads none as "release every bond,
//! slash none" (bond slash is post-MVP).
//!
//! **Answers** (`admin_settle.rs`, `admin_cancel.rs`, mostrod 0.20; the
//! handlers check in this order: the assigned solver, the permission, a
//! cooperative cancel, the order's status):
//!
//! | Answer | Outcome | Effect |
//! |---|---|---|
//! | `AdminSettled` (to a settle) | `PaidBuyer` | closed, paid the buyer; permission read-write |
//! | `AdminCanceled` (to a cancel) | `RefundedSeller` | closed, refunded the seller; permission read-write |
//! | `CooperativeCancelAccepted` | `CooperativelyCanceled` | closed by the parties; permission read-write |
//! | `CantDo(NotAuthorized)` | `ReadOnlySolver` | permission read |
//! | `CantDo(IsNotYourDispute)`, `CantDo(DisputeTakenByAdmin)` | `TakenOver` | this key's take dropped |
//! | `CantDo(InvalidOrderStatus)`, `CantDo(NotAllowedByStatus)` | `NotInDispute` | none: the 38386 reconciles |
//! | `CantDo(InvalidPayload)`, to a request that slashed a bond | `BondNotPosted` | none: a party it names posted no bond |
//! | another `CantDo`, anything else | `Refused` | none |
//! | nothing in time | `NoAnswer` | none; a late answer is still applied |
//!
//! `CooperativeCancelAccepted` comes after the permission check in both
//! handlers, so it shows Read-Write as much as a settle does.
//!
//! **No answer.** A settle cannot be undone, and mostrod may have paid
//! although its answer never arrived (or it failed inside: an LND error is
//! logged by the node and answered with nothing). So nothing here retries.
//! A request the solver sends again after the node did act is refused by the
//! order's status (`InvalidOrderStatus` for a settle, `NotAllowedByStatus`
//! for a cancel), which reads `NotInDispute`.
//!
//! **PoW** is a take's: the larger of the node's `pow` and
//! `pow_first_contact`. A key holding an active dispute is inside mostrod's
//! spam gate and needs only `pow`, but a key whose dispute was taken over is
//! not, and its request would be dropped unanswered below
//! `pow_first_contact`.

use mostro_core::error::CantDoReason;
use mostro_core::message::{Action, BondResolution, Message, Payload};
use nostr_sdk::prelude::*;

use super::replies::{self, Purpose, Reply, Request};
use super::take::{new_request_id, reason_marker, take_pow_on, wrap_mined, ANSWER_WAIT};
use crate::api::resolve::{
    BondSlash, Resolution, ResolveError, ResolveOutcome, ResolveResult, ResolvedAs,
};
use crate::api::take::{SolverPermission, TakeError};
use crate::disputes::feed::Feed;

/// What the node's message says about one resolution.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) enum Answer {
    /// `AdminSettled` to a settle, `AdminCanceled` to a cancel, about the
    /// order that was asked for.
    Done,
    /// `CooperativeCancelAccepted` about that order.
    CooperativelyCanceled,
    CantDo(Option<CantDoReason>),
    /// Anything else carrying the request's id.
    Other,
}

/// The action that carries `resolution`, and the one that confirms it.
pub(crate) fn actions_of(resolution: Resolution) -> (Action, Action) {
    match resolution {
        Resolution::PayBuyer => (Action::AdminSettle, Action::AdminSettled),
        Resolution::RefundSeller => (Action::AdminCancel, Action::AdminCanceled),
    }
}

/// The request for `resolution` of `order_id`.
pub(crate) fn request_message(
    resolution: Resolution,
    order_id: uuid::Uuid,
    request_id: u64,
    bond: BondSlash,
) -> Message {
    Message::new_order(
        Some(order_id),
        Some(request_id),
        None,
        actions_of(resolution).0,
        bond_payload(bond),
    )
}

/// The payload that carries `bond`: none when nothing is slashed (mostrod
/// reads none as "release every bond", as Mostrix's `to_optional_payload`),
/// mostro-core's `BondResolution` otherwise.
pub(crate) fn bond_payload(bond: BondSlash) -> Option<Payload> {
    let (slash_seller, slash_buyer) = bond.slashes();
    (slash_seller || slash_buyer).then_some(Payload::BondResolution(BondResolution {
        slash_seller,
        slash_buyer,
    }))
}

/// Read `message` as the answer to `resolution` of `order_id`. A
/// confirmation counts only when it is the one that action gets (as
/// Mostrix's `admin_finalize_ack`) and names that order.
pub(crate) fn read_answer(resolution: Resolution, order_id: &str, message: &Message) -> Answer {
    let kind = message.get_inner_message_kind();
    let about_order = kind.id.is_some_and(|id| id.to_string() == order_id);
    let confirmed_by = actions_of(resolution).1;
    match (&kind.action, &kind.payload) {
        (action, _) if *action == confirmed_by && about_order => Answer::Done,
        (Action::CooperativeCancelAccepted, _) if about_order => Answer::CooperativelyCanceled,
        (Action::CantDo, Some(Payload::CantDo(reason))) => Answer::CantDo(reason.clone()),
        (Action::CantDo, None) => Answer::CantDo(None),
        _ => Answer::Other,
    }
}

/// The outcome of `answer` to `resolution`, and the refusal's reason when it
/// is worth carrying.
pub(crate) fn classify(
    answer: &Answer,
    resolution: Resolution,
    bond: BondSlash,
) -> (ResolveOutcome, Option<String>) {
    match answer {
        Answer::Done => (
            match resolution {
                Resolution::PayBuyer => ResolveOutcome::PaidBuyer,
                Resolution::RefundSeller => ResolveOutcome::RefundedSeller,
            },
            None,
        ),
        Answer::CooperativelyCanceled => (ResolveOutcome::CooperativelyCanceled, None),
        Answer::CantDo(Some(CantDoReason::NotAuthorized)) => (ResolveOutcome::ReadOnlySolver, None),
        Answer::CantDo(Some(CantDoReason::IsNotYourDispute | CantDoReason::DisputeTakenByAdmin)) => {
            (ResolveOutcome::TakenOver, None)
        }
        Answer::CantDo(Some(
            reason @ (CantDoReason::InvalidOrderStatus
            | CantDoReason::NotAllowedByStatus
            | CantDoReason::InvalidDisputeStatus),
        )) => (ResolveOutcome::NotInDispute, Some(reason_marker(reason))),
        // Only a slash can make a well-formed request's payload invalid.
        Answer::CantDo(Some(CantDoReason::InvalidPayload)) if bond != BondSlash::NoSlash => {
            (ResolveOutcome::BondNotPosted, None)
        }
        Answer::CantDo(reason) => (ResolveOutcome::Refused, reason.as_ref().map(reason_marker)),
        Answer::Other => (ResolveOutcome::Refused, None),
    }
}

/// The bonds a resolution that closed as `closed` slashed: what it asked for,
/// unless the parties had cancelled already (mostrod answers
/// `CooperativeCancelAccepted` before it reads the payload, so nothing is
/// slashed then).
pub(crate) fn slashed(closed: ResolvedAs, bond: BondSlash) -> BondSlash {
    match closed {
        ResolvedAs::CooperativelyCanceled => BondSlash::NoSlash,
        _ => bond,
    }
}

/// How the dispute closed, for the outcomes that close it.
pub(crate) fn resolved_as(outcome: ResolveOutcome) -> Option<ResolvedAs> {
    match outcome {
        ResolveOutcome::PaidBuyer => Some(ResolvedAs::PaidBuyer),
        ResolveOutcome::RefundedSeller => Some(ResolvedAs::RefundedSeller),
        ResolveOutcome::CooperativelyCanceled => Some(ResolvedAs::CooperativelyCanceled),
        _ => None,
    }
}

/// Apply the node's answer to `request`, a `resolution` of `order_id`: close
/// the dispute, learn the permission, or drop a take that is no longer this
/// key's; and return what the caller sees. Runs whether or not the caller is
/// still waiting, so a late answer is applied too.
pub(crate) async fn apply(
    feed: &Feed,
    request: &Request,
    resolution: Resolution,
    order_id: &str,
    bond: BondSlash,
    message: &Message,
) -> ResolveResult {
    let answer = read_answer(resolution, order_id, message);
    let (outcome, reason) = classify(&answer, resolution, bond);
    let (node, solver, dispute) = (&request.node, &request.solver, &request.dispute_id);
    if let Some(closed) = resolved_as(outcome) {
        if let Err(e) = feed
            .record_resolution(node, dispute, solver, order_id, closed, slashed(closed, bond))
            .await
        {
            log::warn!("[resolve] resolution not stored: {e}");
        }
        super::standing::set_permission(node, solver, SolverPermission::ReadWrite).await;
    }
    match outcome {
        ResolveOutcome::ReadOnlySolver => {
            super::standing::set_permission(node, solver, SolverPermission::Read).await;
        }
        ResolveOutcome::TakenOver => {
            if let Err(e) = feed.drop_take(node, dispute, solver, order_id).await {
                log::warn!("[resolve] take not dropped: {e}");
            }
        }
        _ => {}
    }
    // What changed the standing alone, or nothing, still makes the screens
    // read again (the "no answer yet" warning goes, the permission shows).
    feed.announce_stored(node, dispute).await;
    log::info!(
        "[resolve] dispute {}…: {resolution:?}, bonds {bond:?} → {outcome:?}",
        &dispute[..8.min(dispute.len())]
    );
    ResolveResult {
        mostro_pubkey: node.clone(),
        dispute_id: dispute.clone(),
        resolution,
        bond,
        outcome,
        reason,
    }
}

/// Send `resolution` of `dispute_id` on the active node and wait for the
/// answer (`api::resolve::resolve_dispute`).
pub(crate) async fn resolve(
    dispute_id: &str,
    resolution: Resolution,
    bond: BondSlash,
) -> Result<ResolveResult, ResolveError> {
    let keys = crate::solver_slot::SOLVER_SLOT
        .keys()
        .await
        .ok_or(ResolveError::NoKey)?;
    let node = crate::config::active_mostro_pubkey().ok_or(ResolveError::NoNode)?;
    let pool = crate::api::relays::pool().map_err(|_| ResolveError::NoRelays)?;
    let feed = crate::disputes::feed::feed().ok_or(ResolveError::NoRelays)?;
    let router = replies::router().ok_or(ResolveError::NoRelays)?;
    router
        .retarget(Some(node.clone()), Some(keys.clone()))
        .await;
    resolve_on(
        &router,
        &feed,
        &pool.client(),
        &keys,
        &node,
        dispute_id,
        resolution,
        bond,
        ANSWER_WAIT,
    )
    .await
}

/// The order id of `dispute_id`, if this key may resolve it: stored, held by
/// `solver`, open, and naming its order.
pub(crate) async fn order_to_resolve(
    feed: &Feed,
    node: &str,
    solver: &str,
    dispute_id: &str,
) -> Result<uuid::Uuid, ResolveError> {
    let row = feed
        .row(node, dispute_id)
        .await
        .ok()
        .flatten()
        .ok_or(ResolveError::UnknownDispute)?;
    let taken = row
        .taken
        .as_ref()
        .filter(|t| t.solver_pubkey == solver)
        .ok_or(ResolveError::NotYours)?;
    if row.status.is_terminal() || taken.resolved_as.is_some() {
        return Err(ResolveError::Closed);
    }
    let order_id = taken.order_id.as_deref().ok_or(ResolveError::NoOrderId)?;
    uuid::Uuid::parse_str(order_id).map_err(|_| ResolveError::NoOrderId)
}

/// The resolution on explicit parts: the dispute is checked, then the node's
/// PoW is read, then the request goes.
#[allow(clippy::too_many_arguments)]
pub(crate) async fn resolve_on(
    router: &replies::Router,
    feed: &Feed,
    client: &Client,
    keys: &Keys,
    node: &str,
    dispute_id: &str,
    resolution: Resolution,
    bond: BondSlash,
    wait: std::time::Duration,
) -> Result<ResolveResult, ResolveError> {
    order_to_resolve(feed, node, &keys.public_key().to_hex(), dispute_id).await?;
    let pow = take_pow_on(client, node).await.map_err(|e| match e {
        TakeError::ProtocolUnsupported => ResolveError::ProtocolUnsupported,
        _ => ResolveError::NodeInfoUnavailable,
    })?;
    send_resolution(router, feed, client, keys, node, dispute_id, resolution, bond, pow, wait).await
}

/// The request itself, on explicit parts so tests drive it against a relay.
#[allow(clippy::too_many_arguments)]
pub(crate) async fn send_resolution(
    router: &replies::Router,
    feed: &Feed,
    client: &Client,
    keys: &Keys,
    node: &str,
    dispute_id: &str,
    resolution: Resolution,
    bond: BondSlash,
    pow: u8,
    wait: std::time::Duration,
) -> Result<ResolveResult, ResolveError> {
    let solver = keys.public_key().to_hex();
    let order_id = order_to_resolve(feed, node, &solver, dispute_id).await?;
    let node_key = PublicKey::from_hex(node).map_err(|_| ResolveError::NoNode)?;

    let request_id = new_request_id();
    let request = Request {
        node: node.to_string(),
        solver,
        dispute_id: dispute_id.to_string(),
        purpose: Purpose::Resolve {
            resolution,
            order_id: order_id.to_string(),
            bond,
        },
    };
    let answer = router
        .register(request_id, request)
        .map_err(|_| ResolveError::AlreadyResolving)?;
    let message = request_message(resolution, order_id, request_id, bond);
    let sent = async {
        let event = wrap_mined(keys, &node_key, &message, pow)
            .await
            .map_err(|e| {
                log::warn!("[resolve] request not built: {e}");
                ResolveError::SendFailed
            })?;
        let output = client.send_event(&event).await.map_err(|e| {
            log::warn!("[resolve] request not sent: {e}");
            ResolveError::SendFailed
        })?;
        if output.success.is_empty() {
            log::warn!("[resolve] no relay took the request");
            return Err(ResolveError::SendFailed);
        }
        Ok(())
    }
    .await;
    if let Err(e) = sent {
        router.forget(request_id);
        return Err(e);
    }

    match crate::rt::time::timeout(wait, answer).await {
        Ok(Ok(Reply::Resolve(result))) => Ok(result),
        // Timed out, or the router dropped the request (the node or the key
        // changed). It stays registered for a late answer; nothing is resent.
        _ => Ok(ResolveResult {
            mostro_pubkey: node.to_string(),
            dispute_id: dispute_id.to_string(),
            resolution,
            bond,
            outcome: ResolveOutcome::NoAnswer,
            reason: None,
        }),
    }
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use crate::mostro::take::tests::{DISPUTE, ORDER};

    pub(crate) fn order() -> uuid::Uuid {
        uuid::Uuid::parse_str(ORDER).unwrap()
    }

    /// The node's confirmation of `resolution`, as mostrod enqueues it
    /// (`enqueue_order_msg(request_id, Some(order.id), AdminSettled, None…)`).
    pub(crate) fn confirmed(request_id: u64, resolution: Resolution) -> Message {
        Message::new_order(
            Some(order()),
            Some(request_id),
            None,
            actions_of(resolution).1,
            None,
        )
    }

    pub(crate) fn coop_accepted(request_id: u64) -> Message {
        Message::new_order(
            Some(order()),
            Some(request_id),
            None,
            Action::CooperativeCancelAccepted,
            None,
        )
    }

    /// A refusal as mostrod's `manage_errors` sends it: the request's id
    /// (the order's) and the reason.
    pub(crate) fn refused(request_id: u64, reason: CantDoReason) -> Message {
        Message::cant_do(Some(order()), Some(request_id), Some(Payload::CantDo(Some(reason))))
    }

    use Resolution::{PayBuyer, RefundSeller};

    #[test]
    fn the_request_carries_the_order_id_not_the_dispute_id() {
        for (resolution, action) in [(PayBuyer, Action::AdminSettle), (RefundSeller, Action::AdminCancel)] {
            let message = request_message(resolution, order(), 7, BondSlash::NoSlash);
            let kind = message.get_inner_message_kind();
            assert_eq!(kind.action, action);
            assert_eq!(kind.id.unwrap().to_string(), ORDER);
            assert_ne!(kind.id.unwrap().to_string(), DISPUTE);
            assert_eq!(kind.request_id, Some(7));
            assert!(kind.payload.is_none(), "no BondResolution: release all, slash none");
            assert!(message.verify(), "mostrod's own check of the shape");
            // The order variant, as mostrod's handler tests build it.
            assert!(matches!(message, Message::Order(_)));
        }
    }

    // ── Each row of the answer table ─────────────────────────────────────

    #[test]
    fn a_confirmation_resolves_as_asked() {
        let answer = read_answer(PayBuyer, ORDER, &confirmed(1, PayBuyer));
        assert_eq!(classify(&answer, PayBuyer, BondSlash::NoSlash), (ResolveOutcome::PaidBuyer, None));
        let answer = read_answer(RefundSeller, ORDER, &confirmed(1, RefundSeller));
        assert_eq!(classify(&answer, RefundSeller, BondSlash::NoSlash), (ResolveOutcome::RefundedSeller, None));
    }

    /// The other action's confirmation, or one about another order, is not
    /// this request's answer (Mostrix's `admin_finalize_ack`).
    #[test]
    fn only_the_matching_confirmation_of_this_order_counts() {
        assert_eq!(read_answer(PayBuyer, ORDER, &confirmed(1, RefundSeller)), Answer::Other);
        assert_eq!(read_answer(RefundSeller, ORDER, &confirmed(1, PayBuyer)), Answer::Other);
        let other = "1f2e3d4c-5b6a-4978-8695-a4b3c2d1e0f9";
        assert_eq!(read_answer(PayBuyer, other, &confirmed(1, PayBuyer)), Answer::Other);
        assert_eq!(
            classify(&Answer::Other, PayBuyer, BondSlash::NoSlash),
            (ResolveOutcome::Refused, None)
        );
    }

    #[test]
    fn a_cooperative_cancel_is_closed_without_an_error() {
        for resolution in [PayBuyer, RefundSeller] {
            let answer = read_answer(resolution, ORDER, &coop_accepted(1));
            assert_eq!(
                classify(&answer, resolution, BondSlash::NoSlash),
                (ResolveOutcome::CooperativelyCanceled, None)
            );
        }
    }

    #[test]
    fn not_authorized_is_a_read_only_solver() {
        let answer = read_answer(PayBuyer, ORDER, &refused(1, CantDoReason::NotAuthorized));
        assert_eq!(classify(&answer, PayBuyer, BondSlash::NoSlash), (ResolveOutcome::ReadOnlySolver, None));
    }

    #[test]
    fn not_your_dispute_and_taken_by_admin_are_a_take_over() {
        for reason in [CantDoReason::IsNotYourDispute, CantDoReason::DisputeTakenByAdmin] {
            let answer = read_answer(RefundSeller, ORDER, &refused(1, reason));
            assert_eq!(classify(&answer, RefundSeller, BondSlash::NoSlash), (ResolveOutcome::TakenOver, None));
        }
    }

    #[test]
    fn a_refusal_by_status_is_not_in_dispute_with_its_reason() {
        for (reason, marker) in [
            (CantDoReason::InvalidOrderStatus, "invalid_order_status"),
            (CantDoReason::NotAllowedByStatus, "not_allowed_by_status"),
        ] {
            let answer = read_answer(PayBuyer, ORDER, &refused(1, reason));
            assert_eq!(
                classify(&answer, PayBuyer, BondSlash::NoSlash),
                (ResolveOutcome::NotInDispute, Some(marker.into()))
            );
        }
    }

    #[test]
    fn another_refusal_keeps_its_reason() {
        let answer = read_answer(PayBuyer, ORDER, &refused(1, CantDoReason::NotFound));
        assert_eq!(
            classify(&answer, PayBuyer, BondSlash::NoSlash),
            (ResolveOutcome::Refused, Some("not_found".into()))
        );
        let bare = Message::cant_do(Some(order()), Some(1), None);
        assert_eq!(
            classify(&read_answer(PayBuyer, ORDER, &bare), PayBuyer, BondSlash::NoSlash),
            (ResolveOutcome::Refused, None)
        );
    }

    #[test]
    fn only_closing_outcomes_close() {
        assert_eq!(resolved_as(ResolveOutcome::PaidBuyer), Some(ResolvedAs::PaidBuyer));
        assert_eq!(
            resolved_as(ResolveOutcome::RefundedSeller),
            Some(ResolvedAs::RefundedSeller)
        );
        assert_eq!(
            resolved_as(ResolveOutcome::CooperativelyCanceled),
            Some(ResolvedAs::CooperativelyCanceled)
        );
        for open in [
            ResolveOutcome::ReadOnlySolver,
            ResolveOutcome::TakenOver,
            ResolveOutcome::NotInDispute,
            ResolveOutcome::Refused,
            ResolveOutcome::NoAnswer,
        ] {
            assert_eq!(resolved_as(open), None);
        }
    }

}

/// The resolution end to end: a simulated mostrod on a local relay answers
/// the request as `admin_settle.rs` / `admin_cancel.rs` do, and the router
/// applies the answer.
#[cfg(all(test, not(target_arch = "wasm32")))]
mod rig_tests {
    use std::sync::atomic::{AtomicUsize, Ordering};
    use std::sync::{Arc, Mutex};
    use std::time::Duration;

    use super::tests::{confirmed, coop_accepted, order, refused};
    use super::*;
    use crate::api::disputes::DisputeStatus;
    use crate::api::take::{SolverPermission, SolverStatus};
    use crate::disputes::event::tests::mostrod_event;
    use crate::mostro::replies::tests::{answer_with, silent, Rig, Script, WAIT};
    use crate::mostro::take::tests::{info, DISPUTE, ORDER};
    use crate::mostro::take::taken_from;
    use Resolution::{PayBuyer, RefundSeller};

    /// A rig whose dispute this solver took (`in-progress`, with its order).
    async fn taken_rig(script: Script) -> Rig {
        let rig = Rig::new("in-progress", script).await;
        let taken = taken_from(&info(), &rig.solver_hex(), None, crate::rt::unix_now());
        rig.feed
            .record_take(&rig.node_hex(), DISPUTE, taken)
            .await
            .unwrap();
        rig
    }

    async fn resolve(rig: &Rig, resolution: Resolution, wait: Duration) -> Result<ResolveResult, ResolveError> {
        resolve_with(rig, resolution, BondSlash::NoSlash, wait).await
    }

    async fn resolve_with(
        rig: &Rig,
        resolution: Resolution,
        bond: BondSlash,
        wait: Duration,
    ) -> Result<ResolveResult, ResolveError> {
        send_resolution(
            &rig.router,
            &rig.feed,
            &rig.client,
            &rig.solver,
            &rig.node_hex(),
            DISPUTE,
            resolution,
            bond,
            0,
            wait,
        )
        .await
    }

    async fn permission(rig: &Rig) -> SolverPermission {
        crate::mostro::standing::read(&rig.node_hex(), &rig.solver_hex())
            .await
            .permission
    }

    /// What the daemon was sent, and how many times.
    #[derive(Default)]
    struct Received {
        messages: Mutex<Vec<Message>>,
        count: AtomicUsize,
    }

    fn recording(received: Arc<Received>, answer: fn(u64) -> Vec<Message>) -> Script {
        Arc::new(move |rid, message| {
            received.count.fetch_add(1, Ordering::SeqCst);
            received.messages.lock().unwrap().push(message.clone());
            answer(rid)
        })
    }

    async fn until(mut done: impl AsyncFnMut() -> bool) {
        for _ in 0..100 {
            if done().await {
                return;
            }
            tokio::time::sleep(Duration::from_millis(50)).await;
        }
        panic!("never happened");
    }

    // ── Each answer, with its effect ─────────────────────────────────────

    #[tokio::test]
    async fn admin_settled_closes_it_as_paid_and_shows_read_write() {
        let received = Arc::new(Received::default());
        let rig = taken_rig(recording(received.clone(), |rid| {
            vec![confirmed(rid, PayBuyer)]
        }))
        .await;

        let result = resolve(&rig, PayBuyer, WAIT).await.unwrap();

        assert_eq!(result.outcome, ResolveOutcome::PaidBuyer);
        assert_eq!(result.resolution, PayBuyer);
        let row = rig.row().await;
        assert_eq!(row.status, DisputeStatus::Settled, "closed at once");
        assert_eq!(row.taken.as_ref().unwrap().resolved_as, Some(ResolvedAs::PaidBuyer));
        assert_eq!(permission(&rig).await, SolverPermission::ReadWrite);
        assert_eq!(rig.standing().await, SolverStatus::Yes);
        // It left Your disputes for the closed ones.
        let rows = [row.clone()];
        assert!(crate::mostro::take::held_by(&rows, &rig.solver_hex(), 0).is_empty());
        let closed = crate::mostro::take::closed_by(&rows, &rig.solver_hex());
        assert_eq!(closed[0].resolved_as, Some(ResolvedAs::PaidBuyer));
        assert!(crate::mostro::take::detail_of(&row, &rig.solver_hex()).unwrap().is_closed);

        // The ORDER id went out, with the settle action and no payload.
        let sent = received.messages.lock().unwrap().clone();
        assert_eq!(sent.len(), 1);
        let kind = sent[0].get_inner_message_kind();
        assert_eq!(kind.action, Action::AdminSettle);
        assert_eq!(kind.id.unwrap().to_string(), ORDER);
        assert!(kind.payload.is_none());

        // Done is done: a second request is not sent.
        assert_eq!(
            resolve(&rig, RefundSeller, WAIT).await.unwrap_err(),
            ResolveError::Closed
        );
        assert_eq!(received.count.load(Ordering::SeqCst), 1);
    }

    // ── Bonds ────────────────────────────────────────────────────────────

    /// Each choice as mostro-core's payload (Mostrix `to_optional_payload`):
    /// none when nothing is slashed, `BondResolution` otherwise, and a
    /// request mostrod's own check accepts for both actions.
    #[test]
    fn each_bond_choice_is_its_payload() {
        for (bond, expected) in [
            (BondSlash::NoSlash, None),
            (BondSlash::Buyer, Some((false, true))),
            (BondSlash::Seller, Some((true, false))),
            (BondSlash::Both, Some((true, true))),
        ] {
            for resolution in [PayBuyer, RefundSeller] {
                let message = request_message(resolution, order(), 3, bond);
                let payload = message.get_inner_message_kind().payload.clone();
                match (payload, expected) {
                    (None, None) => {}
                    (Some(Payload::BondResolution(b)), Some((seller, buyer))) => {
                        assert_eq!((b.slash_seller, b.slash_buyer), (seller, buyer), "{bond:?}");
                    }
                    (other, _) => panic!("{bond:?}: unexpected payload {other:?}"),
                }
                assert!(message.verify(), "{bond:?} {resolution:?}");
            }
        }
    }

    /// A slash of a party that posted no bond is refused as such; the same
    /// refusal to a request without a slash is an ordinary refusal.
    #[test]
    fn invalid_payload_is_a_missing_bond_only_when_one_was_slashed() {
        let answer = read_answer(PayBuyer, ORDER, &refused(1, CantDoReason::InvalidPayload));
        for bond in [BondSlash::Buyer, BondSlash::Seller, BondSlash::Both] {
            assert_eq!(classify(&answer, PayBuyer, bond), (ResolveOutcome::BondNotPosted, None));
        }
        assert_eq!(
            classify(&answer, PayBuyer, BondSlash::NoSlash).0,
            ResolveOutcome::Refused
        );
    }

    /// mostrod answers a cooperative cancel before it reads the payload:
    /// nothing was slashed then.
    #[test]
    fn a_cooperative_cancel_slashes_nothing() {
        assert_eq!(slashed(ResolvedAs::CooperativelyCanceled, BondSlash::Both), BondSlash::NoSlash);
        assert_eq!(slashed(ResolvedAs::PaidBuyer, BondSlash::Seller), BondSlash::Seller);
        assert_eq!(slashed(ResolvedAs::RefundedSeller, BondSlash::Buyer), BondSlash::Buyer);
    }

    #[tokio::test]
    async fn a_slash_goes_out_with_the_request_and_is_kept_with_the_dispute() {
        let received = Arc::new(Received::default());
        let rig = taken_rig(recording(received.clone(), |rid| {
            vec![confirmed(rid, RefundSeller)]
        }))
        .await;

        let result = resolve_with(&rig, RefundSeller, BondSlash::Buyer, WAIT)
            .await
            .unwrap();

        assert_eq!(result.outcome, ResolveOutcome::RefundedSeller);
        assert_eq!(result.bond, BondSlash::Buyer);
        let kind = received.messages.lock().unwrap()[0].get_inner_message_kind().clone();
        assert_eq!(kind.action, Action::AdminCancel);
        assert_eq!(kind.id.unwrap().to_string(), ORDER);
        match kind.payload {
            Some(Payload::BondResolution(b)) => {
                assert!(b.slash_buyer && !b.slash_seller);
            }
            other => panic!("expected BondResolution, got {other:?}"),
        }
        let row = rig.row().await;
        let taken = row.taken.clone().unwrap();
        assert_eq!(taken.resolved_as, Some(ResolvedAs::RefundedSeller));
        assert_eq!(taken.bond_slash, Some(BondSlash::Buyer));
        let detail = crate::mostro::take::detail_of(&row, &rig.solver_hex()).unwrap();
        assert_eq!(detail.bond_slash, Some(BondSlash::Buyer));
    }

    #[tokio::test]
    async fn a_slash_of_a_party_with_no_bond_resolves_nothing() {
        let rig = taken_rig(answer_with(|rid| refused(rid, CantDoReason::InvalidPayload))).await;

        let result = resolve_with(&rig, PayBuyer, BondSlash::Seller, WAIT).await.unwrap();

        assert_eq!(result.outcome, ResolveOutcome::BondNotPosted);
        let row = rig.row().await;
        assert_eq!(row.status, DisputeStatus::InProgress, "still open");
        let taken = row.taken.unwrap();
        assert_eq!(taken.resolved_as, None);
        assert_eq!(taken.bond_slash, None);
        // Another choice can be sent: nothing is in flight.
        assert!(rig.router.unanswered_resolution(&rig.node_hex(), &rig.solver_hex(), DISPUTE).is_none());
    }

    #[tokio::test]
    async fn admin_canceled_closes_it_as_refunded() {
        let received = Arc::new(Received::default());
        let rig = taken_rig(recording(received.clone(), |rid| {
            vec![confirmed(rid, RefundSeller)]
        }))
        .await;

        let result = resolve(&rig, RefundSeller, WAIT).await.unwrap();

        assert_eq!(result.outcome, ResolveOutcome::RefundedSeller);
        let row = rig.row().await;
        assert_eq!(row.status, DisputeStatus::SellerRefunded);
        assert_eq!(
            row.taken.unwrap().resolved_as,
            Some(ResolvedAs::RefundedSeller)
        );
        assert_eq!(permission(&rig).await, SolverPermission::ReadWrite);
        let kind = received.messages.lock().unwrap()[0].get_inner_message_kind().clone();
        assert_eq!(kind.action, Action::AdminCancel);
        assert_eq!(kind.id.unwrap().to_string(), ORDER);
    }

    #[tokio::test]
    async fn not_authorized_marks_the_key_read_only_and_leaves_the_dispute_open() {
        let rig = taken_rig(answer_with(|rid| refused(rid, CantDoReason::NotAuthorized))).await;

        let result = resolve(&rig, PayBuyer, WAIT).await.unwrap();

        assert_eq!(result.outcome, ResolveOutcome::ReadOnlySolver);
        assert_eq!(permission(&rig).await, SolverPermission::Read);
        let row = rig.row().await;
        assert_eq!(row.status, DisputeStatus::InProgress);
        let taken = row.taken.unwrap();
        assert_eq!(taken.solver_pubkey, rig.solver_hex(), "still this key's");
        assert_eq!(taken.resolved_as, None);
    }

    #[tokio::test]
    async fn a_take_over_drops_this_keys_take() {
        for reason in [CantDoReason::IsNotYourDispute, CantDoReason::DisputeTakenByAdmin] {
            let answer = reason.clone();
            let script: Script = Arc::new(move |rid, _| vec![refused(rid, answer.clone())]);
            let rig = taken_rig(script).await;

            let result = resolve(&rig, RefundSeller, WAIT).await.unwrap();

            assert_eq!(result.outcome, ResolveOutcome::TakenOver, "{reason:?}");
            let row = rig.row().await;
            assert_eq!(row.taken, None, "out of Your disputes");
            assert_eq!(row.status, DisputeStatus::InProgress, "still the node's");
            assert_eq!(permission(&rig).await, SolverPermission::Unknown);
        }
    }

    #[tokio::test]
    async fn a_cooperative_cancel_closes_it_without_an_error() {
        let rig = taken_rig(answer_with(coop_accepted)).await;

        let result = resolve(&rig, PayBuyer, WAIT).await.unwrap();

        assert_eq!(result.outcome, ResolveOutcome::CooperativelyCanceled);
        let row = rig.row().await;
        assert_eq!(row.status, DisputeStatus::CooperativelyCanceled);
        assert_eq!(
            row.taken.unwrap().resolved_as,
            Some(ResolvedAs::CooperativelyCanceled)
        );
        assert_eq!(permission(&rig).await, SolverPermission::ReadWrite);
    }

    #[tokio::test]
    async fn a_refusal_by_status_changes_nothing_and_the_38386_reconciles() {
        let rig = taken_rig(answer_with(|rid| {
            refused(rid, CantDoReason::NotAllowedByStatus)
        }))
        .await;

        let result = resolve(&rig, RefundSeller, WAIT).await.unwrap();

        assert_eq!(result.outcome, ResolveOutcome::NotInDispute);
        assert_eq!(result.reason.as_deref(), Some("not_allowed_by_status"));
        let row = rig.row().await;
        assert_eq!(row.status, DisputeStatus::InProgress);
        assert_eq!(row.taken.as_ref().unwrap().resolved_as, None);
        assert_eq!(permission(&rig).await, SolverPermission::Unknown);

        // The node's own revision closes it.
        rig.feed
            .ingest(&mostrod_event(&rig.node, DISPUTE, "seller-refunded", 1_800_000_000))
            .await
            .unwrap();
        let row = rig.row().await;
        assert_eq!(row.status, DisputeStatus::SellerRefunded);
        assert!(row.taken.is_some(), "the take survives a close");
    }

    // ── What is never sent ───────────────────────────────────────────────

    #[tokio::test]
    async fn without_an_order_id_nothing_is_sent() {
        let received = Arc::new(Received::default());
        let rig = taken_rig(recording(received.clone(), |rid| {
            vec![confirmed(rid, PayBuyer)]
        }))
        .await;
        let mut taken = rig.row().await.taken.unwrap();
        taken.order_id = None;
        rig.feed.record_take(&rig.node_hex(), DISPUTE, taken).await.unwrap();

        assert_eq!(
            resolve(&rig, PayBuyer, WAIT).await.unwrap_err(),
            ResolveError::NoOrderId
        );
        tokio::time::sleep(Duration::from_millis(300)).await;
        assert_eq!(received.count.load(Ordering::SeqCst), 0);
        assert_eq!(rig.router.waiting_len(), 0);
    }

    #[tokio::test]
    async fn another_keys_or_a_closed_dispute_is_not_sent() {
        let rig = Rig::new("in-progress", silent()).await;
        assert_eq!(
            resolve(&rig, PayBuyer, WAIT).await.unwrap_err(),
            ResolveError::NotYours,
            "not taken"
        );
        let other = taken_from(&info(), &"bb".repeat(32), None, 1);
        rig.feed.record_take(&rig.node_hex(), DISPUTE, other).await.unwrap();
        assert_eq!(
            resolve(&rig, PayBuyer, WAIT).await.unwrap_err(),
            ResolveError::NotYours,
            "another key's"
        );
        let mine = taken_from(&info(), &rig.solver_hex(), None, 1);
        rig.feed.record_take(&rig.node_hex(), DISPUTE, mine).await.unwrap();
        rig.feed
            .ingest(&mostrod_event(&rig.node, DISPUTE, "released", 1_800_000_000))
            .await
            .unwrap();
        assert_eq!(
            resolve(&rig, PayBuyer, WAIT).await.unwrap_err(),
            ResolveError::Closed
        );
        assert_eq!(rig.router.waiting_len(), 0);
    }

    /// A resolution still waiting for its answer refuses a second one of the
    /// same dispute (a double tap that got past the screen).
    #[tokio::test]
    async fn a_second_resolution_in_flight_is_refused() {
        let rig = Arc::new(taken_rig(silent()).await);
        let first = {
            let rig = rig.clone();
            tokio::spawn(async move { resolve(&rig, PayBuyer, Duration::from_secs(2)).await })
        };
        until(async || rig.router.waiting_len() == 1).await;

        assert_eq!(
            resolve(&rig, RefundSeller, WAIT).await.unwrap_err(),
            ResolveError::AlreadyResolving
        );
        assert_eq!(rig.router.waiting_len(), 1);
        assert_eq!(
            first.await.unwrap().unwrap().outcome,
            ResolveOutcome::NoAnswer
        );
    }

    // ── No answer ────────────────────────────────────────────────────────

    /// No answer in time: the result says so, nothing is resent, the detail
    /// warns while the request is still waited for, and a late confirmation
    /// still closes the dispute.
    #[tokio::test]
    async fn no_answer_is_never_retried_and_a_late_answer_still_closes_it() {
        let received = Arc::new(Received::default());
        let rig = taken_rig(recording(received.clone(), |_| Vec::new())).await;

        let result = resolve(&rig, PayBuyer, Duration::from_millis(300)).await.unwrap();

        assert_eq!(result.outcome, ResolveOutcome::NoAnswer);
        tokio::time::sleep(Duration::from_millis(500)).await;
        assert_eq!(received.count.load(Ordering::SeqCst), 1, "sent once, never again");
        assert_eq!(rig.router.waiting_len(), 1, "kept for a late answer");
        assert_eq!(
            rig.router
                .unanswered_resolution(&rig.node_hex(), &rig.solver_hex(), DISPUTE),
            Some(PayBuyer)
        );
        let row = rig.row().await;
        assert_eq!(row.status, DisputeStatus::InProgress, "not known to be closed");

        let request_id = received.messages.lock().unwrap()[0]
            .get_inner_message_kind()
            .request_id
            .unwrap();
        let late = mostro_core::transport::wrap_message_with(
            mostro_core::transport::Transport::Nip44Direct,
            &confirmed(request_id, PayBuyer),
            &rig.node,
            &rig.node,
            rig.solver.public_key(),
            mostro_core::transport::WrapOptions {
                signed: false,
                ..Default::default()
            },
        )
        .await
        .unwrap();
        rig._daemon.send_event(&late).await.unwrap();
        until(async || rig.row().await.status == DisputeStatus::Settled).await;
        assert_eq!(
            rig.row().await.taken.unwrap().resolved_as,
            Some(ResolvedAs::PaidBuyer)
        );
        assert_eq!(
            rig.router
                .unanswered_resolution(&rig.node_hex(), &rig.solver_hex(), DISPUTE),
            None
        );
    }

    /// The solver tries again after a request whose answer was lost, and
    /// the node had paid: mostrod's status guard refuses the second
    /// (`InvalidOrderStatus` for a settle), which reads "not in dispute" —
    /// nothing is paid twice.
    #[tokio::test]
    async fn a_retry_after_a_resolution_that_happened_is_refused_by_status() {
        let settled = Arc::new(AtomicUsize::new(0));
        let node_state = settled.clone();
        let script: Script = Arc::new(move |rid, message| {
            let kind = message.get_inner_message_kind();
            assert_eq!(kind.id.unwrap().to_string(), ORDER);
            // The first settle pays and its answer is lost; any later one
            // finds the order out of dispute, as `admin_settle_action` does.
            if node_state.fetch_add(1, Ordering::SeqCst) == 0 {
                Vec::new()
            } else {
                vec![refused(rid, CantDoReason::InvalidOrderStatus)]
            }
        });
        let rig = taken_rig(script).await;

        let first = resolve(&rig, PayBuyer, Duration::from_millis(300)).await.unwrap();
        assert_eq!(first.outcome, ResolveOutcome::NoAnswer);
        let again = resolve(&rig, PayBuyer, WAIT).await.unwrap();
        assert_eq!(again.outcome, ResolveOutcome::NotInDispute);
        assert_eq!(again.reason.as_deref(), Some("invalid_order_status"));
        assert_eq!(settled.load(Ordering::SeqCst), 2);
        // Then the node's settled revision says how it ended.
        rig.feed
            .ingest(&mostrod_event(&rig.node, DISPUTE, "settled", 1_800_000_000))
            .await
            .unwrap();
        assert_eq!(rig.row().await.status, DisputeStatus::Settled);
    }

    /// Against a real mostrod and relay, by hand (not in CI): a dispute this
    /// key holds there (`DISPUTE`, its order `ORDER`) is resolved, and
    /// mostrod's answer is checked against `EXPECT`. The feed does not
    /// follow the node, so the dispute stays open here whatever the node
    /// published since (as when a cooperative cancel lands between the
    /// node's revision and the solver's tap): the request always leaves.
    ///
    /// ```text
    /// BOSSTRO_E2E_RELAY=ws://localhost:7010 BOSSTRO_E2E_NODE=<hex> \
    /// BOSSTRO_E2E_SOLVER=<nsec or hex> BOSSTRO_E2E_DISPUTE=<uuid> \
    /// BOSSTRO_E2E_ORDER=<uuid> BOSSTRO_E2E_RESOLUTION=pay|refund \
    /// [BOSSTRO_E2E_BOND=no-slash|buyer|seller|both] \
    /// BOSSTRO_E2E_EXPECT=paid-buyer|refunded-seller|cooperatively-canceled|read-only|bond-not-posted|taken-over|not-in-dispute \
    ///   cargo test --lib resolve_against_a_local_mostrod -- --ignored --nocapture
    /// ```
    #[tokio::test]
    #[ignore = "needs a local mostrod and relay"]
    async fn resolve_against_a_local_mostrod() {
        use crate::disputes::feed::Store;
        use crate::mostro::replies::tests::connected;
        use crate::mostro::replies::Router;
        use crate::nostr::live_subs::LiveSubs;

        let env = |name: &str| std::env::var(name).unwrap_or_else(|_| panic!("{name} unset"));
        let relay = nostr_sdk::prelude::RelayUrl::parse(&env("BOSSTRO_E2E_RELAY")).unwrap();
        let node = env("BOSSTRO_E2E_NODE");
        let solver = Keys::parse(&env("BOSSTRO_E2E_SOLVER")).unwrap();
        let dispute = env("BOSSTRO_E2E_DISPUTE");
        let order = env("BOSSTRO_E2E_ORDER");
        let resolution = match env("BOSSTRO_E2E_RESOLUTION").as_str() {
            "pay" => PayBuyer,
            "refund" => RefundSeller,
            other => panic!("unknown RESOLUTION {other}"),
        };
        // Optional: which bonds to slash (BOSSTRO_E2E_BOND=no-slash|buyer|seller|both).
        let bond = std::env::var("BOSSTRO_E2E_BOND")
            .ok()
            .map(|b| BondSlash::from_wire(&b).unwrap_or_else(|| panic!("unknown BOND {b}")))
            .unwrap_or_default();
        let expect = match env("BOSSTRO_E2E_EXPECT").as_str() {
            "paid-buyer" => ResolveOutcome::PaidBuyer,
            "refunded-seller" => ResolveOutcome::RefundedSeller,
            "cooperatively-canceled" => ResolveOutcome::CooperativelyCanceled,
            "read-only" => ResolveOutcome::ReadOnlySolver,
            "bond-not-posted" => ResolveOutcome::BondNotPosted,
            "taken-over" => ResolveOutcome::TakenOver,
            "not-in-dispute" => ResolveOutcome::NotInDispute,
            other => panic!("unknown EXPECT {other}"),
        };

        let client = connected(&relay).await;
        let subs: &'static LiveSubs = Box::leak(Box::default());
        let (tx, _) = tokio::sync::broadcast::channel(256);
        let feed = Feed::new(client.clone(), Store::memory(), subs, tx);
        let taken = crate::disputes::TakenDispute {
            order_id: Some(order.clone()),
            ..taken_from(&info(), &solver.public_key().to_hex(), None, crate::rt::unix_now())
        };
        feed.record_take(&node, &dispute, taken).await.unwrap();

        let router = Router::new(client.clone(), subs, feed.clone());
        router.spawn_reader();
        router
            .retarget(Some(node.clone()), Some(solver.clone()))
            .await;
        let started = std::time::Instant::now();
        let result = resolve_on(
            &router,
            &feed,
            &client,
            &solver,
            &node,
            &dispute,
            resolution,
            bond,
            ANSWER_WAIT,
        )
        .await
        .unwrap();
        println!(
            "answer in {:?}: {:?} {:?}",
            started.elapsed(),
            result.outcome,
            result.reason
        );
        let row = feed.row(&node, &dispute).await.unwrap().unwrap();
        println!(
            "row: {:?}, resolved as {:?}, taken {}",
            row.status,
            row.taken.as_ref().and_then(|t| t.resolved_as),
            row.taken.is_some()
        );
        let standing = crate::mostro::standing::read(&node, &solver.public_key().to_hex()).await;
        println!("standing: {standing:?}");
        assert_eq!(result.outcome, expect);
    }
}
