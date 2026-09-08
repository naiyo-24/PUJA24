-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepattributes JavascriptInterface
-keepattributes *Annotation*

-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}

-optimizations !method/inlining/

-keepclasseswithmembers class * {
  public void onPayment*(...);
}

# AndroidX WorkManager and Room rules (Fixes NoSuchMethodException: androidx.work.impl.WorkDatabase_Impl.<init> [])
-keep class androidx.work.impl.** { *; }
-keep class androidx.room.** { *; }
-keep class androidx.sqlite.** { *; }
-keepclassmembers class androidx.work.impl.WorkDatabase_Impl {
    <init>();
}
