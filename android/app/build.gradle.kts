plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    namespace = "com.example.goth_mood_tracker" // adjust if you’ve changed package
    compileSdk = flutter.compileSdkVersion.toInt()
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.goth_mood_tracker" // match your package
        minSdk = flutter.minSdkVersion.toInt()
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Keep it simple while stabilizing
            isMinifyEnabled = false
            isShrinkResources = false
            // Temp debug signing so release builds work locally
            signingConfig = signingConfigs.getByName("debug")
            // If you have a proguard file later, you can re-enable shrinking here
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    // Prevent Lint Metaspace blowups during release builds
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

// Avoid ART baseline profile compilation on low-RAM dev box
tasks.matching { it.name.contains("ArtProfile", ignoreCase = true) }.configureEach {
    enabled = false
}

// This comes from the Flutter Gradle plugin above
flutter {
    source = "../.."
}

