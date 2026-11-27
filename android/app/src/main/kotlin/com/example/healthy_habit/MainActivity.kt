package com.example.healthy_habit

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Puente Flutter/Android para sonidos procedimentales originales. */
class MainActivity : FlutterActivity() {
    private val channel = "healthy_habit/retro_sounds"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        val kind = call.argument<String>("kind") ?: "tap"
                        if (kind !in HealthySoundEngine.supported) {
                            result.error("invalid-argument", "Unknown sound kind", null)
                        } else {
                            Thread {
                                HealthySoundEngine.play(kind)
                            }.start()
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
