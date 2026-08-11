# Flutter/Dart kodu AOT ile ayrı derlenip native snapshot olarak paketlenir —
# R8 yalnızca bu dosyadaki Android/Kotlin/Java katmanını (plugin glue kodu,
# MainActivity) etkiler. Aşağıdaki kurallar savunma amaçlıdır; çoğu plugin
# kendi consumer-rules.pro dosyasını zaten taşır.

# Flutter engine / embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Google Mobile Ads (AdMob) + UMP
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.gms.ads.**

# Google Play Billing (in_app_purchase)
-keep class com.android.vending.billing.** { *; }
-keep class com.android.billingclient.** { *; }

# Play Core (Flutter'ın deferred-components/split-install entegrasyonu
# referans alabilir; kullanılmasa da eksik sınıf uyarısı vermesin)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
