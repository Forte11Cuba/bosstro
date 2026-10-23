//! What every [`Storage`] backend must do, written once over the trait and
//! run against each: SQLite natively (`db/sqlite.rs`), IndexedDB in a
//! browser (`db/indexeddb.rs`, `scripts/test-web-storage.sh`).
//!
//! Each check takes a fresh, empty store.

use crate::api::disputes::{DisputeInitiator, DisputeStatus};
use crate::api::relays::{RelayInfo, RelaySource, RelayStatus};
use crate::db::{settings_keys, Storage};
use crate::api::chat::{ChatDelivery, ChatParty, ChatSender};
use crate::chat::observer::{ObservedRecord, ObservedRef};
use crate::chat::{ChannelRef, ChatRecord};
use crate::disputes::{DisputeRecord, TakenDispute};

pub(crate) fn relay(url: &str) -> RelayInfo {
    RelayInfo {
        url: url.to_string(),
        is_active: true,
        is_default: false,
        source: RelaySource::UserAdded,
        is_blacklisted: false,
        status: RelayStatus::Disconnected,
        last_connected_at: None,
        last_error: None,
        announced_by: None,
    }
}

pub(crate) async fn settings_round_trip(storage: &impl Storage) {
    assert_eq!(storage.get_setting("k").await.unwrap(), None);
    storage.set_setting("k", "one").await.unwrap();
    assert_eq!(storage.get_setting("k").await.unwrap().as_deref(), Some("one"));
    storage.set_setting("k", "two").await.unwrap();
    assert_eq!(storage.get_setting("k").await.unwrap().as_deref(), Some("two"));
    storage.delete_setting("k").await.unwrap();
    assert_eq!(storage.get_setting("k").await.unwrap(), None);
    // Deleting what is not there is not an error.
    storage.delete_setting("k").await.unwrap();
}

pub(crate) async fn active_node_is_absent_until_saved(storage: &impl Storage) {
    assert_eq!(storage.get_active_mostro_pubkey().await.unwrap(), None);
    storage.save_active_mostro_pubkey("aa").await.unwrap();
    storage.save_active_mostro_pubkey("bb").await.unwrap();
    assert_eq!(
        storage.get_active_mostro_pubkey().await.unwrap().as_deref(),
        Some("bb")
    );
    // It is an ordinary setting under its documented key.
    assert_eq!(
        storage
            .get_setting(settings_keys::ACTIVE_MOSTRO_PUBKEY)
            .await
            .unwrap()
            .as_deref(),
        Some("bb")
    );
}

pub(crate) async fn relays_round_trip(storage: &impl Storage) {
    assert!(storage.list_relays().await.unwrap().is_empty());
    let mut announced = relay("wss://a.example");
    announced.source = RelaySource::MostroDiscovered;
    announced.announced_by = Some("aa".into());
    storage.save_relay(&announced).await.unwrap();
    storage.save_relay(&relay("wss://b.example")).await.unwrap();

    // A save on the same URL replaces the row.
    announced.is_blacklisted = true;
    storage.save_relay(&announced).await.unwrap();

    let mut rows = storage.list_relays().await.unwrap();
    rows.sort_by(|a, b| a.url.cmp(&b.url));
    assert_eq!(rows.len(), 2);
    assert_eq!(rows[0], announced);
    assert_eq!(rows[1], relay("wss://b.example"));

}

pub(crate) async fn node_pictures_round_trip(storage: &impl Storage) {
    assert_eq!(storage.get_node_picture("a").await.unwrap(), None);
    assert!(storage.list_node_picture_urls().await.unwrap().is_empty());

    storage
        .save_node_picture("a", "https://a.example/1.png", &[1u8; 4])
        .await
        .unwrap();
    storage
        .save_node_picture("b", "https://b.example/b.png", &[2u8; 4])
        .await
        .unwrap();
    storage
        .save_node_picture("a", "https://a.example/2.png", &[3u8; 4])
        .await
        .unwrap();

    let a = storage.get_node_picture("a").await.unwrap().unwrap();
    assert_eq!(a.url, "https://a.example/2.png");
    assert_eq!(a.bytes, vec![3u8; 4]);
    let urls = storage.list_node_picture_urls().await.unwrap();
    assert_eq!(urls.len(), 2);
    assert_eq!(urls["b"], "https://b.example/b.png");

    storage.delete_node_picture("b").await.unwrap();
    storage.delete_node_picture("b").await.unwrap();
    assert_eq!(storage.get_node_picture("b").await.unwrap(), None);
    assert!(storage.get_node_picture("a").await.unwrap().is_some());
}

