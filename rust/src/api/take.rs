//! Taking a dispute (phase 4), across the bridge.
//!
//! The solver takes a dispute with `AdminTakeDispute`, sent to the active
//! node over transport v2 and signed with the solver key; the node answers
//! with `AdminTookDispute` (and the order data, `SolverDisputeInfo`) or a
//! `CantDo` (`crate::mostro`). The answer also tells whether this key is a
//! solver on that node at all: mostrod has no read-only query for it
//! (CLAUDE.md → "Am I a solver on this node?").
//!
//! Rust does not translate: every outcome and refusal is a marker, and Dart
//! words it.

use anyhow::Result;

use crate::api::disputes::{DisputeInitiator, DisputeStatus, DisputeSummary};
use crate::api::resolve::{BondSlash, Resolution, ResolvedAs};

/// Whether this key is a solver on a node, as its answers have shown.
/// Cached per node and solver key (D6, D12).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum SolverStatus {
    /// No answer has said yet.
    #[default]
    Unknown,
    /// The node let this key take a dispute.
    Yes,
    /// The node refused this key a dispute waiting for a solver
    /// (`CantDo(InvalidPubkey)` on an `initiated` one).
    No,
}

/// What this key may do on a node (D12), as its answers have shown. A take
/// never teaches it: a take succeeds for a Read and a Read-Write solver
/// alike, and the take-over a Read solver cannot make is indistinguishable
/// from recovering one's own dispute. Settle and cancel do (phase 6):
/// `NotAuthorized` → Read; `AdminSettled`, `AdminCanceled` or
/// `CooperativeCancelAccepted` → Read-Write.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum SolverPermission {
    #[default]
    Unknown,
    /// Can take and mediate, never pay or refund.
    Read,
    /// Can also pay the buyer or refund the seller, and take over a dispute
    /// held by a Read solver.
    ReadWrite,
}

/// This key's standing on the active node.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SolverStanding {
    pub mostro_pubkey: String,
    pub status: SolverStatus,
    pub permission: SolverPermission,
}

/// How a take ended.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TakeOutcome {
    /// The node gave this key the dispute (`AdminTookDispute`): it is in
    /// In progress now, with its order data.
    Taken,
    /// `CantDo(InvalidPubkey)` on a dispute waiting for a solver: this key is
    /// not a solver on this node.
    NotSolver,
    /// `CantDo(InvalidPubkey)` on a dispute a solver holds: either another
    /// solver who is not read-only holds it, or this key may not take it
    /// over. Ambiguous (it is also the answer to a key that is no solver at
    /// all), so it changes nothing about the node.
    CannotTakeOver,
    /// Another `CantDo`; its reason is in [`TakeResult::reason`].
    Refused,
    /// The node did not answer in time. Nothing is retried: the dispute may
    /// have been taken all the same, and Recover a dispute asks again.
    NoAnswer,
}

/// The answer to one take.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TakeResult {
    pub mostro_pubkey: String,
    pub dispute_id: String,
    pub outcome: TakeOutcome,
    /// With [`TakeOutcome::Refused`]: mostro-core's `CantDoReason` as the
    /// wire writes it (`not_found`, `invalid_peer`…), or `None` when the node
    /// gave none.
    pub reason: Option<String>,
}

/// Why a take was not sent. Dart maps each marker to its own copy.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TakeError {
    /// No solver key is loaded.
    NoKey,
    /// No node is chosen.
    NoNode,
    /// The relay pool is not running.
    NoRelays,
    /// No relay took the request.
    SendFailed,
    /// The dispute is not one of the active node's stored disputes.
    UnknownDispute,
    /// The dispute is closed (settled, refunded, released or cancelled):
    /// there is nothing to take.
    NotTakeable,
    /// A take of this dispute is already waiting for its answer.
    AlreadyTaking,
    /// The node says it speaks another protocol than v2 (its kind 38385).
    ProtocolUnsupported,
    /// The node's kind 38385 was never read and could not be read now, so
    /// the proof of work it asks for is not known. Sent without it, the take
    /// could be dropped unanswered; it is not sent.
    NodeInfoUnavailable,
}

/// One dispute this key took, as In progress lists it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TakenDisputeSummary {
    pub mostro_pubkey: String,
    pub dispute_id: String,
    pub status: DisputeStatus,
    pub initiator: DisputeInitiator,
    pub opened_at: Option<i64>,
    /// When the node gave it to this key (Unix seconds, this device's clock).
    pub taken_at: i64,
    /// Sats.
    pub amount: Option<i64>,
    pub fiat_amount: Option<i64>,
    /// From the order's kind 38383, when the relays have it (the take's
    /// answer carries none).
    pub fiat_code: Option<String>,
    /// How this key resolved it, once closed by its own request.
    pub resolved_as: Option<ResolvedAs>,
}

