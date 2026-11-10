# Plugins that Dart calls through JNI must keep their Kotlin names, or release
# builds fail with NoSuchMethodError (seen with shared_preferences, which also
# stores the Supabase login session).
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class kotlin.coroutines.Continuation { *; }

# Google Sign-In
-keep class io.flutter.plugins.googlesignin.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }

# Kotlin runtime and coroutines used by JNI suspend calls, in case shrinking
# is turned back on.
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
