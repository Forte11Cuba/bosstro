//! Talking to the Mostro daemon as a solver (phases 4 and 6): the requests this key
//! sends over transport v2 and the node's answers to them.
//!
//! - [`replies`] follows the active node's kind 14 answers to the loaded key
//!   and hands each to the request that asked for it.
//! - [`take`] sends `AdminTakeDispute` and applies the answer.
//! - [`resolve`] sends `AdminSettle` / `AdminCancel` and applies the answer
//!   (phase 6).
//! - [`standing`] keeps what the answers taught about this key on each node.

pub mod replies;
pub mod resolve;
pub mod standing;
pub mod take;
