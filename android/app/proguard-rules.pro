# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep all Flutter-related classes
-keep class io.flutter.** { *; }
-keep class androidx.** { *; }

# Keep Retrofit classes
-keep class retrofit2.** { *; }
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# Keep Dio classes
-keep class dio.** { *; }
-keep class com.getcapacitor.** { *; }

# Keep your model classes - replace with your actual package name
-keep class com.example.mouser.** { *; }

# CRITICAL: Keep all file transfer model classes with their exact structure
-keep class * extends java.lang.Object {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep JSON annotation classes
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# IMPORTANT: Keep json_annotation generated classes
-keep class **$*.g.dart { *; }
-keep class *.g.dart { *; }

# Keep annotation classes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep generic signature of Call, Response (R8 full mode strips signatures from non-kept items)
-keep,allowobfuscation,allowshrinking interface retrofit2.Call
-keep,allowobfuscation,allowshrinking class retrofit2.Response

# Keep coroutines
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

# Keep file picker related classes
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Keep HTTP client classes
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# CRITICAL: Keep all data model classes for JSON serialization/deserialization
# This prevents field names from being obfuscated
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
    @com.google.gson.annotations.Expose <fields>;
}

# Keep all classes with JsonSerializable annotation
-keep @com.google.gson.annotations.JsonAdapter class * { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Google Play Core library classes (for deferred components / dynamic delivery)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# IMPORTANT: Keep all reflection-based classes
-keepclassmembers class * {
    @java.lang.reflect.* <fields>;
    @java.lang.reflect.* <methods>;
}

# Keep BLoC classes
-keep class * extends **Cubit { *; }
-keep class * extends **Bloc { *; }
-keep class **State { *; }
-keep class **Event { *; }

# Remove logging in release (but keep error logs)
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Keep crash reporting
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ADDITIONAL: Disable aggressive optimizations that might break Flutter
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-allowaccessmodification
-dontpreverify