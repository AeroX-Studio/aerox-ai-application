# AeroX AI ProGuard / R8 Optimization and Shrinking Rules
# Preserves Flutter embedding, native JNI bridges, and plugin registrants

# Flutter Embedding and Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn dev.flutter.**

# AeroX AI Application Entry
-keep class com.aeroxstudio.aeroxai.** { *; }

# Preserve annotations and type signatures for serialization & reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions
-keepattributes SourceFile,LineNumberTable

# Preserve native JNI methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve GeneratedPluginRegistrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Suppress known harmless warnings from third-party plugins
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**

# Google Play Services & Google Sign-In SDK
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.gms.**

# AndroidX Credentials Manager (Used by Google Sign-In modern flow)
-keep class androidx.credentials.** { *; }
-dontwarn androidx.credentials.**

# WebRTC / flutter_webrtc Native JNI & Audio Bridges
-keep class com.cloudwebrtc.webrtc.** { *; }
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**
-dontwarn com.cloudwebrtc.webrtc.**
