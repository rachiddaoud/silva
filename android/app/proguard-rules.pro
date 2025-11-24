# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Gson uses generic type information stored in a class file when working with fields. Proguard
# removes such information by default, so configure it to keep all of it.
-keepattributes Signature

# For using GSON @Expose annotation
-keepattributes *Annotation*

# Gson specific classes
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep application classes
-keep class com.example.silva.** { *; }

# Keep timezone data classes
-keep class tzdata.** { *; }
-keep class com.brightsoftwaresolutions.timezone.** { *; }
-dontwarn com.brightsoftwaresolutions.timezone.**

# Keep notification classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Keep shared preferences
-keep class androidx.preference.** { *; }

# Keep Google Fonts
-keep class dev.fluttercommunity.plus.share.** { *; }

# Ignore missing Google Play Core classes (optional dependency)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

