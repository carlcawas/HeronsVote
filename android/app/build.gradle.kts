import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("android/key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

fun prop(key: String): String? = keystoreProperties.getProperty(key)

fun storeFileExists(): Boolean {
    val sf = prop("storeFile")
    return sf != null && sf.isNotBlank() && rootProject.file(sf).exists()
}

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.heronsvote"
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
        applicationId = "com.example.heronsvote"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("unified") {
            val storeFileProp = prop("storeFile")
            if (storeFileProp != null && storeFileProp.isNotBlank()) {
                val resolved = rootProject.file(storeFileProp)
                if (resolved.exists()) {
                    storeFile = resolved
                }
            }
            storePassword = prop("storePassword") ?: ""
            keyAlias = prop("keyAlias") ?: ""
            keyPassword = prop("keyPassword") ?: ""
        }
    }

    buildTypes {
        getByName("debug") {
            if (storeFileExists()) {
                signingConfig = signingConfigs.getByName("unified")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }

        getByName("release") {
            if (storeFileExists()) {
                signingConfig = signingConfigs.getByName("unified")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.3.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.android.gms:play-services-auth")
}