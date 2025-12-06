# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Gson Configuration
# prevent code shrinking for Gson
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep generic type information for Gson
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep application classes
-keep class com.rachid.silva.** { *; }

# Keep timezone data classes
-keep class tzdata.** { *; }
-keep class com.brightsoftwaresolutions.timezone.** { *; }
-dontwarn com.brightsoftwaresolutions.timezone.**

# Keep notification classes and their members
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keepnames class com.dexterous.flutterlocalnotifications.** { *; }

# Keep AndroidX Work (used by local notifications)
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Keep shared preferences
-keep class androidx.preference.** { *; }

# Keep Google Fonts
-keep class dev.fluttercommunity.plus.share.** { *; }

# Play Core
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

