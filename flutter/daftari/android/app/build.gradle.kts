plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// Real release signing, read from a local, never-committed key.properties
// file — see android/key.properties.example and the Flutter README's
// "Producing a signed release build" section for how to create one. If
// that file is absent (the default state of a fresh checkout), the release
// build type below falls back to debug signing, so `flutter build apk
// --release` always succeeds even before a real keystore exists — it just
// won't be installable via the Play Store until one is added.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.daftari.daftari"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.daftari.daftari"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // No key.properties yet — sign with the debug key so the
                // build still succeeds and installs on a test device. Not
                // suitable for the Play Store; see the README before
                // publishing.
                signingConfigs.getByName("debug")
            }
            // Deliberately NOT enabling isMinifyEnabled/isShrinkResources
            // here: several plugins in this project (sqlite3_flutter_libs,
            // speech_to_text, record) use native/JNI bindings that R8 can
            // silently over-strip without exactly-right keep rules, which
            // fails at runtime on a device rather than at build time —
            // worse than the larger APK size this leaves on the table.
            // Turning this on is a real, worthwhile follow-up, but only
            // together with testing every native-backed feature (voice
            // capture, local database) on a real device against the
            // minified build specifically.
        }
    }
}

flutter {
    source = "../.."
}
