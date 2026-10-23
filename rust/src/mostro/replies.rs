//! The node's answers to this solver key: one kind 14 subscription, authored
//! by the active node and `p`-tagged to the loaded key, apart from the 38386
//! feed and kept alive by `nostr::live_subs`.
//!
//! **What is taken.** Only an event the active node signed (the filter pins
//! the author, and the unwrapped sender is checked again), that opens with
//! the loaded key, whose message carries the `request_id` of a request this
//! process sent to that same node with that same key. Anything else is
//! dropped. The content is never logged.
//!
//! **Requests** (a take, a resolution) wait in [`Router::register`] until
//! their answer arrives or they age out ([`LATE_WINDOW_SECS`]); a caller that
//! stopped waiting (`take::ANSWER_WAIT`) leaves its request there, so a late
//! answer is still applied. A retarget to another node or key drops the requests of the old
//! one: their answers are not taken.
//!
//! **Since.** The subscription starts a minute before it is opened, so a
//! reconnect never replays the node's older answers; requests exist only in
//! this process, so an older answer could match none anyway.

use std::collections::{HashMap, HashSet, VecDeque};
use std::sync::{Arc, Mutex, OnceLock};

use nostr_sdk::prelude::{
    Client, ClientNotification, Event, EventId, Filter, Keys, Kind, PublicKey, RelayMessage,
    StreamExt, SubscriptionId, Timestamp,
};
use tokio::sync::{mpsc, oneshot};

use crate::api::disputes::DisputeStatus;
use crate::api::resolve::{Resolution, ResolveResult};
use crate::api::take::TakeResult;
use crate::disputes::feed::Feed;
use crate::nostr::live_subs::LiveSubs;

/// How long a request is kept for a late answer.
pub(crate) const LATE_WINDOW_SECS: i64 = 600;

/// How far back the subscription reaches when it opens: clock skew between
/// the phone and the node.
const SINCE_SKEW_SECS: u64 = 60;

/// How many handled event ids are remembered (each relay sends a copy).
const SEEN_CAPACITY: usize = 256;

/// One request sent and not answered yet.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Request {
    /// The node it went to (hex).
    pub node: String,
    /// The key that signed it (hex).
    pub solver: String,
    pub dispute_id: String,
    pub purpose: Purpose,
}

/// What a request asked for, which decides how its answer is read.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) enum Purpose {
    /// `AdminTakeDispute`, sent while the dispute was stored with
    /// `status_at_send`.
    Take { status_at_send: DisputeStatus },
    /// `AdminSettle` or `AdminCancel` of the dispute's order.
    Resolve {
        resolution: Resolution,
        order_id: String,
    },
}

/// What the caller of a request gets back.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) enum Reply {
    Take(TakeResult),
    Resolve(ResolveResult),
}

/// A request of the same dispute on the same node is still waited for.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) struct Busy;

struct Waiting {
    request: Request,
    registered_at: i64,
    /// The caller, while it waits.
    reply: Option<oneshot::Sender<Reply>>,
}

/// Who the subscription is for.
#[derive(Clone)]
struct Target {
    node: PublicKey,
    keys: Keys,
    sub: SubscriptionId,
}

/// The subscription id of `node` and `solver` (both hex):
/// `daemon-<16 hex>-<16 hex>`, within NIP-01's 64 characters.
pub(crate) fn subscription_id(node: &str, solver: &str) -> SubscriptionId {
    let short = |s: &str| s.chars().take(16).collect::<String>();
    SubscriptionId::new(format!("daemon-{}-{}", short(node), short(solver)))
}

/// Every kind 14 the node sends to `solver`, from `since` on.
pub(crate) fn answers_filter(node: &PublicKey, solver: &PublicKey, since: Timestamp) -> Filter {
    Filter::new()
        .kind(Kind::PrivateDirectMessage)
        .author(*node)
        .pubkey(*solver)
        .since(since)
}

fn lock<T>(m: &Mutex<T>) -> std::sync::MutexGuard<'_, T> {
    m.lock().unwrap_or_else(std::sync::PoisonError::into_inner)
}

#[derive(Default)]
struct Seen {
    ids: HashSet<EventId>,
    order: VecDeque<EventId>,
}

impl Seen {
    /// Whether `id` is new; remembers it.
    fn first_time(&mut self, id: EventId) -> bool {
        if !self.ids.insert(id) {
            return false;
        }
        self.order.push_back(id);
        if self.order.len() > SEEN_CAPACITY {
            if let Some(oldest) = self.order.pop_front() {
                self.ids.remove(&oldest);
            }
        }
        true
    }
}

