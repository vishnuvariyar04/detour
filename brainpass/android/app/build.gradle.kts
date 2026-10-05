import org.gradle.api.tasks.PathSensitivity
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Google services (reads android/app/google-services.json).
    id("com.google.gms.google-services")
}

// Load release signing credentials from android/key.properties (gitignored).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// PostHog runs on PostHog Cloud EU (data stored in Frankfurt). The project
// token comes from android/posthog.properties (gitignored; copy
// posthog.properties.example) or the POSTHOG_PROJECT_TOKEN environment
// variable, and reaches the app as manifest meta-data, read once by
// PostHogInit. With no token PostHog stays off: the build still runs, with
// Firebase as the only analytics.
val posthogHost = "https://eu.i.posthog.com"
val posthogProperties = Properties()
val posthogPropertiesFile = rootProject.file("posthog.properties")
if (posthogPropertiesFile.exists()) {
    posthogProperties.load(FileInputStream(posthogPropertiesFile))
}
fun posthogSetting(key: String, env: String): String =
    (posthogProperties.getProperty(key) ?: System.getenv(env) ?: "").trim()

val nupoPreview = project.hasProperty("nupoPreview")

android {
    namespace = "com.brainpass.brainpass"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications (the trial reminder) uses java.time on
        // older Android versions through library desugaring.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.nupo.kid"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 7.0+. The overlay / foreground-service / accessibility
        // plugins need a modern API floor.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["posthogHost"] = posthogHost
        manifestPlaceholders["posthogToken"] =
            if (nupoPreview) "" else posthogSetting("projectToken", "POSTHOG_PROJECT_TOKEN")
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        // `-PnupoPreview` makes a debug build that installs NEXT TO the Play
        // app (its own package, its own data) with analytics off, for checking
        // the lesson on a real phone via GatePreviewActivity.
        if (nupoPreview) getByName("debug") { applicationIdSuffix = ".preview" }
        release {
            // Use the real upload key when key.properties is present,
            // otherwise fall back to debug so `flutter run --release` still works.
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

// The preview package is not in google-services.json, so Firebase stays off.
if (nupoPreview) {
    tasks.matching { it.name.contains("GoogleServices") }.configureEach { enabled = false }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// The curriculum JSON is an INPUT to the unit tests, not just something they
// happen to read. Without this Gradle calls the test task up to date after the
// content changes, and AnswersTest reports a pass it never actually ran — the
// worst possible failure mode for a check whose whole job is to catch a wrong
// answer before a child does.
tasks.withType<Test>().configureEach {
    inputs.dir(rootProject.file("../assets/curriculum"))
        .withPropertyName("curriculum")
        .withPathSensitivity(PathSensitivity.RELATIVE)
    testLogging { showStandardStreams = true }
}

dependencies {
    // Firebase Analytics is used from KOTLIN as well as from Dart: the kid's
    // learning moment is 100% native (GuardService + LockUi), so the events
    // that measure real daily usage are logged in Analytics.kt. The Flutter
    // firebase_analytics plugin puts the SDK on the RUNTIME classpath only, so
    // the app module needs its own declaration to COMPILE against it.
    //
    // Keep this BoM in sync with the version firebase_core resolves — see
    // `FirebaseSDKVersion` in that plugin's android/gradle.properties.
    implementation(platform("com.google.firebase:firebase-bom:34.15.0"))
    implementation("com.google.firebase:firebase-analytics")

    // PostHog, alongside Firebase. posthog_flutter declares the Android SDK as
    // `implementation`, so like Firebase the app needs its own line to compile
    // Analytics.kt against it. Keep the range the plugin's own build.gradle uses.
    implementation("com.posthog:posthog-android:[3.71.0,4.0.0)")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Unit tests for the curriculum simulator. android.jar on the unit-test
    // classpath is a stub whose org.json methods all throw, so a real
    // implementation has to shadow it — Curriculum reads its content from
    // JSON, and the test would fail before running a single question without
    // this. No Android framework classes are touched by these tests.
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20250107")
}

flutter {
    source = "../.."
}
