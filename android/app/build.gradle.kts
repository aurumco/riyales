plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ir.ryls"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        release {
            keyAlias System.getenv("KEY_ALIAS") ?: project.property("keyAlias")
            keyPassword System.getenv("KEY_PASSWORD") ?: project.property("keyPassword")
            storeFile file(System.getenv("STORE_FILE") ?: project.property("storeFile"))
            storePassword System.getenv("STORE_PASSWORD") ?: project.property("storePassword")
        }
    }

    defaultConfig {
        applicationId = "ir.ryls"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}

flutter {
    source = "../.."
}