pub(crate) struct Router {
    client: Arc<Client>,
    subs: &'static LiveSubs,
    feed: Arc<Feed>,
    target: Mutex<Option<Target>>,
    waiting: Mutex<HashMap<u64, Waiting>>,
    seen: Mutex<Seen>,
    /// Serialises retargets, each closing the previous subscription.
    retarget_lock: tokio::sync::Mutex<()>,
}

impl Router {
    pub(crate) fn new(client: Arc<Client>, subs: &'static LiveSubs, feed: Arc<Feed>) -> Arc<Self> {
        Arc::new(Self {
            client,
            subs,
            feed,
            target: Mutex::new(None),
            waiting: Mutex::new(HashMap::new()),
            seen: Mutex::new(Seen::default()),
            retarget_lock: tokio::sync::Mutex::new(()),
        })
    }

    /// Read the client's notifications for as long as it lives: the reader
    /// only passes on the kind 14 events of the current subscription, in
    /// order, so it never falls behind the client's bounded broadcast; a
    /// second task opens them (as the 38386 feed).
    pub(crate) fn spawn_reader(self: &Arc<Self>) {
        let (tx, mut rx) = mpsc::unbounded_channel::<Box<Event>>();
        let mut notifications = self.client.notifications();
        let router = self.clone();
        crate::rt::spawn(async move {
            while let Some(notification) = notifications.next().await {
                let ClientNotification::Message { message, .. } = notification else {
                    continue;
                };
                let RelayMessage::Event {
                    subscription_id,
                    event,
                } = *message
                else {
                    continue;
                };
                if event.kind != Kind::PrivateDirectMessage
                    || router.current_sub().as_ref() != Some(subscription_id.as_ref())
                {
                    continue;
                }
                if tx.send(Box::new(event.into_owned())).is_err() {
                    break;
                }
            }
        });
        let router = self.clone();
        crate::rt::spawn(async move {
            while let Some(event) = rx.recv().await {
                router.handle(&event).await;
            }
        });
    }

    fn current_sub(&self) -> Option<SubscriptionId> {
        lock(&self.target).as_ref().map(|t| t.sub.clone())
    }

    /// Follow `node`'s answers to `keys`, or nothing. Following what it
    /// already follows changes nothing; otherwise the previous subscription
    /// closes and the requests made under it are dropped.
    pub(crate) async fn retarget(&self, node: Option<String>, keys: Option<Keys>) {
        let _guard = self.retarget_lock.lock().await;
        let next = match (node.as_deref().map(PublicKey::from_hex), keys) {
            (Some(Ok(node)), Some(keys)) => Some(Target {
                sub: subscription_id(&node.to_hex(), &keys.public_key().to_hex()),
                node,
                keys,
            }),
            _ => None,
        };
        let previous = {
            let mut target = lock(&self.target);
            let same = match (&*target, &next) {
                (Some(a), Some(b)) => {
                    a.node == b.node && a.keys.public_key() == b.keys.public_key()
                }
                (None, None) => true,
                _ => false,
            };
            if same {
                return;
            }
            std::mem::replace(&mut *target, next.clone())
        };
        {
            let keep = next
                .as_ref()
                .map(|t| (t.node.to_hex(), t.keys.public_key().to_hex()));
            lock(&self.waiting).retain(|_, w| {
                keep.as_ref().is_some_and(|(node, solver)| {
                    &w.request.node == node && &w.request.solver == solver
                })
            });
        }
        if let Some(previous) = previous {
            self.subs.close(&self.client, &previous.sub).await;
        }
        let Some(target) = next else {
            return;
        };
        let since = Timestamp::from_secs(
            (crate::rt::unix_now().max(0) as u64).saturating_sub(SINCE_SKEW_SECS),
        );
        let filter = answers_filter(&target.node, &target.keys.public_key(), since);
        if let Err(e) = self
            .subs
            .replace(&self.client, target.sub.clone(), filter)
            .await
        {
            log::warn!("[daemon] subscribe {} failed: {e}", target.sub);
        }
    }

