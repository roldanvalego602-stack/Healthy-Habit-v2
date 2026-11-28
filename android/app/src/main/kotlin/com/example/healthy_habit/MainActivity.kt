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
        // Motor de alimentos independiente del audio y de Firebase.
        // La foto nunca sale del teléfono: solo se descargan pesos del
        // modelo mediante una acción explícita del usuario.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "healthy_habit/food_model")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> {
                        result.success(
                            HealthyFoodModelEngine.status(applicationContext))
                    }
                    "install", "classify" -> {
                        val jpeg = call.argument<ByteArray>("jpeg")
                        if (call.method == "classify" &&
                            (jpeg == null || jpeg.isEmpty())) {
                            result.error("invalid-argument",
                                "Fotografía JPEG vacía", null)
                        } else {
                            Thread {
                                try {
                                    val answer = if (call.method == "install")
                                        HealthyFoodModelEngine.install(
                                            applicationContext)
                                    else HealthyFoodModelEngine.classify(
                                        applicationContext, jpeg!!)
                                    runOnUiThread { result.success(answer) }
                                } catch (error: Exception) {
                                    Log.w("HealthyHabitFood",
                                        "Error controlado del clasificador: " +
                                            error.javaClass.simpleName)
                                    runOnUiThread {
                                        result.error("food-model",
                                            error.message ?: "Modelo no disponible",
                                            null)
                                    }
                                }
                            }.start()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
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
