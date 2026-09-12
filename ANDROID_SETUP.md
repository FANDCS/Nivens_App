# Android setup — ιστορικό προβλημάτων/λύσεων

## android/settings.gradle.kts

```kotlin
pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}
include(":app")
```

## android/app/build.gradle.kts

```kotlin
android {
    defaultConfig {
        minSdk = 23  // SQLCipher απαιτεί 23+
    }
}
```

## android/gradle/wrapper/gradle-wrapper.properties

```
distributionUrl=https\://services.gradle.org/distributions/gradle-8.13-all.zip
```

## AndroidManifest.xml (permissions)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

## Προβλήματα που λύσαμε (για αναφορά)

1. **`jni` gradle error "Could not find method kotlin()"** — προερχόταν
   από AGP 9.0.1 (πολύ νέο, ασύμβατο με το `jni` που σέρνει το `record`).
   Λύση: AGP 8.11.1 / Kotlin 2.2.20 / Gradle 8.13 όπως παραπάνω.

2. **`sqlite3_flutter_libs` + `sqlcipher_flutter_libs` μαζί → R8 duplicate
   class error.** Αυτά τα δύο πακέτα είναι εναλλακτικά — ΜΟΝΟ το
   `sqlcipher_flutter_libs` πρέπει να υπάρχει στο pubspec.yaml.

3. **`record_linux` ασύμβατο με `record_platform_interface`** στο
   `record: ^5.1.2` — λύθηκε με αναβάθμιση σε `record: ^7.1.1`.

4. **`app_database.g.dart` missing** — χρειάζεται πάντα
   `dart run build_runner build` μετά από αλλαγή στο schema (πίνακες,
   `@DataClassName`, κ.λπ.)

## Βασική ροή build

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --release -d <device-id>
```