pub(crate) const DISPUTE_A: &str = "8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c";
pub(crate) const DISPUTE_B: &str = "1f2e3d4c-5b6a-4978-8695-a4b3c2d1e0f9";

/// An untaken `initiated` dispute of `node`.
pub(crate) fn dispute(node: &str, id: &str) -> DisputeRecord {
    DisputeRecord {
        mostro_pubkey: node.to_string(),
        dispute_id: id.to_string(),
        status: DisputeStatus::Initiated,
        initiator: DisputeInitiator::Seller,
        opened_at: Some(1_700_000_000),
        expires_at: Some(1_900_000_000),
        event_id: "e".repeat(64),
        event_created_at: 1_700_000_100,
        taken: None,
    }
}

pub(crate) async fn disputes_round_trip(storage: &impl Storage) {
    assert!(storage.list_disputes("aa").await.unwrap().is_empty());
    assert_eq!(storage.get_dispute("aa", DISPUTE_A).await.unwrap(), None);

    // Every field survives, the optional ones absent too.
    let mut bare = dispute("aa", DISPUTE_B);
    bare.opened_at = None;
    bare.expires_at = None;
    bare.initiator = DisputeInitiator::Unknown;
    storage.save_dispute(&bare).await.unwrap();
    assert_eq!(
        storage.get_dispute("aa", DISPUTE_B).await.unwrap(),
        Some(bare.clone())
    );

    // A save on the same (node, id) replaces the row, phase 4's fields
    // included.
    let mut row = dispute("aa", DISPUTE_A);
    storage.save_dispute(&row).await.unwrap();
    row.status = DisputeStatus::InProgress;
    row.event_created_at += 1;
    row.taken = Some(TakenDispute {
        solver_pubkey: "ab".repeat(32),
        taken_at: 1_700_000_200,
        order_id: Some("5b9e1f7e-6f0e-4b8a-9c3d-2e1f0a9b8c7d".into()),
        order_kind: Some("sell".into()),
        amount: Some(50_000),
        fiat_amount: Some(30),
        fiat_code: Some("USD".into()),
        payment_method: Some("bank transfer".into()),
        premium: Some(-1),
        fee: Some(150),
        initiator_pubkey: Some("11".into()),
        buyer_pubkey: Some("22".into()),
        seller_pubkey: None,
        resolved_as: None,
        bond_slash: None,
    });
    storage.save_dispute(&row).await.unwrap();
    assert_eq!(
        storage.get_dispute("aa", DISPUTE_A).await.unwrap(),
        Some(row.clone())
    );

    // And back to untaken (a reopen).
    row.status = DisputeStatus::Initiated;
    row.taken = None;
    storage.save_dispute(&row).await.unwrap();
    assert_eq!(
        storage.get_dispute("aa", DISPUTE_A).await.unwrap(),
        Some(row.clone())
    );

    let mut all = storage.list_disputes("aa").await.unwrap();
    all.sort_by(|a, b| a.dispute_id.cmp(&b.dispute_id));
    assert_eq!(all, vec![bare, row]);
}

