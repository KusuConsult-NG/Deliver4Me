# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-keep class io.flutter.plugins.firebase.auth.** { *; }
-keep class io.flutter.plugins.firebase.auth.GeneratedAndroidFirebaseAuth$PigeonUserDetails { *; }
-keep class io.flutter.plugins.firebase.auth.GeneratedAndroidFirebaseAuth$PigeonUserUserProfile { *; }
-keep class io.flutter.plugins.firebase.auth.GeneratedAndroidFirebaseAuth$PigeonMultiFactorInfo { *; }
-keep class io.flutter.plugins.firebase.auth.GeneratedAndroidFirebaseAuth$PigeonSecondFactorInfo { *; }

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.common.** { *; }

# SquareUp (OkHttp)
-keep class com.squareup.okhttp.** { *; }
-keep interface com.squareup.okhttp.** { *; }
-dontwarn com.squareup.okhttp.**

# Platform Channels
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * extends io.flutter.plugin.common.BasicMessageChannel$MessageHandler { *; }
