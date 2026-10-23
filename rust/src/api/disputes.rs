//! The disputes of the active node, across the bridge (phase 3).
//!
//! The node publishes each dispute as a kind 38386 event, replaced on every
//! status change. `crate::disputes` subscribes to them for the active node,
//! keeps the newest revision of each in `Storage` (one row per node and
//! dispute, D6), and announces every change on [`on_dispute_updates`].
//!
//! Pending shows the disputes waiting for a solver (`initiated`), as
//! Mostrix's Disputes Pending. The event carries no order data, so no amount:
//! that arrives with `AdminTookDispute` in phase 4.

use anyhow::Result;

/// A dispute's public status: the 38386 `s` tag. Same set as mostro-core's
/// `dispute::Status`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum DisputeStatus {
    /// Waiting for a solver.
    Initiated,
    /// A solver took it.
    InProgress,
    /// A solver refunded the seller (admin-cancel).
    SellerRefunded,
    /// A solver paid the buyer (admin-settle).
    Settled,
    /// The seller released the funds before a solver resolved it.
    Released,
    /// Both parties cancelled the trade cooperatively.
    CooperativelyCanceled,
}

/// Who opened the dispute: the 38386 `initiator` tag. `Unknown` when the
/// node could not tell (it publishes the word `unknown`), the tag is missing,
/// or it names anything else.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum DisputeInitiator {
    Buyer,
    Seller,
    Unknown,
}

/// One dispute as the lists show it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DisputeSummary {
    /// The node that published it (hex).
    pub mostro_pubkey: String,
    /// The dispute id (a UUID). Not the order id.
    pub dispute_id: String,
    pub status: DisputeStatus,
    pub initiator: DisputeInitiator,
    /// When it was opened (Unix seconds), from the `published_at` tag or the
    /// legacy `created_at` tag; `None` when the event carries neither.
    pub opened_at: Option<i64>,
    /// Whether Pending lists it: `initiated` and not expired (NIP-40).
    /// Computed in Rust when the summary is built.
    pub is_pending: bool,
}

/// The active node's pending disputes, oldest first (the one that has waited
/// longest on top), as storage holds them now.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PendingDisputes {
    pub mostro_pubkey: String,
    pub disputes: Vec<DisputeSummary>,
    /// Whether the relays have answered for this node since it became active
    /// (or the wait ran out). Until then an empty list means "not known yet",
    /// not "none".
    pub synced: bool,
}

/// One change, as [`DisputeUpdateStream`] delivers it. With `dispute` set, that
/// dispute changed; without it, the list as a whole may have (the node's first
/// answer arrived, or the reader fell behind) and Dart reads
/// [`pending_disputes`] again.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DisputeUpdate {
    /// The node it is about (hex). Dart ignores updates for another node.
    pub mostro_pubkey: String,
    /// The dispute's new state, when one changed.
    pub dispute: Option<DisputeSummary>,
    /// Whether the node's disputes are synced, as of this update.
    pub synced: bool,
}

/// The active node's pending disputes, or `None` without an active node.
pub async fn pending_disputes() -> Result<Option<PendingDisputes>> {
    let Some(node) = crate::config::active_mostro_pubkey() else {
        return Ok(None);
    };
    let disputes = crate::disputes::pending_for(&node).await?;
    Ok(Some(PendingDisputes {
        synced: crate::disputes::feed::is_synced(&node),
        mostro_pubkey: node,
        disputes,
    }))
}

/// Stream of dispute changes for whichever node is active.
pub fn on_dispute_updates() -> DisputeUpdateStream {
    DisputeUpdateStream {
        rx: crate::disputes::feed::subscribe_updates(),
    }
}

/// Wrapper so flutter_rust_bridge can hand Dart a pull-based stream.
pub struct DisputeUpdateStream {
    rx: tokio::sync::broadcast::Receiver<DisputeUpdate>,
}

impl DisputeUpdateStream {
    /// The next update, or `None` once the feed is gone.
    ///
    /// A reader that fell behind (a node's whole history arriving at once)
    /// gets one update without a dispute instead of what it missed, which
    /// tells it to read the list again.
    pub async fn next(&mut self) -> Option<DisputeUpdate> {
        use tokio::sync::broadcast::error::RecvError;
        match self.rx.recv().await {
            Ok(update) => Some(update),
            Err(RecvError::Lagged(_)) => {
                self.rx = self.rx.resubscribe();
                let node = crate::config::active_mostro_pubkey().unwrap_or_default();
                Some(DisputeUpdate {
                    synced: crate::disputes::feed::is_synced(&node),
                    mostro_pubkey: node,
                    dispute: None,
                })
            }
            Err(RecvError::Closed) => None,
        }
    }
}
