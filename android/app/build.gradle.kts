import java.io.FileInputStream
import java.util.Properties

// La beta distribuida requiere una clave propia fuera del repositorio.
// Nunca firmar un release con la clave de depuración.
val releaseKeysFile = rootProject.file("key.properties")
val releaseKeys = Properties()
if (releaseKeysFile.exists()) {
    FileInputStream(releaseKeysFile).use { releaseKeys.load(it) }
}
val requiredReleaseKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val hasReleaseSigning = releaseKeysFile.exists() &&
    requiredReleaseKeys.all { !releaseKeys.getProperty(it).isNullOrBlank() }
val buildingRelease = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (buildingRelease && !hasReleaseSigning) {
    throw GradleException(
        "Release bloqueado: configura android/key.properties y una clave " +
            "de firma propia. No se permite usar la firma debug para la beta."
    )
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.healthy_habit"
    compileSdk = 36
    // speech_to_text y plugins nativos recientes requieren NDK 28.2.
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.healthy_habit"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = releaseKeys.getProperty("keyAlias")
                keyPassword = releaseKeys.getProperty("keyPassword")
                storeFile = file(releaseKeys.getProperty("storeFile"))
                storePassword = releaseKeys.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Al compilar --release, el chequeo superior exige credenciales.
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Clasificador opcional de frutas; no transmite imágenes a Internet.
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.22.0")
}

flutter {
    source = "../.."
}
