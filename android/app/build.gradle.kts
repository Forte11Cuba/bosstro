import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. `android/key.properties` is never committed. Without it a release
// build falls back to the debug key so that `flutter run --release` keeps working — an
// APK signed that way must never be published: Android refuses to update an app whose
// signing certificate changed.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    // A present but incomplete file must not fall through to the debug key, nor hand
    // Gradle a null: name what is missing and stop.
    val missing = listOf("storeFile", "storePassword", "keyPassword", "keyAlias")
        .filter { keystoreProperties.getProperty(it).isNullOrBlank() }
    check(missing.isEmpty()) {
        "android/key.properties is missing: ${missing.joinToString()}"
    }
}

android {
    // Must differ from MostroP2P/app's `foundation.mostro.app`, or installing one replaces the other.
    namespace = "foundation.mostro.bosstro"
    compileSdk = flutter.compileSdkVersion
    // Pinned (same as MostroP2P/app) for reproducible Rust cross-compilation builds.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "foundation.mostro.bosstro"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // `flutter build apk --split-per-abi` configures `splits.abi` from
        // --target-platform, and AGP rejects ndk.abiFilters next to it. The filter is
        // only needed for a fat APK.
        if (project.findProperty("split-per-abi")?.toString() != "true") {
            ndk {
                // ABI targets for flutter_rust_bridge Rust cross-compilation
                abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
            }
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (hasReleaseKeystore) "release" else "debug"
            )
        }
    }

    packaging {
        jniLibs {
            // Preserve 16 KB page alignment in packaged .so files (Android 15+ requirement)
            useLegacyPackaging = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
