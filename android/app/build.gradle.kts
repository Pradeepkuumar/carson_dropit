plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {

    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.dropit.carson"
        // Google Navigation SDK (google_navigation_flutter) requires API 24+.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("ketstore/carson_drop_it.jks")
            storePassword = "dropit1234"
            keyAlias = "drop-it"
            keyPassword = "dropit1234"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            isDebuggable = true
        }
    }

    namespace = "com.dropit.carson"
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

configurations.all {
    resolutionStrategy {
        // google_navigation_flutter pulls in cronet 119.6045.31, whose cronet-fallback,
        // cronet-common and cronet-api artifacts all share the "org.chromium.net" namespace.
        // AGP 9 rejects that as a namespace collision; 143.7445.0 fixed the packaging.
        force("org.chromium.net:cronet-api:143.7445.0")
        force("org.chromium.net:cronet-common:143.7445.0")
        force("org.chromium.net:cronet-fallback:143.7445.0")
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))

    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-messaging")
    coreLibraryDesugaring ("com.android.tools:desugar_jdk_libs_nio:2.1.5")

}

flutter {
    source = "../.."
}
