//! Talking to the Mostro daemon as a solver (phase 4): the requests this key
//! sends over transport v2 and the node's answers to them.
//!
//! - [`replies`] follows the active node's kind 14 answers to the loaded key
//!   and hands each to the request that asked for it.
//! - [`take`] sends `AdminTakeDispute` and applies the answer.
//! - [`standing`] keeps what the answers taught about this key on each node.

pub mod replies;
pub mod standing;
pub mod take;
