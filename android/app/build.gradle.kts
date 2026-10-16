// android/app/build.gradle.kts

import java.io.File
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Read key.properties from project root: E:/SERV/gcare/key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("../key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    println("key.properties found at: ${keystorePropertiesFile.absolutePath}")
} else {
    println("Warning: key.properties not found at: ${keystorePropertiesFile.absolutePath}")
}

// The release signingConfig block below is evaluated eagerly for every build.
// Only fail for a missing key.properties when a release build is requested,
// so debug builds work on machines without the release keystore.
val releaseRequested =
    gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }

android {
    namespace = "com.serv.serv_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.serv.serv_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storePassword = keystoreProperties.getProperty("storePassword")

                val storeFileValue = keystoreProperties.getProperty("storeFile")

                if (storeFileValue.isNullOrBlank()) {
                    throw GradleException("storeFile is missing in key.properties")
                }

                val resolvedStoreFile = File(storeFileValue)

                storeFile = if (resolvedStoreFile.isAbsolute) {
                    resolvedStoreFile
                } else {
                    rootProject.file("../$storeFileValue")
                }

                println("Using release keystore: ${storeFile?.absolutePath}")
                println("Using key alias: $keyAlias")
            } else if (releaseRequested) {
                throw GradleException("key.properties file not found. Release build cannot be signed.")
            }
        }
    }

    buildTypes {
        release {
            // IMPORTANT: Use release signing, not debug signing
            signingConfig = signingConfigs.getByName("release")

            isMinifyEnabled = false
            isShrinkResources = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    buildFeatures {
        buildConfig = true
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // Same artifact/version geolocator_android already pulls in transitively
    // (as an `implementation` dep, so not exposed to app code by default).
    // Needed only by the temporary NativeGpsDiagnostic comparison tool.
    implementation("com.google.android.gms:play-services-location:21.2.0")
}