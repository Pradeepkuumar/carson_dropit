# Firebase finds its components by reflection (ComponentDiscovery) - keep their
# no-arg constructors, or Firebase.initializeApp fails in release builds with
# "FirebaseCrashlytics component is not present".
-keep class * implements com.google.firebase.components.ComponentRegistrar { public <init>(); }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Protobuf-lite (Cronet / Google Navigation) reads message fields like "flags_"
# by name at runtime - keep field names so R8 doesn't rename them.
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite { <fields>; }

# Google Navigation SDK (google_navigation_flutter) ships pre-shrunk; a second R8 pass
# breaks its map renderer (GL-Map NPE, blank map). Leave its classes untouched.
-keep class com.google.android.libraries.navigation.** { *; }
-keep class com.google.android.libraries.geo.** { *; }
-keep class com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.libraries.navigation.**
-dontwarn com.google.android.libraries.geo.**