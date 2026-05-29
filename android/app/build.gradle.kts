// android/app/build.gradle.kts

import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.exists()) keyPropertiesFile.inputStream().use { load(it) }
}

android {
    namespace  = "com.example.reminder"
    compileSdk = flutter.compileSdkVersion

    // Plugins require NDK 28.2.13676358 minimum (flutter_local_notifications,
    // flutter_timezone, path_provider_android, shared_preferences_android).
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true  // required by flutter_local_notifications
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId   = "com.example.reminder"
        minSdk          = 21   // flutter_local_notifications requires API 21+
        targetSdk       = flutter.targetSdkVersion
        versionCode     = flutter.versionCode
        versionName     = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                storeFile     = file(keyProperties.getProperty("storeFile")
                    ?: error("key.properties missing storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                    ?: error("key.properties missing storePassword")
                keyAlias      = keyProperties.getProperty("keyAlias")
                    ?: error("key.properties missing keyAlias")
                keyPassword   = keyProperties.getProperty("keyPassword")
                    ?: error("key.properties missing keyPassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
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

// Single source of truth for JVM target — avoids "conflicting JVM targets" error.
kotlin {
    jvmToolchain(17)
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
}