    /// Wait for the answer to `request_id`. Refused while a request (a take
    /// or a resolution) of the same dispute on the same node is still waited
    /// for; one whose caller stopped waiting does not count.
    pub(crate) fn register(
        &self,
        request_id: u64,
        request: Request,
    ) -> Result<oneshot::Receiver<Reply>, Busy> {
        let now = crate::rt::unix_now();
        let (tx, rx) = oneshot::channel();
        let mut waiting = lock(&self.waiting);
        waiting.retain(|_, w| now - w.registered_at < LATE_WINDOW_SECS);
        let busy = waiting.values().any(|w| {
            w.request.node == request.node
                && w.request.dispute_id == request.dispute_id
                && w.reply.as_ref().is_some_and(|r| !r.is_closed())
        });
        if busy {
            return Err(Busy);
        }
        waiting.insert(
            request_id,
            Waiting {
                request,
                registered_at: now,
                reply: Some(tx),
            },
        );
        Ok(rx)
    }

    /// Drop a request that never left.
    pub(crate) fn forget(&self, request_id: u64) {
        lock(&self.waiting).remove(&request_id);
    }

    /// The resolution of `dispute_id` on `node` sent by `solver` that is still
    /// waiting for its answer although its caller stopped waiting: the node
    /// may have acted on it. The newest, if several.
    pub(crate) fn unanswered_resolution(
        &self,
        node: &str,
        solver: &str,
        dispute_id: &str,
    ) -> Option<Resolution> {
        let now = crate::rt::unix_now();
        lock(&self.waiting)
            .values()
            .filter(|w| {
                w.request.node == node
                    && w.request.solver == solver
                    && w.request.dispute_id == dispute_id
                    && now - w.registered_at < LATE_WINDOW_SECS
                    && w.reply.as_ref().is_none_or(|r| r.is_closed())
            })
            .max_by_key(|w| w.registered_at)
            .and_then(|w| match &w.request.purpose {
                Purpose::Resolve { resolution, .. } => Some(*resolution),
                Purpose::Take { .. } => None,
            })
    }

    /// One kind 14 of the current subscription.
    pub(crate) async fn handle(&self, event: &Event) {
        let Some(target) = lock(&self.target).clone() else {
            return;
        };
        if event.pubkey != target.node {
            log::debug!("[daemon] dropped a kind 14 the node did not sign");
            return;
        }
        if !lock(&self.seen).first_time(event.id) {
            return;
        }
        let opened = match crate::nostr::transport::unwrap_mostro_message(&target.keys, event).await
        {
            Ok(Some(opened)) => opened,
            Ok(None) => return,
            Err(e) => {
                log::debug!("[daemon] unreadable answer dropped: {e}");
                return;
            }
        };
        if opened.sender != target.node {
            return;
        }
        let Some(request_id) = opened.message.get_inner_message_kind().request_id else {
            return;
        };
        let waiting = {
            let mut waiting = lock(&self.waiting);
            let matches = waiting.get(&request_id).is_some_and(|w| {
                w.request.node == target.node.to_hex()
                    && w.request.solver == target.keys.public_key().to_hex()
            });
            if !matches {
                return;
            }
            waiting.remove(&request_id)
        };
        let Some(waiting) = waiting else {
            return;
        };
        let result = match &waiting.request.purpose {
            Purpose::Take { status_at_send } => Reply::Take(
                super::take::settle(
                    &self.feed,
                    &waiting.request,
                    *status_at_send,
                    &opened.message,
                )
                .await,
            ),
            Purpose::Resolve {
                resolution,
                order_id,
            } => Reply::Resolve(
                super::resolve::apply(
                    &self.feed,
                    &waiting.request,
                    *resolution,
                    order_id,
                    &opened.message,
                )
                .await,
            ),
        };
        if let Some(reply) = waiting.reply {
            let _ = reply.send(result);
        }
    }

    #[cfg(test)]
    pub(crate) fn waiting_len(&self) -> usize {
        lock(&self.waiting).len()
    }
}

// ── The process-wide router ───────────────────────────────────────────────────

static ROUTER: OnceLock<Arc<Router>> = OnceLock::new();

pub(crate) fn router() -> Option<Arc<Router>> {
    ROUTER.get().cloned()
}

/// Start the router on the relay pool's client, beside the dispute feed.
/// Called once the pool exists; later calls only re-point it.
pub(crate) async fn start(client: Arc<Client>, feed: Arc<Feed>) {
    let router = ROUTER.get_or_init(|| {
        let router = Router::new(client, crate::nostr::live_subs::live_subs(), feed);
        router.spawn_reader();
        router
    });
    follow_with(router).await;
}

/// Re-point the router at the active node and the loaded key, after either
/// changes. A no-op before the pool started.
pub(crate) async fn follow() {
    if let Some(router) = ROUTER.get() {
        follow_with(router).await;
    }
}

