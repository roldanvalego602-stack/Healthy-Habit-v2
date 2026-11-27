package com.example.healthy_habit

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin

/**
 * Healthy Habit Sound Identity v1: efectos cortos creados por síntesis
 * procedimental. No incorpora grabaciones, librerías musicales ni melodías
 * externas. Diseño de timbre y secuencias original para esta aplicación.
 */
internal object HealthySoundEngine {
    private const val RATE = 24000
    private const val TAU = 2.0 * PI
    private data class Voice(
        val startMs: Int,
        val durationMs: Int,
        val startHz: Double,
        val endHz: Double,
        val gain: Double = 0.5,
        val brightness: Double = 0.15,
    )

    // Pequeños motivos abstractos. Los efectos son funcionales, no canciones.
    private fun voices(kind: String): List<Voice> = when (kind) {
        "tap" -> listOf(Voice(0, 38, 580.0, 750.0, 0.24, 0.06))
        "open" -> listOf(
            Voice(0, 70, 440.0, 710.0, 0.27),
            Voice(44, 100, 740.0, 900.0, 0.18, 0.10))
        "guide" -> listOf(
            Voice(0, 105, 620.0, 850.0, 0.22),
            Voice(70, 125, 820.0, 1140.0, 0.20),
            Voice(140, 180, 1040.0, 1440.0, 0.18, 0.23))
        "talk" -> listOf(
            Voice(0, 45, 440.0, 570.0, 0.19),
            Voice(54, 48, 520.0, 640.0, 0.18))
        "purchase" -> listOf(
            Voice(0, 85, 470.0, 570.0, 0.25),
            Voice(95, 110, 620.0, 810.0, 0.24),
            Voice(210, 160, 900.0, 1080.0, 0.22, 0.24))
        "reward" -> listOf(
            Voice(0, 110, 510.0, 690.0, 0.24),
            Voice(85, 130, 730.0, 930.0, 0.24),
            Voice(185, 190, 1000.0, 1290.0, 0.23, 0.22))
        "achievement" -> listOf(
            Voice(0, 110, 420.0, 600.0, 0.25),
            Voice(100, 130, 710.0, 880.0, 0.24),
            Voice(200, 155, 930.0, 1180.0, 0.22),
            Voice(310, 220, 1210.0, 1450.0, 0.19, 0.25))
        "friend" -> listOf(
            Voice(0, 100, 575.0, 710.0, 0.22),
            Voice(105, 125, 760.0, 910.0, 0.21),
            Voice(205, 160, 880.0, 1050.0, 0.20))
        "habit" -> listOf(
            Voice(0, 95, 480.0, 650.0, 0.22),
            Voice(85, 145, 760.0, 960.0, 0.22),
            Voice(180, 185, 960.0, 1280.0, 0.20))
        "equip" -> listOf(
            Voice(0, 55, 680.0, 460.0, 0.23, 0.20),
            Voice(48, 95, 480.0, 710.0, 0.17))
        "error" -> listOf(
            Voice(0, 95, 520.0, 370.0, 0.15),
            Voice(100, 135, 350.0, 280.0, 0.13))
        else -> emptyList()
    }

    val supported = setOf(
        "tap", "open", "guide", "talk", "purchase", "reward",
        "achievement", "friend", "habit", "equip", "error")

    fun play(kind: String) {
        val events = voices(kind)
        if (events.isEmpty()) return
        val totalMs = events.maxOf { it.startMs + it.durationMs } + 20
        val sampleCount = (RATE * totalMs / 1000).coerceAtLeast(1)
        val samples = DoubleArray(sampleCount)

        events.forEach { voice ->
            val count = RATE * voice.durationMs / 1000
            val start = RATE * voice.startMs / 1000
            var phase = 0.0
            for (i in 0 until count) {
                val progress = i.toDouble() / count
                // Curva suave; evítanse clics digitales de inicio y fin.
                val attack = min(1.0, i / (RATE * 0.006))
                val release = min(1.0, (count - i) / (RATE * 0.024))
                val envelope = (attack * release).coerceIn(0.0, 1.0) *
                    exp(-1.55 * progress)
                val hz = voice.startHz +
                    (voice.endHz - voice.startHz) * progress
                phase += TAU * hz / RATE
                val fundamental = sin(phase)
                val overtone = sin(2.0 * phase) * voice.brightness
                val shimmer = sin(3.03 * phase) * voice.brightness * 0.20
                val idx = start + i
                if (idx < sampleCount) {
                    samples[idx] += (fundamental + overtone + shimmer) *
                        voice.gain * envelope
                }
            }
        }

        // Limita picos para no producir sonidos agresivos.
        val pcm = ShortArray(sampleCount) { index ->
            val x = samples[index].coerceIn(-0.82, 0.82)
            (x * 14000).toInt().coerceIn(-32767, 32767).toShort()
        }

        var track: AudioTrack? = null
        try {
            val minBuffer = AudioTrack.getMinBufferSize(
                RATE, AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT)
            if (minBuffer <= 0) return
            track = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build())
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(RATE)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build())
                .setTransferMode(AudioTrack.MODE_STATIC)
                .setBufferSizeInBytes(maxOf(minBuffer, pcm.size * 2))
                .build()
            if (track.state != AudioTrack.STATE_INITIALIZED) return
            if (track.write(pcm, 0, pcm.size) != pcm.size) return
            track.play()
            Thread.sleep(totalMs.toLong() + 50)
        } catch (_: Exception) {
            // Ningún fallo de audio debe bloquear compras ni registros.
        } finally {
            try { track?.release() } catch (_: Exception) {}
        }
    }
}
