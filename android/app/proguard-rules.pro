# Flutter engine + embedding ---------------------------------------------------
# The embedding references Play Core's deferred-component classes, but this app
# does not use deferred components. R8 full mode fails on the missing classes
# unless they are explicitly ignored (canonical Flutter/R8 fix).
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.app.FlutterPlayStoreSplitApplication
-keep class io.flutter.app.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.embedding.**

# Plugins used by Bluetooth Finder Radar ---------------------------------------
-keep class com.lib.flutter_blue_plus.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }
-keep class xyz.luan.audioplayers.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.lib.flutter_blue_plus.**

# Platform channel / reflection safety ----------------------------------------
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