/// Phase 6: how this key resolved a dispute is kept with its take, every
/// word of it, and gone with the take.
pub(crate) async fn a_resolution_round_trips(storage: &impl Storage) {
    use crate::api::resolve::ResolvedAs;
    let mut row = dispute("aa", DISPUTE_A);
    row.taken = Some(crate::disputes::tests::taken());
    for (status, resolved) in [
        (DisputeStatus::Settled, ResolvedAs::PaidBuyer),
        (DisputeStatus::SellerRefunded, ResolvedAs::RefundedSeller),
        (
            DisputeStatus::CooperativelyCanceled,
            ResolvedAs::CooperativelyCanceled,
        ),
    ] {
        row.status = status;
        row.taken.as_mut().unwrap().resolved_as = Some(resolved);
        storage.save_dispute(&row).await.unwrap();
        assert_eq!(
            storage.get_dispute("aa", DISPUTE_A).await.unwrap(),
            Some(row.clone())
        );
        assert_eq!(
            storage
                .list_disputes_with_status("aa", status)
                .await
                .unwrap(),
            vec![row.clone()]
        );
    }
    // The bonds it slashed, every choice of them.
    use crate::api::resolve::BondSlash;
    for bond in [BondSlash::NoSlash, BondSlash::Buyer, BondSlash::Seller, BondSlash::Both] {
        row.taken.as_mut().unwrap().bond_slash = Some(bond);
        storage.save_dispute(&row).await.unwrap();
        assert_eq!(
            storage.get_dispute("aa", DISPUTE_A).await.unwrap(),
            Some(row.clone()),
            "{bond:?}"
        );
    }
    row.taken = None;
    storage.save_dispute(&row).await.unwrap();
    assert_eq!(
        storage.get_dispute("aa", DISPUTE_A).await.unwrap(),
        Some(row)
    );
}

/// D6: the same dispute id under two nodes is two rows, and a node's list
/// holds only its own.
pub(crate) async fn disputes_never_mix_nodes(storage: &impl Storage) {
    let mine = dispute("aa", DISPUTE_A);
    let mut theirs = dispute("bb", DISPUTE_A);
    theirs.status = DisputeStatus::Settled;
    storage.save_dispute(&mine).await.unwrap();
    storage.save_dispute(&theirs).await.unwrap();
    storage
        .save_dispute(&dispute("bb", DISPUTE_B))
        .await
        .unwrap();

    assert_eq!(
        storage.list_disputes("aa").await.unwrap(),
        vec![mine.clone()]
    );
    assert_eq!(storage.list_disputes("bb").await.unwrap().len(), 2);
    assert_eq!(
        storage.get_dispute("aa", DISPUTE_A).await.unwrap(),
        Some(mine)
    );
    assert_eq!(
        storage.get_dispute("bb", DISPUTE_A).await.unwrap(),
        Some(theirs)
    );
    assert!(storage.list_disputes("cc").await.unwrap().is_empty());
}

/// Pending's query: one node's rows with one status, and nothing else.
pub(crate) async fn disputes_by_status(storage: &impl Storage) {
    let waiting = dispute("aa", DISPUTE_A);
    let mut taken = dispute("aa", DISPUTE_B);
    taken.status = DisputeStatus::InProgress;
    // Another node's `initiated` row, keyed so it sorts right after `aa`'s.
    let elsewhere = dispute("aab", DISPUTE_A);
    for row in [&waiting, &taken, &elsewhere] {
        storage.save_dispute(row).await.unwrap();
    }

    let initiated = storage
        .list_disputes_with_status("aa", DisputeStatus::Initiated)
        .await
        .unwrap();
    assert_eq!(initiated, vec![waiting]);
    let in_progress = storage
        .list_disputes_with_status("aa", DisputeStatus::InProgress)
        .await
        .unwrap();
    assert_eq!(in_progress, vec![taken]);
    assert!(storage
        .list_disputes_with_status("aa", DisputeStatus::Settled)
        .await
        .unwrap()
        .is_empty());
    assert!(storage
        .list_disputes_with_status("a", DisputeStatus::Initiated)
        .await
        .unwrap()
        .is_empty());
}

