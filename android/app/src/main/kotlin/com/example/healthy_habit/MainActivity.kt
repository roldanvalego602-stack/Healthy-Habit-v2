package com.example.healthy_habit

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Android sound engine bridge and explicit preview diagnostic. */
class MainActivity : FlutterActivity() {
    private val channel = "healthy_habit/retro_sounds"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play", "preview" -> {
                        val kind = call.argument<String>("kind") ?: "tap"
                        if (kind !in HealthySoundEngine.supported) {
                            result.error("invalid-argument", "Unknown sound kind", null)
                        } else {
                            Thread {
                                val status = HealthySoundEngine.play(kind)
                                Log.i("HealthyHabitAudio", status)
                                runOnUiThread {
                                    if (call.method == "preview") {
                                        result.success(status)
                                    } else {
                                        result.success(null)
                                    }
                                }
                            }.start()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
