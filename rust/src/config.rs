//! Compiled-in defaults for the Mostro network, from MostroP2P/app's
//! `config.rs`.
//!
//! Used on first launch, when no relay or node is stored yet. Unlike
//! MostroP2P/app, there is **no default active node**: a solver works for the
//! node that registered their key, so Bosstro waits until they pick it
//! ([`active_mostro_pubkey`] is `None` until then).

use std::sync::RwLock;

/// Relays seeded on first launch: the three the default Mostro node lists in
/// its kind 10002 relay list, as in MostroP2P/app. A node's own list is added
/// to them as soon as it is the active node (`api::relays`).
pub const DEFAULT_RELAYS: &[&str] = &[
    "wss://relay.mostro.network",
    "wss://mostro-p2p.tech",
    "wss://relay.shadowbip.com",
];

/// MostroP2P/app's default Mostro daemon. Here it is only one of the trusted
/// nodes, never selected on its own.
pub const DEFAULT_MOSTRO_PUBKEY: &str =
    "82fa8cb978b43c79b2156585bac2c011176a21d2aead6d9f7c575c005be88390";

// ── Trusted node registry ────────────────────────────────────────────────────

/// A trusted Mostro community node. Only the identity (pubkey) and region
/// label are compiled in; the name, picture and description come from the
/// node's kind 0 event (`api::nodes`).
pub struct TrustedNodeConfig {
    /// Node pubkey, 64-char lowercase hex.
    pub pubkey: &'static str,
    /// Region label: flag emoji + place name (a proper noun, not translated).
    pub region: &'static str,
}

/// Trusted Mostro communities, mirrored from MostroP2P/app's
/// `TRUSTED_MOSTRO_NODES` (itself from mostro.community). **Keep in sync** with
/// it.
pub const TRUSTED_MOSTRO_NODES: &[TrustedNodeConfig] = &[
    TrustedNodeConfig {
        pubkey: "00000235a3e904cfe1213a8a54d6f1ec1bef7cc6bfaabd6193e82931ccf1366a",
        region: "🇨🇺 Cuba",
    },
    TrustedNodeConfig {
        pubkey: "0000cc02101ec29eea9ce623258752b9d7da66c27845ed26846dd0b0fc736b40",
        region: "🇪🇸 España",
    },
    TrustedNodeConfig {
        pubkey: "00000978acc594c506976c655b6decbf2d4af25ffdaa6680f2a9568b0a88441b",
        region: "🇨🇴 Colombia",
    },
    TrustedNodeConfig {
        pubkey: "00007cb3305fb972f5cc83f83a8fbca1e64e93c9d1369880a9fd62ef95d23f91",
        region: "🇧🇴 Bolivia",
    },
    TrustedNodeConfig {
        pubkey: "000009ee1e4b1dc7add19ab30e4ef854d7b562e208b62686fd9002b50b24dabb",
        region: "🇻🇪 Venezuela",
    },
    TrustedNodeConfig {
        pubkey: "b3626fe91b602bdbca3673bec0855221f41dc8f6d0e4027e51eaa525d68d87f2",
        region: "🇦🇷 Argentina",
    },
    TrustedNodeConfig {
        pubkey: "00037abd44e7a846689e230d5446abcd0d56a344fa81fff85c09d1929feda486",
        region: "🇧🇷 Brasil",
    },
    TrustedNodeConfig {
        pubkey: "da23a31d75572138ab8149911a04224812a34bda679caba7cb1824fdf7c592ec",
        region: "🇪🇺 Europa",
    },
    TrustedNodeConfig {
        pubkey: "001bd4747d7d265edfe3bd3b7299886146ad850d51095fe77b763c32015685b9",
        region: "🇪🇨 Ecuador",
    },
    TrustedNodeConfig {
        pubkey: "00003f6be51b51a1a0cf9c94232ab1bba1f5c1bfd5a0e8687e9647558536b791",
        region: "🇲🇽 México",
    },
    TrustedNodeConfig {
        pubkey: DEFAULT_MOSTRO_PUBKEY,
        region: "🌐",
    },
];

// ── The active node (D5) ─────────────────────────────────────────────────────

static ACTIVE_MOSTRO_PUBKEY: RwLock<Option<String>> = RwLock::new(None);

/// The active node's pubkey (hex), or `None` while the solver has not chosen
/// one. Persisted by `api::nodes::select_active_node`, loaded at startup by
/// `api::nodes::rehydrate_active_node`.
pub fn active_mostro_pubkey() -> Option<String> {
    ACTIVE_MOSTRO_PUBKEY
        .read()
        .unwrap_or_else(|e| e.into_inner())
        .clone()
}

/// Set (or clear) the active node in memory. Callers persist it themselves.
pub fn set_active_mostro_pubkey(pubkey: Option<String>) {
    *ACTIVE_MOSTRO_PUBKEY
        .write()
        .unwrap_or_else(|e| e.into_inner()) = pubkey;
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The seeded relays are the ones the default node announces in its kind
    /// 10002 list, in its order (as in MostroP2P/app).
    #[test]
    fn default_relays_are_the_default_node_relay_list() {
        assert_eq!(
            DEFAULT_RELAYS,
            &[
                "wss://relay.mostro.network",
                "wss://mostro-p2p.tech",
                "wss://relay.shadowbip.com",
            ]
        );
    }

    #[test]
    fn trusted_registry_is_valid_and_unique() {
        let mut seen = std::collections::HashSet::new();
        for n in TRUSTED_MOSTRO_NODES {
            assert!(
                nostr_sdk::prelude::PublicKey::from_hex(n.pubkey).is_ok(),
                "invalid pubkey in trusted registry: {}",
                n.pubkey
            );
            assert_eq!(n.pubkey, n.pubkey.to_lowercase());
            assert!(seen.insert(n.pubkey), "duplicate pubkey: {}", n.pubkey);
        }
    }
}
