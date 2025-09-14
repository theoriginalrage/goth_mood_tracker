plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // This is required so the `flutter { ... }` block works:
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.goth_mood_tracker" // <-- change to your package if different
    compileSdk = flutter.compileSdkVersion.toInt()
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.goth_mood_tracker" // <-- match your manifest/package
        minSdk = flutter.minSdkVersion.toInt()
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use your real keystore when you’re ready to sign
            isMinifyEnabled = false
            // If you have a proguard file, keep this; otherwise remove the line
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // temp signing config for local builds; remove once you set release signing
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Java/Kotlin toolchains — AGP 8 expects 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    // ✅ This is the Kotlin DSL version of what you tried to add
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    // (optional) common packaging exclude to avoid META-INF clashes
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

// This comes from the Flutter Gradle plugin above
flutter {
    source = "../.."
}

