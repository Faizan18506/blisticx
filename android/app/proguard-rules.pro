# uCrop (image_cropper) rules
-keep class com.yalantis.ucrop** { *; }
-keep interface com.yalantis.ucrop** { *; }
-dontwarn com.yalantis.ucrop**

# OkHttp3 / Okio (dependencies of uCrop)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