async fn follow_with(router: &Router) {
    let keys = crate::solver_slot::SOLVER_SLOT.keys().await;
    router
        .retarget(crate::config::active_mostro_pubkey(), keys)
        .await;
}

#[cfg(all(test, not(target_arch = "wasm32")))]
pub(crate) mod tests {
    use super::*;
    use crate::api::take::{SolverStatus, TakeError, TakeOutcome};
    use crate::disputes::event::tests::mostrod_event;
    use crate::disputes::feed::Store;
    use crate::mostro::take::tests::{cant_do, took, DISPUTE};
    use crate::mostro::take::{send_take, take_on, take_pow_on};
    use mostro_core::error::CantDoReason;
    use mostro_core::message::Message;
    use mostro_core::transport::{wrap_message_with, Transport, WrapOptions};
    use nostr_sdk::local_relay::MockRelay;
    use std::time::Duration;

    /// What the simulated daemon answers to a request, from its request id
    /// and the message it carried: the answers, or nothing.
    pub(crate) type Script = Arc<dyn Fn(u64, &Message) -> Vec<Message> + Send + Sync>;

    pub(crate) async fn connected(url: &nostr_sdk::prelude::RelayUrl) -> Arc<Client> {
        let client = Arc::new(Client::new());
        client.add_relay(url).await.unwrap();
        client
            .try_connect_relay(url, Duration::from_secs(3))
            .await
            .unwrap();
        client
    }

    /// The node's side as mostrod writes it (`util.rs`, `send_dm`): every
    /// kind 14 to the node is opened, and each message the script returns
    /// goes back to its author, unsigned inside, signed outside by the node.
    pub(crate) async fn daemon(relay: &MockRelay, node: Keys, script: Script) -> Arc<Client> {
        let client = connected(&relay.url().await).await;
        client
            .subscribe(
                Filter::new()
                    .kind(Kind::PrivateDirectMessage)
                    .pubkey(node.public_key()),
            )
            .await
            .unwrap();
        let mut notifications = client.notifications();
        let replier = client.clone();
        tokio::spawn(async move {
            while let Some(n) = notifications.next().await {
                let ClientNotification::Event { event, .. } = n else {
                    continue;
                };
                let Ok(Some(opened)) =
                    crate::nostr::transport::unwrap_mostro_message(&node, &event).await
                else {
                    continue;
                };
                let request_id = opened.message.get_inner_message_kind().request_id.unwrap();
                for answer in script(request_id, &opened.message) {
                    let reply = wrap_message_with(
                        Transport::Nip44Direct,
                        &answer,
                        &node,
                        &node,
                        opened.sender,
                        WrapOptions {
                            signed: false,
                            ..WrapOptions::default()
                        },
                    )
                    .await
                    .unwrap();
                    replier.send_event(&reply).await.unwrap();
                }
            }
        });
        client
    }

    pub(crate) struct Rig {
        pub node: Keys,
        pub solver: Keys,
        pub client: Arc<Client>,
        pub feed: Arc<Feed>,
        pub router: Arc<Router>,
        pub _relay: MockRelay,
        pub _daemon: Arc<Client>,
    }

    impl Rig {
        pub(crate) async fn new(status: &str, script: Script) -> Self {
            let relay = MockRelay::run().await.unwrap();
            let node = Keys::generate();
            let solver = Keys::generate();
            let daemon = daemon(&relay, node.clone(), script).await;
            let client = connected(&relay.url().await).await;
            let subs: &'static LiveSubs = Box::leak(Box::default());
            let (tx, _) = tokio::sync::broadcast::channel(16);
            let feed = Feed::new(client.clone(), Store::memory(), subs, tx);
            feed.retarget(Some(node.public_key().to_hex())).await;
            feed.ingest(&mostrod_event(&node, DISPUTE, status, 1_700_000_100))
                .await
                .expect("the dispute is stored");
            let router = Router::new(client.clone(), subs, feed.clone());
            router.spawn_reader();
            router
                .retarget(Some(node.public_key().to_hex()), Some(solver.clone()))
                .await;
            Self {
                node,
                solver,
                client,
                feed,
                router,
                _relay: relay,
                _daemon: daemon,
            }
        }

        pub(crate) fn node_hex(&self) -> String {
            self.node.public_key().to_hex()
        }

        pub(crate) fn solver_hex(&self) -> String {
            self.solver.public_key().to_hex()
        }

