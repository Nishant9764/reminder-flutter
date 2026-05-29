// android/app/build.gradle.kts
// ─────────────────────────────────────────────────────────────────────────────
// FIXES applied vs previous version
// ─────────────────────────────────────────────────────────────────────────────
//
//  FIX 1 — Duplicate JVM target removed.
//           Previous file had BOTH:
//             kotlinOptions { jvmTarget = "17" }   ← inside android {}
//             kotlin { compilerOptions { ... } }   ← top-level
//           Kotlin Gradle Plugin 1.8+ treats these as conflicting and throws:
//             "Conflicting JVM targets set in compilerOptions and kotlinOptions"
//           Solution: delete both blocks. Use kotlin { jvmToolchain(17) } which
//           is the single, modern, recommended way — it sets compileOptions,
//           kotlinOptions, and the Kotlin compiler target all at once.
//
//  FIX 2 — Type-safe Properties access.
//           keyProperties["storeFile"] as String  returns Any? at runtime.
//           If the key is absent, Kotlin throws NullPointerException silently.
//           Replaced with .getProperty("key") which returns String? and allows
//           safe null-check with ?: operator.
//
//  FIX 3 — minSdk hardcoded to 21.
//           flutter.minSdkVersion defaults to 16 in many Flutter configs.
//           flutter_local_notifications requires API 21+ — using the Flutter
//           default causes a Gradle manifest merger error at compile time.
//
//  FIX 4 — Consistent namespace / applicationId.
//           Previous file used "com.example.reminder".
//           flutter create lumina_reminders generates "com.example.lumina_reminders"
//           inside MainActivity.kt. A mismatch causes:
//             "Namespace 'X' is not used by any source files"
//           and a broken R class reference. Fixed to lumina_reminders.
//
//  FIX 5 — Removed unused proguardFiles line.
//           isMinifyEnabled = false means ProGuard never runs, so the
//           proguardFiles() call is dead code and confusing. Removed.
// ─────────────────────────────────────────────────────────────────────────────

import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Signing: load key.properties injected by CI (or present locally) ─────────
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.exists()) {
        keyPropertiesFile.inputStream().use { load(it) }
    }
}

android {
    // FIX 4: must match the package declared in MainActivity.kt
    namespace  = "com.example.lumina_reminders"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // FIX 1: compileOptions only — JVM target for Kotlin is set via
    //         kotlin { jvmToolchain(17) } below (single source of truth).
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // FIX 4: applicationId must match namespace above
        applicationId   = "com.example.lumina_reminders"

        // FIX 3: floor at 21 so flutter_local_notifications compiles correctly.
        //        If flutter.minSdkVersion is already ≥ 21 this is a no-op.
        minSdk          = maxOf(flutter.minSdkVersion, 21)

        targetSdk       = flutter.targetSdkVersion
        versionCode     = flutter.versionCode
        versionName     = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                // FIX 2: getProperty() returns String? — avoids Any?-cast NPE.
                //         file() is relative to android/app/ (the module dir).
                //         CI writes lumina.jks to android/app/lumina.jks ✓
                val sf = keyProperties.getProperty("storeFile")
                    ?: error("key.properties is missing 'storeFile'")
                storeFile     = file(sf)
                storePassword = keyProperties.getProperty("storePassword")
                    ?: error("key.properties is missing 'storePassword'")
                keyAlias      = keyProperties.getProperty("keyAlias")
                    ?: error("key.properties is missing 'keyAlias'")
                keyPassword   = keyProperties.getProperty("keyPassword")
                    ?: error("key.properties is missing 'keyPassword'")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            versionNameSuffix   = "-debug"
            // Debug keystore is applied automatically by Android Gradle Plugin
        }

        getByName("release") {
            // Use the release signing config when key.properties is present (CI).
            // Fall back to debug keystore for local `flutter run --release` tests.
            signingConfig = if (keyPropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // FIX 5: ProGuard disabled — safe for first production build.
            //         Enable + tune proguard-rules.pro only after confirming
            //         the app runs correctly with minification off.
            isMinifyEnabled   = false
            isShrinkResources = false
        }
    }
}

// ── FIX 1: Single JVM toolchain declaration ───────────────────────────────────
// jvmToolchain(17) replaces both compileOptions Java version AND kotlinOptions
// jvmTarget in one shot. It is the official KGP 1.8+ recommended approach and
// avoids the "conflicting JVM targets" error entirely.
kotlin {
    jvmToolchain(17)
}

flutter {
    source = "../.."
}

dependencies {
    // Multidex support for minSdk < 21 (kept even though minSdk=21 for safety)
    implementation("androidx.multidex:multidex:2.0.1")
}
