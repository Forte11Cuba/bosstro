//! The node's disputes (phase 3): what a kind 38386 says about each, kept
//! per node (D6) and reconciled as the node republishes it.
//!
//! - [`event`] reads one 38386 and refuses anything not signed by the node.
//! - [`merge`] decides what a revision does to the stored row (NIP-01 order;
//!   a reopen drops this solver's take).
//! - [`feed`] subscribes to the active node's 38386 events, writes the rows
//!   and announces each change across the bridge.

pub mod event;
pub mod feed;

use anyhow::Result;

use crate::api::disputes::{DisputeInitiator, DisputeStatus, DisputeSummary};
use crate::db::Storage;
use event::ParsedDispute;

/// One stored dispute: the newest 38386 revision seen of it, and what phase 4
/// learns when this solver takes it.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub struct DisputeRecord {
    /// The node that published it (hex).
    pub mostro_pubkey: String,
    /// The `d` tag: the dispute id, a lowercase hyphenated UUID.
    pub dispute_id: String,
    pub status: DisputeStatus,
    pub initiator: DisputeInitiator,
    /// The `published_at` tag, or the legacy `created_at` tag.
    pub opened_at: Option<i64>,
    /// NIP-40 `expiration` of the revision.
    pub expires_at: Option<i64>,
    /// The revision held (hex id and created_at), for NIP-01 ordering.
    pub event_id: String,
    pub event_created_at: i64,
    /// Set when this solver took the dispute (phase 4); `None` otherwise.
    pub taken: Option<TakenDispute>,
}

/// What `AdminTookDispute` (`SolverDisputeInfo`) tells the solver who took a
/// dispute (`crate::mostro::take`), kept across 38386 updates.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub struct TakenDispute {
    /// The solver key that took it (hex). A take belongs to one key: another
    /// nsec logged in on this device does not see it as its own.
    #[serde(default)]
    pub solver_pubkey: String,
    /// When the node answered the take (this device's clock, Unix seconds).
    pub taken_at: i64,
    pub order_id: Option<String>,
    pub order_kind: Option<String>,
    pub amount: Option<i64>,
    pub fiat_amount: Option<i64>,
    pub fiat_code: Option<String>,
    pub payment_method: Option<String>,
    pub premium: Option<i64>,
    pub fee: Option<i64>,
    pub initiator_pubkey: Option<String>,
    pub buyer_pubkey: Option<String>,
    pub seller_pubkey: Option<String>,
}

impl DisputeStatus {
    /// The status as the node writes it in the `s` tag (kebab-case).
    pub fn as_wire(self) -> &'static str {
        match self {
            DisputeStatus::Initiated => "initiated",
            DisputeStatus::InProgress => "in-progress",
            DisputeStatus::SellerRefunded => "seller-refunded",
            DisputeStatus::Settled => "settled",
            DisputeStatus::Released => "released",
            DisputeStatus::CooperativelyCanceled => "cooperatively-canceled",
        }
    }

    /// Read an `s` tag value. Parsed by mostro-core, so a status it does not
    /// know is refused here too.
    pub fn from_wire(value: &str) -> Option<Self> {
        use mostro_core::dispute::Status;
        use std::str::FromStr;
        Some(match Status::from_str(value).ok()? {
            Status::Initiated => DisputeStatus::Initiated,
            Status::InProgress => DisputeStatus::InProgress,
            Status::SellerRefunded => DisputeStatus::SellerRefunded,
            Status::Settled => DisputeStatus::Settled,
            Status::Released => DisputeStatus::Released,
            Status::CooperativelyCanceled => DisputeStatus::CooperativelyCanceled,
        })
    }

    /// Whether the dispute is over (Mostrix `AdminDispute::is_terminal_status`).
    pub fn is_terminal(self) -> bool {
        matches!(
            self,
            DisputeStatus::Settled
                | DisputeStatus::SellerRefunded
                | DisputeStatus::Released
                | DisputeStatus::CooperativelyCanceled
        )
    }
}

