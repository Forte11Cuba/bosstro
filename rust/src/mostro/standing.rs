//! What a solver key has learned about itself on a node (D12): whether it is
//! a solver there, and what it may do. mostrod publishes neither and has no
//! query for them; they are learned from its answers and kept per node and
//! per key, in the settings store (`settings_keys::solver_standing`), with a
//! copy in memory for a session without storage.

use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};

use anyhow::Result;

use crate::api::take::{SolverPermission, SolverStanding, SolverStatus};
use crate::db::{settings_keys, Storage};

/// What is stored under one key.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, serde::Serialize, serde::Deserialize)]
pub(crate) struct Learned {
    #[serde(default)]
    pub status: SolverStatus,
    #[serde(default)]
    pub permission: SolverPermission,
}

fn memory() -> &'static Mutex<HashMap<String, Learned>> {
    static MEMORY: OnceLock<Mutex<HashMap<String, Learned>>> = OnceLock::new();
    MEMORY.get_or_init(Default::default)
}

fn lock<T>(m: &Mutex<T>) -> std::sync::MutexGuard<'_, T> {
    m.lock().unwrap_or_else(std::sync::PoisonError::into_inner)
}

/// What `solver` (hex) knows about itself on `node` (hex).
pub(crate) async fn read(node: &str, solver: &str) -> Learned {
    let key = settings_keys::solver_standing(node, solver);
    if let Some(learned) = lock(memory()).get(&key) {
        return *learned;
    }
    let Some(db) = crate::db::app_db::db() else {
        return Learned::default();
    };
    let learned = match db.get_setting(&key).await {
        Ok(Some(json)) => serde_json::from_str(&json).unwrap_or_else(|e| {
            log::warn!("[standing] unreadable, read as unknown: {e}");
            Learned::default()
        }),
        Ok(None) => Learned::default(),
        Err(e) => {
            log::warn!("[standing] not read: {e}");
            return Learned::default();
        }
    };
    lock(memory()).insert(key, learned);
    learned
}

/// Record that `solver` is (`Yes`) or is not (`No`) a solver on `node`.
/// Its permission is kept.
pub(crate) async fn set_status(node: &str, solver: &str, status: SolverStatus) {
    let mut learned = read(node, solver).await;
    if learned.status == status {
        return;
    }
    learned.status = status;
    write(node, solver, learned).await;
}

async fn write(node: &str, solver: &str, learned: Learned) {
    let key = settings_keys::solver_standing(node, solver);
    lock(memory()).insert(key.clone(), learned);
    if let Some(db) = crate::db::app_db::db() {
        match serde_json::to_string(&learned) {
            Ok(json) => {
                if let Err(e) = db.set_setting(&key, &json).await {
                    log::warn!("[standing] not stored: {e}");
                }
            }
            Err(e) => log::warn!("[standing] not encoded: {e}"),
        }
    }
}

/// The loaded key's standing on the active node.
pub(crate) async fn active() -> Result<Option<SolverStanding>> {
    let Some(node) = crate::config::active_mostro_pubkey() else {
        return Ok(None);
    };
    let Some(keys) = crate::solver_slot::SOLVER_SLOT.keys().await else {
        return Ok(None);
    };
    let learned = read(&node, &keys.public_key().to_hex()).await;
    Ok(Some(SolverStanding {
        mostro_pubkey: node,
        status: learned.status,
        permission: learned.permission,
    }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_stored_form_is_kebab_case_and_tolerates_missing_fields() {
        let learned = Learned {
            status: SolverStatus::No,
            permission: SolverPermission::ReadWrite,
        };
        assert_eq!(
            serde_json::to_string(&learned).unwrap(),
            r#"{"status":"no","permission":"read-write"}"#
        );
        let partial: Learned = serde_json::from_str(r#"{"status":"yes"}"#).unwrap();
        assert_eq!(partial.status, SolverStatus::Yes);
        assert_eq!(partial.permission, SolverPermission::Unknown);
    }

    /// Per node and per key: what one key learned on one node says nothing
    /// about another node, or another key on the same node.
    #[tokio::test]
    async fn standing_is_kept_per_node_and_per_key() {
        let (node_a, node_b) = ("a1".repeat(32), "b2".repeat(32));
        let (me, other) = ("c3".repeat(32), "d4".repeat(32));
        set_status(&node_a, &me, SolverStatus::No).await;
        assert_eq!(read(&node_a, &me).await.status, SolverStatus::No);
        assert_eq!(read(&node_b, &me).await.status, SolverStatus::Unknown);
        assert_eq!(read(&node_a, &other).await.status, SolverStatus::Unknown);
        set_status(&node_a, &me, SolverStatus::Yes).await;
        assert_eq!(
            read(&node_a, &me).await,
            Learned {
                status: SolverStatus::Yes,
                permission: SolverPermission::Unknown,
            }
        );
    }
}