/// Phase 4: a take keeps the key that made it, so In progress and Recover
/// can tell this key's disputes from another key's on the same device.
pub(crate) async fn takes_keep_their_solver(storage: &impl Storage) {
    let take = |solver: &str| TakenDispute {
        solver_pubkey: solver.to_string(),
        taken_at: 1_700_000_200,
        order_id: None,
        order_kind: None,
        amount: Some(21_000),
        fiat_amount: None,
        fiat_code: None,
        payment_method: None,
        premium: None,
        fee: None,
        initiator_pubkey: None,
        buyer_pubkey: None,
        seller_pubkey: None,
        resolved_as: None,
        bond_slash: None,
    };
    let mut mine = dispute("aa", DISPUTE_A);
    mine.status = DisputeStatus::InProgress;
    mine.taken = Some(take(&"11".repeat(32)));
    let mut other_key = dispute("aa", DISPUTE_B);
    other_key.status = DisputeStatus::InProgress;
    other_key.taken = Some(take(&"22".repeat(32)));
    storage.save_dispute(&mine).await.unwrap();
    storage.save_dispute(&other_key).await.unwrap();

    let mut rows = storage
        .list_disputes_with_status("aa", DisputeStatus::InProgress)
        .await
        .unwrap();
    rows.sort_by(|a, b| a.dispute_id.cmp(&b.dispute_id));
    assert_eq!(rows, vec![other_key, mine]);
}

pub(crate) fn channel(node: &str, dispute: &str, party: ChatParty, solver: &str) -> ChannelRef {
    ChannelRef {
        mostro_pubkey: node.into(),
        dispute_id: dispute.into(),
        party,
        solver_pubkey: solver.into(),
    }
}

pub(crate) fn message(channel: &ChannelRef, id: &str, created_at: i64) -> ChatRecord {
    ChatRecord {
        channel: channel.clone(),
        message_id: id.into(),
        sender: channel.party.sender(),
        content: format!("text of {id}"),
        created_at,
        received_at: created_at,
        delivery: ChatDelivery::Sent,
        seq: 0,
    }
}

/// A stored message without the arrival order the store gave it.
fn unseq(record: ChatRecord) -> ChatRecord {
    ChatRecord { seq: 0, ..record }
}

/// Three messages of the same second stored in the order they arrived keep
/// it: their `seq` grows with each insert (a copy takes none), whatever their
/// ids say.
pub(crate) async fn chat_messages_keep_their_arrival_order(storage: &impl Storage) {
    let buyer = channel("aa", DISPUTE_A, ChatParty::Buyer, "ss");
    let arrived = ["m3", "m1", "m2"];
    for id in arrived {
        assert!(storage
            .insert_chat_message(&message(&buyer, id, 100))
            .await
            .unwrap());
    }
    assert!(!storage
        .insert_chat_message(&message(&buyer, "m3", 100))
        .await
        .unwrap());
    let mut rows = storage.list_chat_messages(&buyer).await.unwrap();
    rows.sort_by_key(|r| r.seq);
    let order: Vec<&str> = rows.iter().map(|r| r.message_id.as_str()).collect();
    assert_eq!(order, arrived);
    assert!(rows.windows(2).all(|w| w[0].seq < w[1].seq), "strictly growing");
}

pub(crate) async fn chat_messages_round_trip(storage: &impl Storage) {
    let buyer = channel("aa", DISPUTE_A, ChatParty::Buyer, "ss");
    assert!(storage.list_chat_messages(&buyer).await.unwrap().is_empty());
    assert_eq!(storage.chat_cursor(&buyer).await.unwrap(), None);

    let first = message(&buyer, "m1", 100);
    assert!(storage.insert_chat_message(&first).await.unwrap());
    // The same id again is a copy: not stored twice, not replaced.
    let mut copy = first.clone();
    copy.content = "something else".into();
    assert!(!storage.insert_chat_message(&copy).await.unwrap());
    assert_eq!(
        storage.get_chat_message(&buyer, "m1").await.unwrap().map(unseq),
        Some(first.clone())
    );

    let mut mine = message(&buyer, "m2", 200);
    mine.sender = ChatSender::You;
    mine.delivery = ChatDelivery::Sending;
    assert!(storage.insert_chat_message(&mine).await.unwrap());
    storage
        .set_chat_delivery(&buyer, "m2", ChatDelivery::Failed)
        .await
        .unwrap();
    assert_eq!(
        storage
            .get_chat_message(&buyer, "m2")
            .await
            .unwrap()
            .unwrap()
            .delivery,
        ChatDelivery::Failed
    );
    // Absent rows are not an error.
    storage
        .set_chat_delivery(&buyer, "nope", ChatDelivery::Sent)
        .await
        .unwrap();
    storage.delete_chat_message(&buyer, "nope").await.unwrap();

    let mut rows = storage.list_chat_messages(&buyer).await.unwrap();
    rows.sort_by(|a, b| a.message_id.cmp(&b.message_id));
    assert_eq!(rows.len(), 2);
    assert_eq!(unseq(rows[0].clone()), first);
    assert_eq!(storage.chat_cursor(&buyer).await.unwrap(), Some(200));

    storage.delete_chat_message(&buyer, "m2").await.unwrap();
    let rows = storage.list_chat_messages(&buyer).await.unwrap();
    assert_eq!(rows.into_iter().map(unseq).collect::<Vec<_>>(), vec![first]);
    assert_eq!(storage.chat_cursor(&buyer).await.unwrap(), Some(100));
}