        async fn take(&self, wait: Duration) -> Result<TakeResult, TakeError> {
            send_take(
                &self.router,
                &self.feed,
                &self.client,
                &self.solver,
                &self.node_hex(),
                DISPUTE,
                0,
                wait,
            )
            .await
        }

        pub(crate) async fn row(&self) -> crate::disputes::DisputeRecord {
            self.feed
                .row(&self.node_hex(), DISPUTE)
                .await
                .unwrap()
                .unwrap()
        }

        pub(crate) async fn standing(&self) -> SolverStatus {
            crate::mostro::standing::read(&self.node_hex(), &self.solver_hex())
                .await
                .status
        }
    }

    pub(crate) fn answer_with(f: fn(u64) -> Message) -> Script {
        Arc::new(move |rid, _| vec![f(rid)])
    }

    pub(crate) fn silent() -> Script {
        Arc::new(|_, _| Vec::new())
    }

    pub(crate) const WAIT: Duration = Duration::from_secs(5);

    // ── Each row of the marker tables, end to end ────────────────────────

    #[tokio::test]
    async fn a_take_answered_with_admin_took_dispute_is_stored_as_mine() {
        let rig = Rig::new("initiated", answer_with(|rid| took(rid, DISPUTE))).await;

        let result = rig.take(WAIT).await.unwrap();

        assert_eq!(result.outcome, TakeOutcome::Taken);
        assert_eq!(result.mostro_pubkey, rig.node_hex());
        let row = rig.row().await;
        assert_eq!(row.status, DisputeStatus::InProgress, "off Pending at once");
        let taken = row.taken.expect("taken");
        assert_eq!(taken.solver_pubkey, rig.solver_hex());
        assert_eq!(taken.amount, Some(75_000));
        assert_eq!(rig.standing().await, SolverStatus::Yes);
        assert_eq!(rig.router.waiting_len(), 0);
    }

    #[tokio::test]
    async fn invalid_pubkey_on_a_waiting_dispute_marks_the_key_no_solver() {
        let rig = Rig::new(
            "initiated",
            answer_with(|rid| cant_do(rid, Some(CantDoReason::InvalidPubkey))),
        )
        .await;

        let result = rig.take(WAIT).await.unwrap();

        assert_eq!(result.outcome, TakeOutcome::NotSolver);
        assert_eq!(rig.row().await.taken, None);
        assert_eq!(rig.standing().await, SolverStatus::No);
    }

    #[tokio::test]
    async fn invalid_pubkey_on_a_held_dispute_cannot_take_over_and_says_nothing_of_the_key() {
        let rig = Rig::new(
            "in-progress",
            answer_with(|rid| cant_do(rid, Some(CantDoReason::InvalidPubkey))),
        )
        .await;

        let result = rig.take(WAIT).await.unwrap();

        assert_eq!(result.outcome, TakeOutcome::CannotTakeOver);
        assert_eq!(rig.row().await.taken, None);
        assert_eq!(rig.standing().await, SolverStatus::Unknown);
    }

    /// Recover a dispute: re-taking an `in-progress` dispute this key holds
    /// brings `AdminTookDispute` again, with the data that was lost.
    #[tokio::test]
    async fn recovering_my_own_dispute_brings_its_data_back() {
        let rig = Rig::new("in-progress", answer_with(|rid| took(rid, DISPUTE))).await;
        assert_eq!(rig.row().await.taken, None, "the first answer was lost");

        let result = rig.take(WAIT).await.unwrap();

        assert_eq!(result.outcome, TakeOutcome::Taken);
        let row = rig.row().await;
        assert_eq!(row.status, DisputeStatus::InProgress);
        assert_eq!(row.taken.unwrap().solver_pubkey, rig.solver_hex());
        assert_eq!(rig.standing().await, SolverStatus::Yes);
        // Permission is not learned from a take (D12).
        let learned = crate::mostro::standing::read(&rig.node_hex(), &rig.solver_hex()).await;
        assert_eq!(
            learned.permission,
            crate::api::take::SolverPermission::Unknown
        );
    }

    #[tokio::test]
    async fn another_cant_do_is_refused_with_its_reason() {
        let rig = Rig::new(
            "initiated",
            answer_with(|rid| cant_do(rid, Some(CantDoReason::NotFound))),
        )
        .await;
        let result = rig.take(WAIT).await.unwrap();
        assert_eq!(result.outcome, TakeOutcome::Refused);
        assert_eq!(result.reason.as_deref(), Some("not_found"));
        assert_eq!(rig.standing().await, SolverStatus::Unknown);
    }

