# flutter_local_notifications reflects over its own model classes when it
# reschedules pending notifications after a reboot. GSON's own rules ship with
# the library, so only the plugin's classes are named here.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
