package com.example.healthy_habit

import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.sin

/** Original, short synthesised bleeps. No recorded speech or copyrighted audio. */
class MainActivity : FlutterActivity() {
    private val channel = "healthy_habit/retro_sounds"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        val kind = call.argument<String>("kind") ?: "talk"
                        if (kind !in setOf("talk", "purchase", "reward", "achievement", "friend")) {
                            result.error("invalid-argument", "Unknown sound kind", null)
                        } else {
                            Thread { playBleeps(kind) }.start()
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun playBleeps(kind: String) {
        val rate = 22050
        val notes = when (kind) {
            "purchase" -> intArrayOf(520, 760, 1100)
            "reward" -> intArrayOf(620, 830, 1240, 1480)
            "achievement" -> intArrayOf(660, 880, 990, 1320)
            "friend" -> intArrayOf(680, 920, 680, 1020)
            else -> intArrayOf(470, 560, 490, 620, 520)
        }
        val noteMs = if (kind == "talk") 42 else 80
        val gapMs = 16
        val samplesPerNote = rate * noteMs / 1000
        val samplesGap = rate * gapMs / 1000
        val pcm = ShortArray(notes.size * (samplesPerNote + samplesGap))
        var offset = 0
        for (hz in notes) {
            for (i in 0 until samplesPerNote) {
                val t = i.toDouble() / rate
                val envelope = minOf(1.0, i / (rate * .008)) *
                    minOf(1.0, (samplesPerNote - i) / (rate * .017))
                // Gentle retro triangular-ish tone, with no melody taken from a game.
                val wave = sin(2 * PI * hz * t) + .12 * sin(4 * PI * hz * t)
                pcm[offset++] = (wave * envelope * 4700).toInt()
                    .coerceIn(-32767, 32767).toShort()
            }
            offset += samplesGap
        }
        val bytes = ByteArray(pcm.size * 2)
        for (i in pcm.indices) {
            val value = pcm[i].toInt()
            bytes[i * 2] = (value and 0xFF).toByte()
            bytes[i * 2 + 1] = ((value shr 8) and 0xFF).toByte()
        }
        var track: AudioTrack? = null
        try {
            val minBuffer = AudioTrack.getMinBufferSize(rate,
                AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
            track = AudioTrack(
                AudioManager.STREAM_MUSIC, rate, AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                maxOf(bytes.size, minBuffer.coerceAtLeast(0)),
                AudioTrack.MODE_STATIC,
            )
            if (track.state != AudioTrack.STATE_INITIALIZED) return
            if (track.write(bytes, 0, bytes.size) != bytes.size) return
            track.play()
            Thread.sleep((notes.size * (noteMs + gapMs) + 100).toLong())
        } catch (_: Exception) {
            // Sound is decorative: never interrupt the main Flutter action.
        } finally {
            try { track?.release() } catch (_: Exception) {}
        }
    }
}
