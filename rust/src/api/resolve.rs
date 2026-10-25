//! Resolving a dispute (phase 6), across the bridge: pay the buyer
//! (`AdminSettle`) or refund the seller (`AdminCancel`).
//!
//! The request carries the dispute's **order** id, not its dispute id
//! (MostroP2P/mostro's `src/app/admin_settle.rs`, `get_order`): the one the
//! take's `SolverDisputeInfo` named. It goes to the active node over transport
//! v2, signed with the solver key, and its answer comes through the same router
//! as a take's (`crate::mostro::replies`). Sats move only on the node's side;
//! this end never retries a request on its own (`crate::mostro::resolve`).
//!
//! Rust does not translate: every outcome and refusal is a marker, and Dart
//! words it.

/// What the solver decides.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Resolution {
    /// `AdminSettle`: the node settles the seller's hold invoice and pays the
    /// buyer's invoice.
    PayBuyer,
    /// `AdminCancel`: the node cancels the seller's hold invoice, so the sats
    /// go back to the seller.
    RefundSeller,
}

/// Which anti-abuse bonds a resolution slashes, decided apart from paying or
/// refunding (mostrod `docs/ANTI_ABUSE_BOND.md` §7, Mostrix
/// `BondSlashChoice`). Only on a node whose kind 38385 says `bond_enabled`.
/// A slashed party loses its bond; the other may claim its share
/// (`AddBondInvoice`, on the traders' side).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum BondSlash {
    /// Release every bond, slash none: the default, and what the request
    /// means without a payload.
    #[default]
    NoSlash,
    /// Slash the buyer's bond.
    Buyer,
    /// Slash the seller's bond.
    Seller,
    /// Slash both bonds.
    Both,
}

/// How a dispute this key held ended, as the node's answer to its own
/// resolution said. Kept with the take: a 38386 status says what happened
/// to the dispute, not that this key did it.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ResolvedAs {
    /// `AdminSettled`: this key paid the buyer.
    PaidBuyer,
    /// `AdminCanceled`: this key refunded the seller.
    RefundedSeller,
    /// `CooperativeCancelAccepted`: the parties had already cancelled the
    /// trade between them; nothing was paid or refunded by this key.
    CooperativelyCanceled,
}

/// How a resolution ended.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ResolveOutcome {
    /// `AdminSettled`: the buyer is paid. The dispute is closed; this key is
    /// Read-Write on the node.
    PaidBuyer,
    /// `AdminCanceled`: the seller is refunded. The dispute is closed; this
    /// key is Read-Write on the node.
    RefundedSeller,
    /// `CooperativeCancelAccepted`: the parties cancelled the trade
    /// themselves before the request; the dispute is closed, nothing moved.
    CooperativelyCanceled,
    /// `CantDo(NotAuthorized)`: this key may take and mediate on this node,
    /// never pay or refund (D12). The node is marked "permission: read".
    ReadOnlySolver,
    /// `CantDo(IsNotYourDispute)` or `CantDo(DisputeTakenByAdmin)`: another
    /// solver (or the node itself) holds the dispute now. This key's take is
    /// dropped: it leaves Your disputes.
    TakenOver,
    /// A `CantDo` about the order's status (`InvalidOrderStatus`,
    /// `NotAllowedByStatus`): the order is no longer in dispute — paid,
    /// refunded or released already, perhaps by a request whose answer was
    /// lost. Nothing changes here; the node's 38386 says how it ended.
    NotInDispute,
    /// `CantDo(InvalidPayload)` to a request that slashed a bond: a party it
    /// names posted none (mostrod `validate_bond_resolution`). Nothing was
    /// paid or refunded; the solver sends it again with another choice.
    BondNotPosted,
    /// Another `CantDo`; its reason is in [`ResolveResult::reason`].
    Refused,
    /// The node did not answer in time. **It may have acted all the same**,
    /// and nothing is retried: the dispute's 38386 tells, and a request sent
    /// again after it did is refused (`NotInDispute`).
    NoAnswer,
}

/// The answer to one resolution.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ResolveResult {
    pub mostro_pubkey: String,
    pub dispute_id: String,
    pub resolution: Resolution,
    /// The bonds the request slashed.
    pub bond: BondSlash,
    pub outcome: ResolveOutcome,
    /// With [`ResolveOutcome::Refused`] and [`ResolveOutcome::NotInDispute`]:
    /// mostro-core's `CantDoReason` as the wire writes it, or `None` when the
    /// node gave none.
    pub reason: Option<String>,
}

/// Why a resolution was not sent. Dart maps each marker to its own copy.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ResolveError {
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
    /// This key does not hold the dispute here (another key's, reopened, or
    /// taken over).
    NotYours,
    /// The take named no order, and the request needs the order id.
    NoOrderId,
    /// The dispute is closed already.
    Closed,
    /// A request about this dispute (a resolution or a take) is still waiting
    /// for its answer.
    AlreadyResolving,
    /// The node says it speaks another protocol than v2 (its kind 38385).
    ProtocolUnsupported,
    /// The node's kind 38385 was never read and could not be read now, so the
    /// proof of work it asks for is not known; the request is not sent.
    NodeInfoUnavailable,
}

/// Send `AdminSettle` ([`Resolution::PayBuyer`]) or `AdminCancel`
/// ([`Resolution::RefundSeller`]) for `dispute_id`, a dispute this key holds
/// on the active node, and wait for the answer (15 s). What the answer says
/// is stored before it returns: the closed dispute and how it closed, this
/// key's permission, a take-over. An answer that arrives after the wait is
/// still applied. Never retried. [`BondSlash::NoSlash`] sends no payload;
/// any other choice sends mostro-core's `BondResolution`.
pub async fn resolve_dispute(
    dispute_id: String,
    resolution: Resolution,
    bond: BondSlash,
) -> Result<ResolveResult, ResolveError> {
    crate::mostro::resolve::resolve(&dispute_id, resolution, bond).await
}
