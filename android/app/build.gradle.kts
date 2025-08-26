plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.nishali"
    compileSdk = 36
    ndkVersion = "27.0.12077973"  // Updated to match plugin requirements

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.nishali"
        minSdk = 26  // Updated to support tflite_flutter plugin requirements
        targetSdk = 34
        versionCode = flutter.versionCode?.toInt() ?: 1
        versionName = flutter.versionName ?: "1.0.0"
        
        // Enable multidex support
        multiDexEnabled = true
        
        // Enable View Binding
        buildFeatures {
            viewBinding = true
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.2"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-common-ktx:20.4.2")
    
    // Biometric dependencies
    implementation("androidx.biometric:biometric:1.2.0-alpha05")
    
    // AndroidX core and appcompat
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    
    // Material Components
    implementation("com.google.android.material:material:1.11.0")
    
    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