/// Two parties, two disputes, two nodes, two solver keys: four channels
/// that share nothing (D6).
pub(crate) async fn chat_channels_never_mix(storage: &impl Storage) {
    let channels = [
        channel("aa", DISPUTE_A, ChatParty::Buyer, "ss"),
        channel("aa", DISPUTE_A, ChatParty::Seller, "ss"),
        channel("aa", DISPUTE_B, ChatParty::Buyer, "ss"),
        channel("bb", DISPUTE_A, ChatParty::Buyer, "ss"),
        channel("aa", DISPUTE_A, ChatParty::Buyer, "tt"),
    ];
    for (n, c) in channels.iter().enumerate() {
        // The same message id in every channel: still one row each.
        assert!(storage
            .insert_chat_message(&message(c, "same", 10 * (n as i64 + 1)))
            .await
            .unwrap());
    }
    for (n, c) in channels.iter().enumerate() {
        let rows = storage.list_chat_messages(c).await.unwrap();
        assert_eq!(rows.len(), 1, "{c:?}");
        assert_eq!(&rows[0].channel, c);
        assert_eq!(rows[0].created_at, 10 * (n as i64 + 1));
        assert_eq!(
            storage.chat_cursor(c).await.unwrap(),
            Some(10 * (n as i64 + 1))
        );
    }
    storage
        .delete_chat_message(&channels[0], "same")
        .await
        .unwrap();
    assert!(storage
        .list_chat_messages(&channels[0])
        .await
        .unwrap()
        .is_empty());
    assert_eq!(storage.list_chat_messages(&channels[1]).await.unwrap().len(), 1);
}

/// A message dated in the future moves the cursor only to when it was
/// accepted.
pub(crate) async fn the_chat_cursor_never_passes_the_clock_of_acceptance(storage: &impl Storage) {
    let seller = channel("aa", DISPUTE_A, ChatParty::Seller, "ss");
    let mut early = message(&seller, "m1", 1_000);
    early.received_at = 1_005;
    let mut future = message(&seller, "m2", 9_999_999_999);
    future.received_at = 2_000;
    storage.insert_chat_message(&early).await.unwrap();
    storage.insert_chat_message(&future).await.unwrap();
    assert_eq!(storage.chat_cursor(&seller).await.unwrap(), Some(2_000));
}

pub(crate) fn observed_ref(node: &str, dispute: &str, solver: &str) -> ObservedRef {
    ObservedRef {
        mostro_pubkey: node.into(),
        dispute_id: dispute.into(),
        solver_pubkey: solver.into(),
    }
}

pub(crate) fn observed(chat: &ObservedRef, id: &str, sender: ChatParty) -> ObservedRecord {
    ObservedRecord {
        conversation: chat.clone(),
        message_id: id.into(),
        sender,
        content: format!("observed {id}"),
        created_at: 100,
        received_at: 200,
    }
}