/// The disputes this key took on the active node: the ones it still holds,
/// and the ones that closed while it held them.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct InProgressDisputes {
    pub mostro_pubkey: String,
    /// `in-progress`, the one that has waited longest first.
    pub disputes: Vec<TakenDisputeSummary>,
    /// Closed (settled, refunded, released, cancelled by the parties), the
    /// one that closed last first. Read only.
    pub closed: Vec<TakenDisputeSummary>,
}

/// Send `AdminTakeDispute` for `dispute_id`, a stored dispute of the active
/// node, and wait for the answer (15 s, as Mostrix). Whatever the answer
/// says is stored before it returns: the take, and what it tells about this
/// key's standing. An answer that arrives after the wait is still stored.
///
/// The same call recovers a dispute: on an `in-progress` dispute this key
/// already holds, the node answers `AdminTookDispute` again with its data.
pub async fn take_dispute(dispute_id: String) -> Result<TakeResult, TakeError> {
    crate::mostro::take::take(&dispute_id).await
}

/// The disputes this key holds on the active node (`in-progress`, taken by
/// it), the one that has waited longest first, and those it held that closed;
/// `None` without a node or a key.
pub async fn in_progress_disputes() -> Result<Option<InProgressDisputes>> {
    crate::mostro::take::in_progress().await
}

/// What Recover a dispute offers: the active node's `in-progress` disputes
/// that this key does not hold here, oldest first. The 38386 does not say
/// who holds one, so the list mixes this key's lost takes with other
/// solvers' disputes. `None` without a node or a key.
pub async fn recover_candidates() -> Result<Option<Vec<DisputeSummary>>> {
    crate::mostro::take::recover_candidates().await
}

/// This key's standing on the active node; `None` without a node or a key.
pub async fn solver_standing() -> Result<Option<SolverStanding>> {
    crate::mostro::standing::active().await
}

/// A dispute this key holds (or held until it closed), as its detail shows
/// it: the 38386's public fields and what the node said in the take.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DisputeDetail {
    pub mostro_pubkey: String,
    pub dispute_id: String,
    pub status: DisputeStatus,
    pub initiator: DisputeInitiator,
    pub opened_at: Option<i64>,
    /// When the node gave it to this key (Unix seconds, this device's clock).
    pub taken_at: i64,
    pub order_id: Option<String>,
    /// `buy` or `sell`, as the node writes it.
    pub order_kind: Option<String>,
    /// Sats.
    pub amount: Option<i64>,
    pub fiat_amount: Option<i64>,
    pub fiat_code: Option<String>,
    pub payment_method: Option<String>,
    /// Percent over the market price.
    pub premium: Option<i64>,
    /// The node's fee, sats.
    pub fee: Option<i64>,
    /// The parties' trade keys (hex), when the node named them.
    pub buyer_pubkey: Option<String>,
    pub seller_pubkey: Option<String>,
    /// Whether the dispute is over (its 38386 is terminal, or this key's own
    /// resolution closed it): the chats are read only, nothing can be
    /// resolved.
    pub is_closed: bool,
    /// How this key resolved it, when its own request closed it.
    pub resolved_as: Option<ResolvedAs>,
    /// The bonds that resolution slashed, when it was kept.
    pub bond_slash: Option<BondSlash>,
    /// The order's status when the dispute was opened, as the node wrote it:
    /// `active` (the buyer had not marked the fiat as sent) or `fiat-sent`
    /// (they had). `None` when the take did not keep it. Dart words it.
    pub order_previous_status: Option<String>,
    /// Whether the node uses anti-abuse bonds (`bond_enabled` in its cached
    /// kind 38385): only then the solver chooses which to slash. `false`
    /// when the info was never read, so nothing is offered blind.
    pub bonds_enabled: bool,
    /// What paying the buyer sends them, sats: the order amount less the
    /// node's fee (mostrod's `do_payment` pays `amount - fee`).
    pub buyer_payout: Option<i64>,
    /// What refunding the seller gives back, sats: the seller's hold invoice,
    /// the order amount plus the node's fee (`amount + fee`).
    pub seller_refund: Option<i64>,
    /// A resolution this key sent that got no answer in time and is still
    /// waited for (in this process only, for ten minutes): the node may have
    /// acted on it. The detail warns before another is sent.
    pub unanswered_resolution: Option<Resolution>,
}

/// The detail of `dispute_id` on the active node, when this key took it;
/// `None` otherwise (another key's, a reopened one, or no node or key).
pub async fn dispute_detail(dispute_id: String) -> Result<Option<DisputeDetail>> {
    crate::mostro::take::detail(&dispute_id).await
}
