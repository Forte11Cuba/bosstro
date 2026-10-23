//! Platform runtime shims.
//!
//! Only the web build needs one so far: the clock `universal-time` reads.
//! Ported from ../app's `rt.rs`; spawning and timers join it when the crate
//! first needs them on both targets.

/// Time provider for `universal-time`, which nostr 0.45 uses for every clock
/// read. On `wasm32-unknown-unknown` that crate has no default source and the
/// build fails at *link* time ("a time provider is required") until the final
/// crate defines one, so this is invisible to `cargo check` and only shows up
/// in `scripts/build-web.sh`.
#[cfg(target_arch = "wasm32")]
mod browser_clock {
    use std::sync::OnceLock;

    use universal_time::{define_time_provider, Instant, MonotonicClock, SystemTime, WallClock};

    struct BrowserClock;

    impl WallClock for BrowserClock {
        fn system_time(&self) -> SystemTime {
            let since_epoch = wasmtimer::std::SystemTime::now()
                .duration_since(wasmtimer::std::UNIX_EPOCH)
                .unwrap_or_default();
            SystemTime::from_unix_duration(since_epoch)
        }
    }

    impl MonotonicClock for BrowserClock {
        fn instant(&self) -> Instant {
            // wasmtimer exposes no raw tick count, so ticks are measured from
            // the first read; only differences between instants are meaningful.
            static ORIGIN: OnceLock<wasmtimer::std::Instant> = OnceLock::new();
            let origin = *ORIGIN.get_or_init(wasmtimer::std::Instant::now);
            Instant::from_ticks(wasmtimer::std::Instant::now().duration_since(origin))
        }
    }

    define_time_provider!(BrowserClock);
}