    // ── Correlation ──────────────────────────────────────────────────────

    /// An answer that carries another request id is not this take's, even
    /// signed by the node and about the same dispute.
    #[tokio::test]
    async fn only_the_answer_with_the_request_id_counts() {
        let rig = Rig::new(
            "initiated",
            Arc::new(|rid, _| {
                vec![
                    took(rid.wrapping_add(1), DISPUTE),
                    cant_do(rid, Some(CantDoReason::InvalidPubkey)),
                ]
            }),
        )
        .await;

        let result = rig.take(WAIT).await.unwrap();

        assert_eq!(result.outcome, TakeOutcome::NotSolver);
        assert_eq!(rig.row().await.taken, None);
    }

    /// A kind 14 the node did not sign is dropped, whatever it says.
    #[tokio::test]
    async fn a_dm_not_signed_by_the_node_is_ignored() {
        let rig = Rig::new("initiated", silent()).await;
        let request = Request {
            node: rig.node_hex(),
            solver: rig.solver_hex(),
            dispute_id: DISPUTE.into(),
            purpose: Purpose::Take {
                status_at_send: DisputeStatus::Initiated,
            },
        };
        let mut answer = rig.router.register(42, request).unwrap();
        let impostor = Keys::generate();
        let forged = wrap_message_with(
            Transport::Nip44Direct,
            &took(42, DISPUTE),
            &impostor,
            &impostor,
            rig.solver.public_key(),
            WrapOptions::default(),
        )
        .await
        .unwrap();

        rig.router.handle(&forged).await;

        assert!(answer.try_recv().is_err(), "not delivered");
        assert_eq!(rig.router.waiting_len(), 1, "still waiting");
        assert_eq!(rig.row().await.taken, None);
        assert_eq!(rig.standing().await, SolverStatus::Unknown);
    }

    // ── No answer ────────────────────────────────────────────────────────

    /// No answer in time: the take says so and nothing is retried; when the
    /// node answers after all, the take is stored.
    #[tokio::test]
    async fn no_answer_in_time_is_no_answer_and_a_late_one_still_lands() {
        let rig = Rig::new("initiated", silent()).await;

        let result = rig.take(Duration::from_millis(300)).await.unwrap();

        assert_eq!(result.outcome, TakeOutcome::NoAnswer);
        assert_eq!(rig.row().await.taken, None);
        assert_eq!(rig.router.waiting_len(), 1, "kept for a late answer");

        // The node answers now (its own client, as mostrod would).
        let request_id = *lock(&rig.router.waiting).keys().next().unwrap();
        let late = wrap_message_with(
            Transport::Nip44Direct,
            &took(request_id, DISPUTE),
            &rig.node,
            &rig.node,
            rig.solver.public_key(),
            WrapOptions {
                signed: false,
                ..WrapOptions::default()
            },
        )
        .await
        .unwrap();
        rig._daemon.send_event(&late).await.unwrap();
        for _ in 0..100 {
            if rig.row().await.taken.is_some() {
                break;
            }
            tokio::time::sleep(Duration::from_millis(50)).await;
        }
        assert_eq!(
            rig.row().await.taken.unwrap().solver_pubkey,
            rig.solver_hex()
        );
        assert_eq!(rig.standing().await, SolverStatus::Yes);
    }

    /// The solver moved to another node before node A answered: A's late
    /// answer is not taken, for A or for the new node.
    #[tokio::test]
    async fn a_late_answer_from_another_node_is_not_applied() {
        let rig = Rig::new("initiated", silent()).await;
        let result = rig.take(Duration::from_millis(300)).await.unwrap();
        assert_eq!(result.outcome, TakeOutcome::NoAnswer);
        let request_id = *lock(&rig.router.waiting).keys().next().unwrap();

        let other_node = Keys::generate();
        rig.router
            .retarget(
                Some(other_node.public_key().to_hex()),
                Some(rig.solver.clone()),
            )
            .await;
        assert_eq!(rig.router.waiting_len(), 0, "A's requests dropped");
        let late = wrap_message_with(
            Transport::Nip44Direct,
            &took(request_id, DISPUTE),
            &rig.node,
            &rig.node,
            rig.solver.public_key(),
            WrapOptions {
                signed: false,
                ..WrapOptions::default()
            },
        )
        .await
        .unwrap();
        rig.router.handle(&late).await;

        assert_eq!(rig.row().await.taken, None);
        assert_eq!(rig.standing().await, SolverStatus::Unknown);
    }

    // ── The node's PoW ───────────────────────────────────────────────────

