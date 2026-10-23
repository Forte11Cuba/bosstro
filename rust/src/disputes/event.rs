//! Reading one kind 38386 dispute event.
//!
//! mostrod builds it in `nip33.rs` (`new_dispute_event`,
//! `create_dispute_event_tags`): `d` = the dispute id, `s` = its status,
//! `initiator`, `published_at` = when the dispute was opened, `y` = the
//! platform, `z` = `dispute`, and a NIP-40 `expiration`. No amount and no
//! order id. The event's own `created_at` is the time of the revision, bumped
//! past the previous one (NIP-33 replacement), so it is never the open time.

use nostr_sdk::prelude::{Event, Kind, PublicKey};

use crate::api::disputes::{DisputeInitiator, DisputeStatus};

/// The dispute event kind (mostro-core `NOSTR_DISPUTE_EVENT_KIND`).
pub const KIND_DISPUTE: u16 = mostro_core::prelude::NOSTR_DISPUTE_EVENT_KIND;

/// What one revision says about a dispute.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ParsedDispute {
    pub mostro_pubkey: String,
    /// Lowercase hyphenated UUID, whatever case the tag used.
    pub dispute_id: String,
    pub status: DisputeStatus,
    pub initiator: DisputeInitiator,
    pub opened_at: Option<i64>,
    pub expires_at: Option<i64>,
    pub event_id: String,
    pub event_created_at: i64,
}

/// Why an event was not taken as a dispute revision.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Rejected {
    WrongKind,
    /// Not authored by the node being read: anyone can publish a 38386.
    WrongAuthor,
    /// The id or signature does not hold.
    BadSignature,
    /// No `d` tag, or one that is not a UUID.
    BadDisputeId,
    /// No `s` tag, or a status mostro-core does not know.
    BadStatus,
    /// Past its NIP-40 expiration: relays drop it, and so does the client.
    Expired,
}

/// Read `event` as a revision of one of `node`'s disputes, at time `now`.
///
/// Only an event of the dispute kind, authored by `node`, whose id and
/// signature verify, with a UUID `d` and a known `s`, is accepted
/// (Mostrix `parse_disputes_events` / `dispute_from_tags`). The open time is
/// the `published_at` tag, else the legacy `created_at` tag that older
/// daemons wrote; a malformed or non-positive value never erases a good one
/// read earlier. With neither, the open time is unknown.
pub fn parse_dispute_event(
    event: &Event,
    node: &PublicKey,
    now: i64,
) -> Result<ParsedDispute, Rejected> {
    if event.kind != Kind::Custom(KIND_DISPUTE) {
        return Err(Rejected::WrongKind);
    }
    if event.pubkey != *node {
        return Err(Rejected::WrongAuthor);
    }
    if event.verify().is_err() {
        return Err(Rejected::BadSignature);
    }

    let mut dispute_id = None;
    let mut status = None;
    let mut initiator = None;
    let mut published_at = None;
    let mut legacy_created_at = None;
    let mut expires_at = None;
    for tag in event.tags.iter() {
        let values = tag.as_slice();
        let (Some(key), Some(value)) = (values.first(), values.get(1)) else {
            continue;
        };
        match key.as_str() {
            "d" if dispute_id.is_none() => {
                let id = uuid::Uuid::parse_str(value).map_err(|_| Rejected::BadDisputeId)?;
                dispute_id = Some(id.to_string());
            }
            "s" if status.is_none() => {
                status = Some(DisputeStatus::from_wire(value).ok_or(Rejected::BadStatus)?);
            }
            "initiator" if initiator.is_none() => {
                initiator = Some(DisputeInitiator::from_wire(value));
            }
            "published_at" => published_at = positive_timestamp(value).or(published_at),
            "created_at" => legacy_created_at = positive_timestamp(value).or(legacy_created_at),
            "expiration" => expires_at = positive_timestamp(value).or(expires_at),
            _ => {}
        }
    }

    let dispute_id = dispute_id.ok_or(Rejected::BadDisputeId)?;
    let status = status.ok_or(Rejected::BadStatus)?;
    if expires_at.is_some_and(|at| at <= now) {
        return Err(Rejected::Expired);
    }
    Ok(ParsedDispute {
        mostro_pubkey: node.to_hex(),
        dispute_id,
        status,
        initiator: initiator.unwrap_or(DisputeInitiator::Unknown),
        opened_at: published_at.or(legacy_created_at),
        expires_at,
        event_id: event.id.to_hex(),
        event_created_at: event.created_at.as_secs() as i64,
    })
}

