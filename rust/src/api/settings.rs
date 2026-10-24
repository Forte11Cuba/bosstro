//! The app's own settings, apart from nodes and keys: the language.
//!
//! Rust keeps the choice (persistence is the core's, A4) and never reads it:
//! which strings show is Dart's (Rust does not translate). So the core knows
//! the shape of a language code, not which languages the app ships.

use anyhow::{bail, Result};

use crate::db::{settings_keys, Storage};

/// The language the solver chose for the app (`es`, `pt`, …), or `None` to
/// follow the system's. Read at startup, before the first frame. A stored
/// value that is not a language code reads as `None`.
pub async fn get_language() -> Result<Option<String>> {
    match crate::db::app_db::db() {
        Some(db) => read_language(db).await,
        None => Ok(None),
    }
}

/// Keep `code` as the app's language, or follow the system's again with
/// `None`. Without storage the choice lasts until the app stops.
///
/// **Errors**: `InvalidLanguage` (not two or three lowercase letters), or a
/// storage failure.
pub async fn set_language(code: Option<String>) -> Result<()> {
    if let Some(code) = &code {
        if !is_language_code(code) {
            bail!("InvalidLanguage");
        }
    }
    match crate::db::app_db::db() {
        Some(db) => write_language(db, code.as_deref()).await,
        None => Ok(()),
    }
}

/// An ISO 639 code as Flutter's `Locale.languageCode` holds it: two or three
/// lowercase ASCII letters, no region.
fn is_language_code(code: &str) -> bool {
    (2..=3).contains(&code.len()) && code.bytes().all(|b| b.is_ascii_lowercase())
}

async fn read_language(db: &impl Storage) -> Result<Option<String>> {
    Ok(db
        .get_setting(settings_keys::LANGUAGE)
        .await?
        .filter(|code| is_language_code(code)))
}

async fn write_language(db: &impl Storage, code: Option<&str>) -> Result<()> {
    match code {
        Some(code) => db.set_setting(settings_keys::LANGUAGE, code).await,
        None => db.delete_setting(settings_keys::LANGUAGE).await,
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;

    #[test]
    fn a_language_code_is_two_or_three_lowercase_letters() {
        for code in ["es", "en", "pt", "fil"] {
            assert!(is_language_code(code), "{code}");
        }
        for code in ["", "e", "ES", "pt-BR", "pt_BR", "espa", "e1", "ñu"] {
            assert!(!is_language_code(code), "{code}");
        }
    }

    #[tokio::test]
    async fn a_choice_is_kept_replaced_and_cleared() {
        let db = crate::db::sqlite::tests::store().await;
        assert_eq!(read_language(&db).await.unwrap(), None, "the system's");
        write_language(&db, Some("de")).await.unwrap();
        assert_eq!(read_language(&db).await.unwrap().as_deref(), Some("de"));
        write_language(&db, Some("pt")).await.unwrap();
        assert_eq!(read_language(&db).await.unwrap().as_deref(), Some("pt"));
        write_language(&db, None).await.unwrap();
        assert_eq!(read_language(&db).await.unwrap(), None, "back to the system's");
    }

    #[tokio::test]
    async fn a_stored_value_that_is_no_language_code_reads_as_the_systems() {
        let db = crate::db::sqlite::tests::store().await;
        db.set_setting(settings_keys::LANGUAGE, "pt-BR").await.unwrap();
        assert_eq!(read_language(&db).await.unwrap(), None);
    }

    #[tokio::test]
    async fn a_code_that_is_no_language_is_refused() {
        let error = set_language(Some("Español".into())).await.unwrap_err();
        assert_eq!(error.to_string(), "InvalidLanguage");
    }
}
