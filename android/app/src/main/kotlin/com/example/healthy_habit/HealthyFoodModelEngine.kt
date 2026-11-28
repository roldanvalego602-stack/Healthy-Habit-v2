package com.example.healthy_habit

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.nio.FloatBuffer
import java.security.MessageDigest
import kotlin.math.exp
import kotlin.math.max

/**
 * Clasificador visual específico, 100 % en el dispositivo.
 *
 * Pesos: SekoKuva Mobile 423K, BC Bertenex Oy, Apache 2.0.
 * https://huggingface.co/bcbertenex/sekokuva-mobile-423k
 *
 * El modelo se descarga opcionalmente con TLS a almacenamiento privado.
 * JAMÁS se sube la fotografía ni se usa para acreditar XP.
 */
internal object HealthyFoodModelEngine {
    private const val modelVersion =
        "46cc9c69263010519dc471c6f5c74cfd301f25f9"
    private const val prefix =
        "https://huggingface.co/bcbertenex/sekokuva-mobile-423k/resolve/"
    private const val name = "sekokuva_mobile_classifier.onnx"
    private const val dataName = "sekokuva_mobile_classifier.onnx.data"
    private const val labelsName = "class_names.json"
    private const val dataSha256 =
        "61c5f90b82503fb1e36f9ffac8a102a2c15856b228ee4dde21654c95c8807fe8"

    private val lock = Any()
    private var session: OrtSession? = null
    private var labels: List<String>? = null

    private fun modelDir(context: Context): File =
        File(context.filesDir, "healthy_food_model_v1")

    private fun filesPresent(context: Context): Boolean {
        val dir = modelDir(context)
        return File(dir, name).length() in 40000..200000 &&
            File(dir, dataName).length() in 1000000..2000000 &&
            File(dir, labelsName).length() in 500..5000
    }

    fun status(context: Context): Map<String, Any> = mapOf(
        "installed" to filesPresent(context),
        "title" to "SekoKuva Mobile 423K",
        "version" to modelVersion,
        "license" to "Apache-2.0",
        "offline" to true,
    )

    private fun sha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val block = ByteArray(32768)
            while (true) {
                val n = input.read(block)
                if (n <= 0) break
                digest.update(block, 0, n)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    private fun download(url: String, dest: File, limit: Long) {
        var next = URL(url)
        repeat(8) {
            require(next.protocol == "https") {
                "Se requiere conexión HTTPS para descargar el modelo."
            }
            val connection = next.openConnection() as HttpURLConnection
            connection.instanceFollowRedirects = false
            connection.connectTimeout = 14000
            connection.readTimeout = 20000
            connection.setRequestProperty(
                "User-Agent", "HealthyHabit-Android-FoodModel/1"
            )
            try {
                val code = connection.responseCode
                if (code in 300..399) {
                    val location = connection.getHeaderField("Location")
                        ?: throw IllegalStateException("Redirección sin destino")
                    next = URL(next, location)
                    return@repeat
                }
                if (code != 200) {
                    throw IllegalStateException("Descarga HTTP $code")
                }
                var count = 0L
                connection.inputStream.use { source ->
                    dest.outputStream().use { out ->
                        val bytes = ByteArray(16384)
                        while (true) {
                            val n = source.read(bytes)
                            if (n <= 0) break
                            count += n
                            if (count > limit) {
                                throw IllegalStateException(
                                    "El modelo supera el tamaño permitido")
                            }
                            out.write(bytes, 0, n)
                        }
                    }
                }
                if (count == 0L) {
                    throw IllegalStateException("El modelo llegó vacío")
                }
                return
            } finally {
                connection.disconnect()
            }
        }
        throw IllegalStateException("Demasiadas redirecciones del servidor")
    }

    fun install(context: Context): Map<String, Any> = synchronized(lock) {
        if (filesPresent(context)) return status(context)
        val target = modelDir(context)
        val temp = File(context.filesDir, "healthy_food_model_pending")
        temp.deleteRecursively()
        temp.mkdirs()
        try {
            val graph = File(temp, name)
            val data = File(temp, dataName)
            val classes = File(temp, labelsName)
            download("${prefix}${modelVersion}/onnx/$name", graph, 200000L)
            download("${prefix}${modelVersion}/onnx/$dataName",
                data, 2000000L)
            download("${prefix}${modelVersion}/class_names.json",
                classes, 5000L)
            if (data.length() !in 1000000..2000000 ||
                sha256(data) != dataSha256) {
                throw IllegalStateException(
                    "Los pesos no superaron la comprobación SHA-256")
            }
            val json = classes.readText(Charsets.UTF_8)
            val names = parseLabels(json)
            if (names.size != 65 ||
                !names.any { it.lowercase() == "watermelon" }) {
                throw IllegalStateException(
                    "El vocabulario del modelo no coincide con la versión")
            }
            if (graph.length() !in 40000..200000) {
                throw IllegalStateException("El archivo ONNX es inválido")
            }
            target.deleteRecursively()
            if (!temp.renameTo(target)) {
                throw IllegalStateException(
                    "No se pudo instalar el modelo privado")
            }
            session?.close()
            session = null
            labels = null
            return status(context)
        } finally {
            temp.deleteRecursively()
        }
    }

    private fun parseLabels(raw: String): List<String> {
        val text = raw.trim()
        if (text.startsWith("[")) {
            val array = JSONArray(text)
            return (0 until array.length()).map { array.getString(it) }
        }
        val obj = JSONObject(text)
        val indexed = mutableMapOf<Int, String>()
        val keys = obj.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val index = key.toIntOrNull()
            if (index != null) {
                indexed[index] = obj.getString(key)
            } else {
                val indexValue = obj.optInt(key, -1)
                if (indexValue >= 0) indexed[indexValue] = key
            }
        }
        return (0 until indexed.size).map { i ->
            indexed[i] ?: throw IllegalStateException(
                "Clases desordenadas en el modelo")
        }
    }

