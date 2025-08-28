plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mouser.app"  // Changed to match MainActivity.kt
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
        applicationId = "com.mouser.app"  // Changed to match MainActivity.kt
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
            signingConfig = signingConfigs.getByName("debug")
        }
        
        getByName("release") {
            // CRITICAL CHANGES FOR FILE TRANSFER TO WORK
            isMinifyEnabled = true  // Enable minification
            isShrinkResources = true  // Enable resource shrinking
            isDebuggable = false
            
            // Add ProGuard files
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            signingConfig = signingConfigs.getByName("debug")
            
            // IMPORTANT: Keep debug info for network debugging
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
        
        // Configure the existing profile build type
        getByName("profile") {
            isMinifyEnabled = true
            isShrinkResources = false  // Disable for easier debugging
            isDebuggable = true  // Enable debugging
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            signingConfig = signingConfigs.getByName("debug")
            
            // Enable debugging symbols
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }

    // ADD: Packaging options to prevent conflicts
    packagingOptions {
        resources {
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt"
            )
        }
    }
}

flutter {
    source = "../.."
}