    /// The node's kind 38385, as mostrod publishes it, with its PoW.
    pub(crate) fn instance_info(node: &Keys, pow: u32, first_contact: u32) -> Event {
        use nostr_sdk::prelude::*;
        EventBuilder::new(Kind::Custom(38385), "")
            .tags([
                Tag::identifier(node.public_key().to_hex()),
                Tag::parse(["pow", &pow.to_string()]).unwrap(),
                Tag::parse(["pow_first_contact", &first_contact.to_string()]).unwrap(),
                Tag::parse(["protocol_version", "2"]).unwrap(),
            ])
            .finalize(node)
            .unwrap()
    }

    /// Nothing cached (the node was chosen while the relays were down): the
    /// take reads the 38385 first and mines the larger of the two.
    #[tokio::test]
    async fn without_cached_node_info_the_take_reads_it_and_mines_enough() {
        let rig = Rig::new("initiated", answer_with(|rid| took(rid, DISPUTE))).await;
        let info = instance_info(&rig.node, 2, 6);
        assert!(!rig
            ._daemon
            .send_event(&info)
            .await
            .unwrap()
            .success
            .is_empty());

        assert_eq!(take_pow_on(&rig.client, &rig.node_hex()).await, Ok(6));
        let result = take_on(
            &rig.router,
            &rig.feed,
            &rig.client,
            &rig.solver,
            &rig.node_hex(),
            DISPUTE,
            WAIT,
        )
        .await
        .unwrap();
        assert_eq!(result.outcome, TakeOutcome::Taken);
    }

    /// No info cached and none to read: the PoW the node wants is unknown,
    /// so nothing goes out (a take below it would be dropped unanswered).
    #[tokio::test]
    async fn without_any_node_info_nothing_is_sent() {
        let asked = Arc::new(std::sync::atomic::AtomicUsize::new(0));
        let counter = asked.clone();
        let rig = Rig::new(
            "initiated",
            Arc::new(move |rid, _| {
                counter.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
                vec![took(rid, DISPUTE)]
            }),
        )
        .await;

        let result = take_on(
            &rig.router,
            &rig.feed,
            &rig.client,
            &rig.solver,
            &rig.node_hex(),
            DISPUTE,
            WAIT,
        )
        .await;

        assert_eq!(result.unwrap_err(), TakeError::NodeInfoUnavailable);
        tokio::time::sleep(Duration::from_millis(300)).await;
        assert_eq!(asked.load(std::sync::atomic::Ordering::SeqCst), 0);
        assert_eq!(rig.router.waiting_len(), 0);
        assert_eq!(rig.row().await.taken, None);
    }

    // ── Guards ───────────────────────────────────────────────────────────

    #[tokio::test]
    async fn a_second_take_of_the_same_dispute_waits_for_the_first() {
        let rig = Rig::new("initiated", silent()).await;
        let request = Request {
            node: rig.node_hex(),
            solver: rig.solver_hex(),
            dispute_id: DISPUTE.into(),
            purpose: Purpose::Take {
                status_at_send: DisputeStatus::Initiated,
            },
        };
        let first = rig.router.register(1, request.clone()).unwrap();
        assert_eq!(
            rig.router.register(2, request.clone()).unwrap_err(),
            Busy
        );
        // Once the first stopped waiting (timed out), another may go.
        drop(first);
        assert!(rig.router.register(3, request).is_ok());
    }

    #[tokio::test]
    async fn a_closed_or_unknown_dispute_is_not_sent() {
        let rig = Rig::new("settled", answer_with(|rid| took(rid, DISPUTE))).await;
        assert_eq!(rig.take(WAIT).await.unwrap_err(), TakeError::NotTakeable);
        let other = send_take(
            &rig.router,
            &rig.feed,
            &rig.client,
            &rig.solver,
            &rig.node_hex(),
            "1f2e3d4c-5b6a-4978-8695-a4b3c2d1e0f9",
            0,
            WAIT,
        )
        .await;
        assert_eq!(other.unwrap_err(), TakeError::UnknownDispute);
        assert_eq!(rig.router.waiting_len(), 0);
    }

