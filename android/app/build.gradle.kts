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
    namespace         "com.example.lumina_reminders"
    compileSdk        flutter.compileSdkVersion
    ndkVersion        flutter.ndkVersion

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

    defaultConfig {
        applicationId  "com.example.lumina_reminders"
        minSdk          flutter.minSdkVersion
        targetSdk       flutter.targetSdkVersion
        versionCode     flutter.versionCode
        versionName     flutter.versionName

        // Required for flutter_local_notifications scheduled notifications
        multiDexEnabled true
    }

    // ── Signing ──────────────────────────────────────────────────────────────
    signingConfigs {
        release {
            if (keyPropertiesFile.exists()) {
                // Path is relative to android/app/ where the JKS is placed by CI
                storeFile     file(keyProperties['storeFile'])
                storePassword keyProperties['storePassword']
                keyAlias      keyProperties['keyAlias']
                keyPassword   keyProperties['keyPassword']
            }
        }
    }

    buildTypes {
        debug {
            // Debug builds are auto-signed with the debug keystore
            applicationIdSuffix ".debug"
            versionNameSuffix   "-debug"
        }
        release {
            signingConfig     signingConfigs.release
            minifyEnabled     true
            shrinkResources   true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                          'proguard-rules.pro'
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    // Required for minSdk < 21 multidex support
    implementation 'androidx.multidex:multidex:2.0.1'
}
