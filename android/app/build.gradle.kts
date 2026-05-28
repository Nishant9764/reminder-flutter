// android/app/build.gradle
// ─────────────────────────────────────────────────────────────────────────────
// Replace your existing android/app/build.gradle with this file.
// Key addition: reads key.properties for release signing so the GitHub
// Actions workflow can inject secrets without touching code.
// ─────────────────────────────────────────────────────────────────────────────

plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

// ── Read signing credentials from key.properties ─────────────────────────────
def keyPropertiesFile = rootProject.file("key.properties")
def keyProperties     = new Properties()

if (keyPropertiesFile.exists()) {
    keyPropertiesFile.withReader('UTF-8') { reader ->
        keyProperties.load(reader)
    }
}

android {
    namespace = "com.example.reminder"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.reminder"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // Debug builds are auto-signed with the debug keystore
            applicationIdSuffix ".debug"
            versionNameSuffix   "-debug"
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source '../..'
}

dependencies {
    // Required for minSdk < 21 multidex support
    implementation 'androidx.multidex:multidex:2.0.1'
}
