plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.assuredgig"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: still the `flutter create` placeholder. Changing this requires
        // registering the new package name in the Firebase console and re-running
        // `flutterfire configure`, because android/app/google-services.json is
        // bound to the current value. Do it before any Play or release work.
        applicationId = "com.example.assuredgig"

        // TRD T-1, decided: API 26 (Android 8.0). Below 26, notification channels
        // and background execution limits diverge enough to cost real engineering
        // time. Pinned explicitly rather than inheriting flutter.minSdkVersion (24)
        // so a Flutter upgrade cannot silently move it.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
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
    source = "../.."
}
