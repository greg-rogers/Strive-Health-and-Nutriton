plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin must be applied last
}

android {
    namespace = "com.gregrogers.fypfitnessapp"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.gregrogers.fypfitnessapp"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug") // Use the existing debug signing config
        }
        release {
            signingConfig = signingConfigs.getByName("debug") // Keep debug signing for testing only
        }
    }
}

flutter {
    source = "../.."
}
