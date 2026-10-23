//! The bridge surface: flutter_rust_bridge scans only `crate::api`
//! (`rust_input` in `flutter_rust_bridge.yaml`). Any change here, even to a
//! private item, needs `./scripts/frb-generate.sh`.

pub mod solver;

/// The crate version, which is also the app version (`pubspec.yaml` without
/// the `+build` suffix). Settings shows it; it is the phase 0 proof that Dart
/// reaches Rust through the bridge.
#[flutter_rust_bridge::frb(sync)]
pub fn app_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

/// Runs once when Dart calls `RustLib.init()`. An `frb(init)` function
/// outside `crate::api` is silently left out of the generated initializers.
#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The pubspec version, without the `+build` suffix.
    ///
    /// `include_str!` resolves against this source file, so the assertion
    /// holds whatever directory the test runs from.
    fn pubspec_version() -> String {
        let pubspec = include_str!("../../../pubspec.yaml");
        let line = pubspec
            .lines()
            .find(|l| l.starts_with("version:"))
            .expect("pubspec.yaml has no top-level `version:` line");
        line.trim_start_matches("version:")
            .trim()
            .split('+')
            .next()
            .unwrap()
            .to_string()
    }

    /// The crate version and the shipped app version live in two files that
    /// nothing else keeps in step; this notices when one moves alone.
    #[test]
    fn app_version_matches_pubspec() {
        assert_eq!(
            app_version(),
            pubspec_version(),
            "rust/Cargo.toml `version` and pubspec.yaml `version` have drifted; \
             bump both in the same commit"
        );
    }

    #[test]
    fn app_version_carries_no_build_number() {
        assert!(!app_version().contains('+'));
    }
}
