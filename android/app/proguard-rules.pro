# Flutter engine + embedding ---------------------------------------------------
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
