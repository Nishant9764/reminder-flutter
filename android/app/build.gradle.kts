// android/app/build.gradle.kts
// ─────────────────────────────────────────────────────────────────────────────
// Kotlin DSL version of the app-level build file.
// FIX: Original file used Groovy DSL syntax (id "...", def, new Properties())
//      inside a .kts file — those are incompatible. All declarations are now
//      valid Kotlin DSL.
// ─────────────────────────────────────────────────────────────────────────────

import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Read signing credentials from key.properties ─────────────────────────────
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "com.example.reminder"
    compileSdk = flutter.compileSdkVersion
    // Hardcoded to satisfy all plugins (flutter_local_notifications,
    // flutter_timezone, path_provider_android, shared_preferences_android).
    // These require 28.2.13676358; NDK versions are backward-compatible.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.example.reminder"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true   // required when adding multidex dependency
    }

    // ── Signing configs ───────────────────────────────────────────────────────
    signingConfigs {
        create("release") {
            // Only configure if key.properties exists (i.e. CI has injected secrets)
            if (keyPropertiesFile.exists()) {
                storeFile     = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
                keyAlias      = keyProperties["keyAlias"] as String
                keyPassword   = keyProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            versionNameSuffix   = "-debug"
            // Uses the default debug keystore automatically
        }
        getByName("release") {
            // Use release signing if key.properties is present, else fall back
            // to the debug keystore so local `flutter run --release` still works.
            signingConfig = if (keyPropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled   = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for minSdk < 21 multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}