/// A positive Unix-seconds value; `None` when malformed or not positive.
fn positive_timestamp(value: &str) -> Option<i64> {
    value.parse::<i64>().ok().filter(|ts| *ts > 0)
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use nostr_sdk::prelude::*;

    pub(crate) const DISPUTE_ID: &str = "8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c";
    const NOW: i64 = 1_800_000_000;

    /// A dispute revision as mostrod builds it, signed by `keys`.
    pub(crate) fn dispute_event(keys: &Keys, tags: &[&[&str]], created_at: u64) -> Event {
        let tags = tags.iter().map(|t| Tag::parse(t.iter().copied()).unwrap());
        EventBuilder::new(Kind::Custom(KIND_DISPUTE), "")
            .tags(tags)
            .custom_created_at(Timestamp::from_secs(created_at))
            .finalize(keys)
            .unwrap()
    }

    /// mostrod's tag set (`create_dispute_event_tags`) for `status`.
    pub(crate) fn mostrod_event(keys: &Keys, id: &str, status: &str, created_at: u64) -> Event {
        dispute_event(
            keys,
            &[
                &["d", id],
                &["expiration", "1900000000"],
                &["s", status],
                &["initiator", "seller"],
                &["published_at", "1700000000"],
                &["y", "mostro", "Mostro Cuba"],
                &["z", "dispute"],
            ],
            created_at,
        )
    }

    #[test]
    fn reads_what_mostrod_publishes() {
        let keys = Keys::generate();
        let event = mostrod_event(&keys, DISPUTE_ID, "initiated", 1_700_000_100);

        let got = parse_dispute_event(&event, &keys.public_key(), NOW).unwrap();

        assert_eq!(got.mostro_pubkey, keys.public_key().to_hex());
        assert_eq!(got.dispute_id, DISPUTE_ID);
        assert_eq!(got.status, DisputeStatus::Initiated);
        assert_eq!(got.initiator, DisputeInitiator::Seller);
        assert_eq!(
            got.opened_at,
            Some(1_700_000_000),
            "from published_at, not created_at"
        );
        assert_eq!(got.expires_at, Some(1_900_000_000));
        assert_eq!(got.event_id, event.id.to_hex());
        assert_eq!(got.event_created_at, 1_700_000_100);
    }

    /// Older daemons wrote the open time as a `created_at` tag.
    #[test]
    fn falls_back_to_the_legacy_created_at_tag() {
        let keys = Keys::generate();
        let event = dispute_event(
            &keys,
            &[
                &["d", DISPUTE_ID],
                &["s", "in-progress"],
                &["created_at", "1690000000"],
            ],
            1_700_000_100,
        );
        let got = parse_dispute_event(&event, &keys.public_key(), NOW).unwrap();
        assert_eq!(got.opened_at, Some(1_690_000_000));
        assert_eq!(got.status, DisputeStatus::InProgress);
        assert_eq!(got.initiator, DisputeInitiator::Unknown, "no initiator tag");
    }

    #[test]
    fn published_at_wins_over_the_legacy_tag_and_a_bad_duplicate_erases_nothing() {
        let keys = Keys::generate();
        let event = dispute_event(
            &keys,
            &[
                &["d", DISPUTE_ID],
                &["s", "initiated"],
                &["created_at", "1690000000"],
                &["published_at", "1700000000"],
                &["published_at", "soon"],
                &["published_at", "-5"],
            ],
            1_700_000_100,
        );
        let got = parse_dispute_event(&event, &keys.public_key(), NOW).unwrap();
        assert_eq!(got.opened_at, Some(1_700_000_000));
    }

    /// Never the event's own created_at: that is when the revision was signed.
    #[test]
    fn without_an_open_time_tag_the_open_time_is_unknown() {
        let keys = Keys::generate();
        let event = dispute_event(
            &keys,
            &[&["d", DISPUTE_ID], &["s", "initiated"]],
            1_700_000_100,
        );
        let got = parse_dispute_event(&event, &keys.public_key(), NOW).unwrap();
        assert_eq!(got.opened_at, None);
    }

    #[test]
    fn the_dispute_id_is_kept_in_canonical_form() {
        let keys = Keys::generate();
        let upper = DISPUTE_ID.to_uppercase();
        let event = dispute_event(&keys, &[&["d", &upper], &["s", "initiated"]], 1);
        let got = parse_dispute_event(&event, &keys.public_key(), NOW).unwrap();
        assert_eq!(got.dispute_id, DISPUTE_ID);
    }

    #[test]
    fn an_event_signed_by_anyone_else_is_refused() {
        let node = Keys::generate();
        let stranger = Keys::generate();
        let event = mostrod_event(&stranger, DISPUTE_ID, "initiated", 1);
        assert_eq!(
            parse_dispute_event(&event, &node.public_key(), NOW),
            Err(Rejected::WrongAuthor)
        );
    }

    /// A forgery that names the node as author but carries someone else's
    /// signature, or tags changed after signing.
    #[test]
    fn a_forged_event_in_the_nodes_name_is_refused() {
        let node = Keys::generate();
        let stranger = Keys::generate();

        let mut json: serde_json::Value =
            serde_json::from_str(&mostrod_event(&stranger, DISPUTE_ID, "initiated", 1).as_json())
                .unwrap();
        json["pubkey"] = node.public_key().to_hex().into();
        let forged = Event::from_json(json.to_string()).unwrap();
        assert_eq!(
            parse_dispute_event(&forged, &node.public_key(), NOW),
            Err(Rejected::BadSignature)
        );

        let mut json: serde_json::Value =
            serde_json::from_str(&mostrod_event(&node, DISPUTE_ID, "in-progress", 1).as_json())
                .unwrap();
        json["tags"][2] = serde_json::json!(["s", "initiated"]);
        let tampered = Event::from_json(json.to_string()).unwrap();
        assert_eq!(
            parse_dispute_event(&tampered, &node.public_key(), NOW),
            Err(Rejected::BadSignature)
        );
    }

    #[test]
    fn a_bad_id_a_bad_status_or_another_kind_is_refused() {
        let keys = Keys::generate();
        let node = keys.public_key();
        let cases: [(&[&[&str]], Rejected); 5] = [
            (
                &[&["d", "not-a-uuid"], &["s", "initiated"]],
                Rejected::BadDisputeId,
            ),
            (&[&["s", "initiated"]], Rejected::BadDisputeId),
            (&[&["d", DISPUTE_ID], &["s", "open"]], Rejected::BadStatus),
            (&[&["d", DISPUTE_ID]], Rejected::BadStatus),
            (
                &[
                    &["d", DISPUTE_ID],
                    &["s", "initiated"],
                    &["expiration", "1700000000"],
                ],
                Rejected::Expired,
            ),
        ];
        for (tags, why) in cases {
            let event = dispute_event(&keys, tags, 1);
            assert_eq!(
                parse_dispute_event(&event, &node, NOW),
                Err(why),
                "{tags:?}"
            );
        }

        let order = EventBuilder::new(Kind::Custom(38383), "")
            .tags([
                Tag::parse(["d", DISPUTE_ID]).unwrap(),
                Tag::parse(["s", "pending"]).unwrap(),
            ])
            .finalize(&keys)
            .unwrap();
        assert_eq!(
            parse_dispute_event(&order, &node, NOW),
            Err(Rejected::WrongKind)
        );
    }
}