/// An observed chat keeps each message once, by its inner id, with its
/// verified sender.
pub(crate) async fn observed_messages_round_trip(storage: &impl Storage) {
    let chat = observed_ref("aa", DISPUTE_A, "ss");
    assert!(storage.list_observed_messages(&chat).await.unwrap().is_empty());
    let buyer = observed(&chat, "o1", ChatParty::Buyer);
    let seller = observed(&chat, "o2", ChatParty::Seller);
    assert!(storage.insert_observed_message(&buyer).await.unwrap());
    assert!(storage.insert_observed_message(&seller).await.unwrap());
    // A re-read of the same message is a copy: not stored twice, not replaced.
    let mut copy = buyer.clone();
    copy.content = "something else".into();
    copy.received_at = 999;
    assert!(!storage.insert_observed_message(&copy).await.unwrap());
    let mut rows = storage.list_observed_messages(&chat).await.unwrap();
    rows.sort_by(|a, b| a.message_id.cmp(&b.message_id));
    assert_eq!(rows, vec![buyer, seller]);
}

/// Observed chats of two nodes, disputes and solver keys share nothing
/// (D6), and none of them is ever read as one of the solver's own chats, or
/// the other way round.
pub(crate) async fn observed_chats_never_mix_with_each_other_or_the_chat(storage: &impl Storage) {
    let chats = [
        observed_ref("aa", DISPUTE_A, "ss"),
        observed_ref("aa", DISPUTE_B, "ss"),
        observed_ref("bb", DISPUTE_A, "ss"),
        observed_ref("aa", DISPUTE_A, "tt"),
    ];
    for (n, chat) in chats.iter().enumerate() {
        let record = observed(chat, &format!("o{n}"), ChatParty::Buyer);
        assert!(storage.insert_observed_message(&record).await.unwrap());
    }
    for (n, chat) in chats.iter().enumerate() {
        let rows = storage.list_observed_messages(chat).await.unwrap();
        assert_eq!(rows.len(), 1, "{chat:?}");
        assert_eq!(rows[0].message_id, format!("o{n}"));
    }
    // The solver's own chats of the same dispute and key hold none of them.
    for party in [ChatParty::Buyer, ChatParty::Seller] {
        let own = channel("aa", DISPUTE_A, party, "ss");
        assert!(storage.list_chat_messages(&own).await.unwrap().is_empty());
    }
    // And a message of the solver's chat is not an observed one.
    let own = channel("aa", DISPUTE_A, ChatParty::Seller, "tt");
    storage
        .insert_chat_message(&message(&own, "m1", 10))
        .await
        .unwrap();
    let rows = storage.list_observed_messages(&chats[3]).await.unwrap();
    assert_eq!(rows.len(), 1);
    assert_eq!(rows[0].message_id, "o3");
}

/// The attachment cache: kept by hash, read back whole, bounded oldest first.
pub(crate) async fn attachment_blobs_are_cached_and_bounded(storage: &impl Storage) {
    assert_eq!(storage.get_attachment_blob("a").await.unwrap(), None);
    storage.save_attachment_blob("a", &[1u8; 10]).await.unwrap();
    storage.save_attachment_blob("b", &[2u8; 10]).await.unwrap();
    storage.save_attachment_blob("c", &[3u8; 10]).await.unwrap();
    assert_eq!(
        storage.get_attachment_blob("b").await.unwrap(),
        Some(vec![2u8; 10])
    );
    // Saved within one second: the last saved is the newest.
    storage.trim_attachment_blobs(25).await.unwrap();
    assert_eq!(storage.get_attachment_blob("a").await.unwrap(), None);
    assert!(storage.get_attachment_blob("b").await.unwrap().is_some());
    assert!(storage.get_attachment_blob("c").await.unwrap().is_some());
    // Saving again replaces, never duplicates.
    storage.save_attachment_blob("c", &[4u8; 10]).await.unwrap();
    assert_eq!(
        storage.get_attachment_blob("c").await.unwrap(),
        Some(vec![4u8; 10])
    );
    storage.trim_attachment_blobs(20).await.unwrap();
    assert!(storage.get_attachment_blob("c").await.unwrap().is_some());
}
