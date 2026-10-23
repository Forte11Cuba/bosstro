//! Nostr plumbing, crate-internal: the relay pool and the event readers
//! `crate::api` builds on. Ported from ../app's `rust/src/nostr/`.

pub mod first_answer;
pub mod relay_list;
pub mod relay_pool;
