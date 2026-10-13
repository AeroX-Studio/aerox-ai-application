import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}

android {
    namespace = "com.aeroxstudio.aeroxai"
    compileSdk = 37
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Official AeroX Studio Production Application Identity
        applicationId = "com.aeroxstudio.aeroxai"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyPath = keystoreProperties.getProperty("storeFile")
                ?: System.getenv("AEROX_KEYSTORE_PATH")
            val storePass = keystoreProperties.getProperty("storePassword")
                ?: System.getenv("AEROX_KEYSTORE_PASSWORD")
            val keyAl = keystoreProperties.getProperty("keyAlias")
                ?: System.getenv("AEROX_KEY_ALIAS")
            val keyPass = keystoreProperties.getProperty("keyPassword")
                ?: System.getenv("AEROX_KEY_PASSWORD")

            if (!keyPath.isNullOrEmpty() && !storePass.isNullOrEmpty() && !keyAl.isNullOrEmpty() && !keyPass.isNullOrEmpty()) {
                val resolvedFile = sequenceOf(
                    rootProject.file(keyPath),
                    file(keyPath),
                    rootProject.file("aerox-release.keystore"),
                    file("aerox-release.keystore")
                ).firstOrNull { it.exists() }

                if (resolvedFile != null) {
                    println("AeroX AI: Using production signing keystore: ${resolvedFile.absolutePath}")
                    storeFile = resolvedFile
                    storePassword = storePass
                    keyAlias = keyAl
                    keyPassword = keyPass
                } else {
                    println("WARNING AeroX AI: Keystore file not found for path: $keyPath")
                }
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            if (releaseSigning.storeFile != null && releaseSigning.storeFile!!.exists()) {
                signingConfig = releaseSigning
            } else {
                logger.warn("AeroX AI: No release keystore configured. Falling back to debug signing.")
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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
