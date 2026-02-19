# For just_audio / ExoPlayer support
-keep class com.google.android.exoplayer2.** { *; }
-keep class com.google.common.** { *; }
-keep class androidx.media3.** { *; }

# Optional: useful for debugging errors
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**