    private fun ensureSession(context: Context): Pair<OrtSession, List<String>> {
        if (!filesPresent(context)) {
            throw IllegalStateException(
                "Primero instala el modelo local de alimentos.")
        }
        if (session == null) {
            val env = OrtEnvironment.getEnvironment()
            val options = OrtSession.SessionOptions()
            options.setIntraOpNumThreads(2)
            session = env.createSession(
                File(modelDir(context), name).absolutePath, options)
            options.close()
            labels = parseLabels(
                File(modelDir(context), labelsName).readText(Charsets.UTF_8))
        }
        return session!! to labels!!
    }

    private fun preprocess(bytes: ByteArray): FloatArray {
        require(bytes.size in 12..(250 * 1024)) {
            "La fotografía debe ser JPEG de hasta 250 KB."
        }
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            ?: throw IllegalArgumentException("Fotografía inválida")
        // Coincide con Resize(256) + CenterCrop(224) del model card.
        val short = minOf(bitmap.width, bitmap.height)
        require(short > 0) { "Fotografía sin dimensiones válidas" }
        val scale = 256.0 / short
        val width = max(224, (bitmap.width * scale).toInt())
        val height = max(224, (bitmap.height * scale).toInt())
        val resized = Bitmap.createScaledBitmap(bitmap, width, height, true)
        if (resized !== bitmap) bitmap.recycle()
        val cropped = Bitmap.createBitmap(resized,
            (width - 224) / 2, (height - 224) / 2, 224, 224)
        if (cropped !== resized) resized.recycle()
        val pixels = IntArray(224 * 224)
        cropped.getPixels(pixels, 0, 224, 0, 0, 224, 224)
        cropped.recycle()
        val array = FloatArray(3 * 224 * 224)
        val mean = floatArrayOf(.485f, .456f, .406f)
        val std = floatArrayOf(.229f, .224f, .225f)
        for (i in pixels.indices) {
            val color = pixels[i]
            array[i] = ((Color.red(color) / 255.0f) - mean[0]) / std[0]
            array[224 * 224 + i] =
                ((Color.green(color) / 255.0f) - mean[1]) / std[1]
            array[2 * 224 * 224 + i] =
                ((Color.blue(color) / 255.0f) - mean[2]) / std[2]
        }
        return array
    }

    fun classify(context: Context, photo: ByteArray): Map<String, Any> =
        synchronized(lock) {
            val (loaded, names) = ensureSession(context)
            val env = OrtEnvironment.getEnvironment()
            val tensor = OnnxTensor.createTensor(
                env, FloatBuffer.wrap(preprocess(photo)),
                longArrayOf(1, 3, 224, 224))
            tensor.use { input ->
                val inputName = loaded.inputNames.first()
                loaded.run(mapOf(inputName to input)).use { outputs ->
                    val value = outputs[0].value
                    val logits = when (value) {
                        is Array<*> -> value.firstOrNull() as? FloatArray
                        is FloatArray -> value
                        else -> null
                    } ?: throw IllegalStateException(
                        "Salida del clasificador desconocida")
                    if (logits.size != names.size) {
                        throw IllegalStateException(
                            "Modelo y categorías incompatibles")
                    }
                    val maxValue = logits.maxOrNull() ?: 0f
                    val exponential = logits.map {
                        exp((it - maxValue).toDouble())
                    }
                    val total = exponential.sum()
                    val best = exponential.indices
                        .sortedByDescending { exponential[it] }
                        .take(5)
                    return mapOf(
                        "installed" to true,
                        "model" to "SekoKuva Mobile 423K",
                        "labels" to best.map { index ->
                            mapOf("name" to names[index],
                                "score" to exponential[index] / total)
                        },
                    )
                }
            }
        }
}