impl DisputeInitiator {
    pub fn as_wire(self) -> &'static str {
        match self {
            DisputeInitiator::Buyer => "buyer",
            DisputeInitiator::Seller => "seller",
            DisputeInitiator::Unknown => "unknown",
        }
    }

    /// Read an `initiator` tag value; anything but buyer or seller is unknown.
    pub fn from_wire(value: &str) -> Self {
        match value {
            "buyer" => DisputeInitiator::Buyer,
            "seller" => DisputeInitiator::Seller,
            _ => DisputeInitiator::Unknown,
        }
    }
}

impl DisputeRecord {
    /// Whether Pending lists it at `now`: waiting for a solver and not past
    /// its NIP-40 expiration (relays drop it then; so does the list).
    pub fn is_pending(&self, now: i64) -> bool {
        self.status == DisputeStatus::Initiated && !self.is_expired(now)
    }

    pub fn is_expired(&self, now: i64) -> bool {
        self.expires_at.is_some_and(|at| at <= now)
    }

    pub fn summary(&self, now: i64) -> DisputeSummary {
        DisputeSummary {
            mostro_pubkey: self.mostro_pubkey.clone(),
            dispute_id: self.dispute_id.clone(),
            status: self.status,
            initiator: self.initiator,
            opened_at: self.opened_at,
            is_pending: self.is_pending(now),
        }
    }
}

/// What `incoming` does to the row of its dispute, `existing`: the new row
/// when it is a newer revision, `None` when it changes nothing.
///
/// - **Order** is NIP-01's for replaceable events, the rule relays apply: the
///   newest `created_at` wins, and within one second the lowest id. So an old
///   revision replayed by a slow relay never undoes a newer status, and which
///   relay answers first never decides between two revisions of one second.
/// - **Reconciliation:** a revision replaces the public fields, so a terminal
///   status (settled, seller-refunded, released, cooperatively-canceled)
///   closes the row however the dispute ended (Mostrix
///   `relay_dispute_db_reconcile.rs`); a take survives every status change
///   but one:
/// - **Reopen:** mostrod can put a closed dispute back to `initiated`
///   (`scheduler.rs`, escrow deadline) and clears its solver then. An
///   `initiated` revision therefore drops this solver's take.
pub fn merge(existing: Option<&DisputeRecord>, incoming: &ParsedDispute) -> Option<DisputeRecord> {
    if let Some(row) = existing {
        let held = (
            row.event_created_at,
            std::cmp::Reverse(row.event_id.as_str()),
        );
        let offered = (
            incoming.event_created_at,
            std::cmp::Reverse(incoming.event_id.as_str()),
        );
        if offered <= held {
            return None;
        }
    }
    let taken = match incoming.status {
        DisputeStatus::Initiated => None,
        _ => existing.and_then(|row| row.taken.clone()),
    };
    Some(DisputeRecord {
        mostro_pubkey: incoming.mostro_pubkey.clone(),
        dispute_id: incoming.dispute_id.clone(),
        status: incoming.status,
        initiator: incoming.initiator,
        opened_at: incoming.opened_at,
        expires_at: incoming.expires_at,
        event_id: incoming.event_id.clone(),
        event_created_at: incoming.event_created_at,
        taken,
    })
}

/// Disputes as the lists show them, oldest first: the one that has waited
/// longest on top. A dispute with no open time sorts last; ties go by id, so
/// the order is stable.
pub fn sort_pending(list: &mut [DisputeSummary]) {
    list.sort_by(|a, b| oldest_first((a.opened_at, &a.dispute_id), (b.opened_at, &b.dispute_id)));
}

/// The order of [`sort_pending`], on an open time and a dispute id.
pub(crate) fn oldest_first(a: (Option<i64>, &str), b: (Option<i64>, &str)) -> std::cmp::Ordering {
    let key = |opened_at: Option<i64>| (opened_at.is_none(), opened_at.unwrap_or(0));
    key(a.0).cmp(&key(b.0)).then_with(|| a.1.cmp(b.1))
}

/// `node`'s stored rows with `status`: from storage, or from the feed's
/// memory when storage never opened.
pub(crate) async fn rows_with_status(
    node: &str,
    status: DisputeStatus,
) -> Result<Vec<DisputeRecord>> {
    Ok(match crate::db::app_db::db() {
        Some(db) => db.list_disputes_with_status(node, status).await?,
        None => feed::memory_rows(node, status).await,
    })
}

