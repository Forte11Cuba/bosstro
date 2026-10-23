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

/// What this key may do on a node (D12), as its answers have shown. Phase 4
/// never learns it: a take succeeds for a Read and a Read-Write solver
/// alike, and the take-over a Read solver cannot make is indistinguishable
/// from recovering one's own dispute. Phase 6 learns it from settle and
/// cancel.
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
}

/// The disputes this key took on the active node and still holds.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct InProgressDisputes {
    pub mostro_pubkey: String,
    pub disputes: Vec<TakenDisputeSummary>,
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
/// it), the one that has waited longest first; `None` without a node or a
/// key.
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