    /// Against a real mostrod and relay, by hand (not in CI): the active
    /// node's 38386 is read from the relay, the take goes out signed by the
    /// solver key, and mostrod's answer is checked against `EXPECT`.
    ///
    /// ```text
    /// BOSSTRO_E2E_RELAY=ws://localhost:7000 BOSSTRO_E2E_NODE=<hex> \
    /// BOSSTRO_E2E_SOLVER=<nsec or hex> BOSSTRO_E2E_DISPUTE=<uuid> \
    /// BOSSTRO_E2E_EXPECT=taken|not-solver|cannot-take-over \
    ///   cargo test --lib against_a_local_mostrod -- --ignored --nocapture
    /// ```
    #[tokio::test]
    #[ignore = "needs a local mostrod and relay"]
    async fn against_a_local_mostrod() {
        let env = |name: &str| std::env::var(name).unwrap_or_else(|_| panic!("{name} unset"));
        let relay = nostr_sdk::prelude::RelayUrl::parse(&env("BOSSTRO_E2E_RELAY")).unwrap();
        let node = env("BOSSTRO_E2E_NODE");
        let solver = Keys::parse(&env("BOSSTRO_E2E_SOLVER")).unwrap();
        let dispute = env("BOSSTRO_E2E_DISPUTE");
        let expect = match env("BOSSTRO_E2E_EXPECT").as_str() {
            "taken" => TakeOutcome::Taken,
            "not-solver" => TakeOutcome::NotSolver,
            "cannot-take-over" => TakeOutcome::CannotTakeOver,
            other => panic!("unknown EXPECT {other}"),
        };

        let client = connected(&relay).await;
        let subs: &'static LiveSubs = Box::leak(Box::default());
        let (tx, _) = tokio::sync::broadcast::channel(256);
        let feed = Feed::new(client.clone(), Store::memory(), subs, tx);
        feed.spawn_reader();
        feed.retarget(Some(node.clone())).await;
        let mut before = None;
        for _ in 0..100 {
            before = feed.row(&node, &dispute).await.unwrap();
            if before.is_some() {
                break;
            }
            tokio::time::sleep(Duration::from_millis(100)).await;
        }
        let before = before.expect("the node's 38386 of the dispute, from the relay");
        println!("before: {:?}", before.status);

        let router = Router::new(client.clone(), subs, feed.clone());
        router.spawn_reader();
        router
            .retarget(Some(node.clone()), Some(solver.clone()))
            .await;
        let started = std::time::Instant::now();
        let result = take_on(
            &router,
            &feed,
            &client,
            &solver,
            &node,
            &dispute,
            crate::mostro::take::ANSWER_WAIT,
        )
        .await
        .unwrap();
        println!(
            "answer in {:?}: {:?} {:?}",
            started.elapsed(),
            result.outcome,
            result.reason
        );
        assert_eq!(result.outcome, expect);

        let after = feed.row(&node, &dispute).await.unwrap().unwrap();
        if expect == TakeOutcome::Taken {
            let taken = after.taken.as_ref().expect("taken");
            assert_eq!(taken.solver_pubkey, solver.public_key().to_hex());
            println!(
                "taken: {} sats, {:?} fiat, order {:?}, method {:?}",
                taken.amount.unwrap_or_default(),
                taken.fiat_amount,
                taken.order_id,
                taken.payment_method
            );
            // mostrod republishes the dispute as in-progress.
            let mut republished = false;
            for _ in 0..50 {
                let row = feed.row(&node, &dispute).await.unwrap().unwrap();
                if row.status == DisputeStatus::InProgress && row.event_id != before.event_id {
                    republished = true;
                    break;
                }
                tokio::time::sleep(Duration::from_millis(100)).await;
            }
            assert!(republished, "the node's in-progress 38386 arrived");
            assert!(feed
                .row(&node, &dispute)
                .await
                .unwrap()
                .unwrap()
                .taken
                .is_some());
        } else {
            assert_eq!(after.taken, None);
        }
        let standing = crate::mostro::standing::read(&node, &solver.public_key().to_hex()).await;
        println!("standing: {standing:?}");
    }

    #[test]
    fn the_subscription_is_the_nodes_answers_to_this_key() {
        let (node, solver) = (Keys::generate().public_key(), Keys::generate().public_key());
        let filter = answers_filter(&node, &solver, Timestamp::from_secs(10));
        assert_eq!(filter.authors, Some([node].into_iter().collect()));
        assert_eq!(
            filter.kinds,
            Some([Kind::PrivateDirectMessage].into_iter().collect())
        );
        assert_eq!(filter.since, Some(Timestamp::from_secs(10)));
        let id = subscription_id(&node.to_hex(), &solver.to_hex());
        assert!(id.to_string().len() <= 64);
        assert_ne!(id, subscription_id(&node.to_hex(), &node.to_hex()));
    }
}