/// The pending disputes of `node` as stored now, sorted for the list.
pub async fn pending_for(node: &str) -> Result<Vec<DisputeSummary>> {
    let rows = rows_with_status(node, DisputeStatus::Initiated).await?;
    Ok(pending_of(&rows, crate::rt::unix_now()))
}

fn pending_of(rows: &[DisputeRecord], now: i64) -> Vec<DisputeSummary> {
    let mut list: Vec<DisputeSummary> = rows
        .iter()
        .filter(|row| row.is_pending(now))
        .map(|row| row.summary(now))
        .collect();
    sort_pending(&mut list);
    list
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;

    pub(crate) const NODE: &str =
        "00000235a3e904cfe1213a8a54d6f1ec1bef7cc6bfaabd6193e82931ccf1366a";
    pub(crate) const ID: &str = "8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c";

    pub(crate) fn parsed(status: DisputeStatus, created_at: i64, event_id: &str) -> ParsedDispute {
        ParsedDispute {
            mostro_pubkey: NODE.into(),
            dispute_id: ID.into(),
            status,
            initiator: DisputeInitiator::Buyer,
            opened_at: Some(1_000),
            expires_at: None,
            event_id: event_id.into(),
            event_created_at: created_at,
        }
    }

    /// A stored row of [`NODE`] with `status`, not taken.
    pub(crate) fn row_with(status: DisputeStatus) -> DisputeRecord {
        DisputeRecord {
            status,
            ..merge(None, &parsed(DisputeStatus::Initiated, 1, &"a".repeat(64))).unwrap()
        }
    }

    pub(crate) fn taken() -> TakenDispute {
        TakenDispute {
            solver_pubkey: "ab".repeat(32),
            taken_at: 1_500,
            order_id: Some("5b9e1f7e-6f0e-4b8a-9c3d-2e1f0a9b8c7d".into()),
            order_kind: Some("sell".into()),
            amount: Some(50_000),
            fiat_amount: Some(30),
            fiat_code: Some("USD".into()),
            payment_method: Some("bank transfer".into()),
            premium: Some(1),
            fee: Some(150),
            initiator_pubkey: Some("aa".into()),
            buyer_pubkey: Some("bb".into()),
            seller_pubkey: Some("cc".into()),
        }
    }

    fn hex(c: char) -> String {
        std::iter::repeat_n(c, 64).collect()
    }

    #[test]
    fn a_first_revision_makes_the_row() {
        let row = merge(None, &parsed(DisputeStatus::Initiated, 10, &hex('a'))).unwrap();
        assert_eq!(row.status, DisputeStatus::Initiated);
        assert_eq!(row.mostro_pubkey, NODE);
        assert_eq!(row.taken, None);
    }

    #[test]
    fn a_newer_revision_wins_and_an_older_one_changes_nothing() {
        let first = merge(None, &parsed(DisputeStatus::Initiated, 10, &hex('a'))).unwrap();
        let newer = merge(
            Some(&first),
            &parsed(DisputeStatus::InProgress, 11, &hex('b')),
        )
        .unwrap();
        assert_eq!(newer.status, DisputeStatus::InProgress);
        // A slow relay replays the old `initiated`: it must not undo the take.
        assert_eq!(
            merge(
                Some(&newer),
                &parsed(DisputeStatus::Initiated, 10, &hex('a'))
            ),
            None
        );
        // The same revision again is a copy, not a change.
        assert_eq!(
            merge(
                Some(&newer),
                &parsed(DisputeStatus::InProgress, 11, &hex('b'))
            ),
            None
        );
    }

    /// NIP-01: two revisions of one second resolve to the lowest id, in
    /// whichever order they arrive.
    #[test]
    fn within_one_second_the_lowest_id_wins_in_either_order() {
        let low = parsed(DisputeStatus::InProgress, 10, &hex('1'));
        let high = parsed(DisputeStatus::Initiated, 10, &hex('f'));

        let a = merge(None, &high).unwrap();
        let a = merge(Some(&a), &low).unwrap_or(a);
        let b = merge(None, &low).unwrap();
        let b = merge(Some(&b), &high).unwrap_or(b);

        assert_eq!(a.event_id, hex('1'));
        assert_eq!(b.event_id, hex('1'));
        assert_eq!(a.status, DisputeStatus::InProgress);
    }

    #[test]
    fn a_terminal_status_closes_the_row_and_keeps_the_take() {
        let mut row = merge(None, &parsed(DisputeStatus::InProgress, 10, &hex('a'))).unwrap();
        row.taken = Some(taken());
        for (n, status) in [
            DisputeStatus::Settled,
            DisputeStatus::SellerRefunded,
            DisputeStatus::Released,
            DisputeStatus::CooperativelyCanceled,
        ]
        .into_iter()
        .enumerate()
        {
            let closed = merge(Some(&row), &parsed(status, 11 + n as i64, &hex('b'))).unwrap();
            assert!(closed.status.is_terminal(), "{status:?}");
            assert!(!closed.is_pending(0));
            assert_eq!(closed.taken, Some(taken()), "{status:?}");
        }
    }

    /// mostrod reopens a resolved dispute at the escrow deadline and clears
    /// its solver: the row is pending again and no longer ours.
    #[test]
    fn a_reopen_makes_it_pending_again_and_drops_the_take() {
        let mut row = merge(None, &parsed(DisputeStatus::Settled, 10, &hex('a'))).unwrap();
        row.taken = Some(taken());
        let reopened = merge(Some(&row), &parsed(DisputeStatus::Initiated, 20, &hex('b'))).unwrap();
        assert!(reopened.is_pending(0));
        assert_eq!(reopened.taken, None);
    }

    #[test]
    fn pending_is_initiated_and_unexpired_sorted_oldest_first() {
        let row =
            |id: &str, status, opened_at: Option<i64>, expires_at: Option<i64>| DisputeRecord {
                dispute_id: id.into(),
                status,
                opened_at,
                expires_at,
                ..merge(None, &parsed(DisputeStatus::Initiated, 1, &hex('a'))).unwrap()
            };
        let rows = vec![
            row("c", DisputeStatus::Initiated, Some(300), None),
            row("a", DisputeStatus::Initiated, Some(100), Some(5_000)),
            row("x", DisputeStatus::InProgress, Some(50), None),
            row("y", DisputeStatus::Settled, Some(60), None),
            row("z", DisputeStatus::Initiated, Some(70), Some(999)),
            row("n", DisputeStatus::Initiated, None, None),
            row("b", DisputeStatus::Initiated, Some(100), None),
        ];
        let ids: Vec<String> = pending_of(&rows, 1_000)
            .into_iter()
            .map(|d| d.dispute_id)
            .collect();
        assert_eq!(ids, vec!["a", "b", "c", "n"]);
    }

    #[test]
    fn every_wire_status_round_trips_and_strangers_are_refused() {
        for status in [
            DisputeStatus::Initiated,
            DisputeStatus::InProgress,
            DisputeStatus::SellerRefunded,
            DisputeStatus::Settled,
            DisputeStatus::Released,
            DisputeStatus::CooperativelyCanceled,
        ] {
            assert_eq!(DisputeStatus::from_wire(status.as_wire()), Some(status));
            // The serde form (IndexedDB rows) is the wire form too.
            assert_eq!(
                serde_json::to_string(&status).unwrap(),
                format!("\"{}\"", status.as_wire())
            );
        }
        assert_eq!(DisputeStatus::from_wire("open"), None);
        assert_eq!(DisputeStatus::from_wire(""), None);
        assert_eq!(
            DisputeInitiator::from_wire("buyer"),
            DisputeInitiator::Buyer
        );
        assert_eq!(
            DisputeInitiator::from_wire("seller"),
            DisputeInitiator::Seller
        );
        assert_eq!(
            DisputeInitiator::from_wire("unknown"),
            DisputeInitiator::Unknown
        );
        assert_eq!(
            DisputeInitiator::from_wire("admin"),
            DisputeInitiator::Unknown
        );
    }
}
