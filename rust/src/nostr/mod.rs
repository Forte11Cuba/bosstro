//! Nostr plumbing, crate-internal: the relay pool, the long-lived
//! subscriptions and the event readers `crate::api` builds on. Ported from
//! MostroP2P/app's `rust/src/nostr/`.

pub mod blossom;
pub mod first_answer;
pub mod live_subs;
pub mod relay_list;
pub mod relay_pool;
pub mod relay_probe;
pub mod transport;
