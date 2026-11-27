package com.example.healthy_habit

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Healthy Habit Sound Identity v2.
 *
 * Distinct original UI soundscapes (plucked wood, glass, soft digital chirp,
 * mallet, airy shimmer, descending warning), synthesized on the device.
 * No third-party recordings or musical samples are bundled.
 */
internal object HealthySoundEngine {
    private const val RATE = 44100
    private const val TAU = 2.0 * PI

    private enum class Tone { SOFT, GLASS, WOOD, BELL, DIGITAL, AIR, BASS }

    private data class Note(
        val at: Int, val ms: Int, val hz: Double,
        val endHz: Double = hz, val volume: Double = 0.50,
        val tone: Tone = Tone.SOFT,
    )

    private val baseEvents = setOf(
        "tap", "open", "guide", "talk", "purchase", "reward",
        "achievement", "friend", "habit", "equip", "error",
    )
    val supported = baseEvents + baseEvents.map { "cosmos_$it" }

    private fun score(kind: String): List<Note> = when (kind) {
        // Quiet woody tick: navigation shouldn't overwhelm.
        "tap" -> listOf(Note(0, 52, 390.0, 340.0, .36, Tone.WOOD))

        // Double airy chime: opening educational content.
        "open" -> listOf(
            Note(0, 130, 500.0, 625.0, .40, Tone.AIR),
            Note(64, 180, 760.0, 820.0, .30, Tone.GLASS),
        )

        // Magic is distinctive: shimmering rising arpeggio with a long tail.
        "guide" -> listOf(
            Note(0, 230, 610.0, 780.0, .31, Tone.GLASS),
            Note(92, 245, 940.0, 1110.0, .29, Tone.GLASS),
            Note(200, 340, 1370.0, 1500.0, .30, Tone.BELL),
            Note(274, 280, 1910.0, 1970.0, .16, Tone.AIR),
        )

        // Companion speaking: tiny robotic two-syllable chirp.
        "talk" -> listOf(
            Note(0, 68, 430.0, 690.0, .30, Tone.DIGITAL),
            Note(78, 84, 670.0, 490.0, .28, Tone.DIGITAL),
        )

        // Purchase: satisfying cash-register wooden double click + ping.
        "purchase" -> listOf(
            Note(0, 65, 380.0, 300.0, .49, Tone.WOOD),
            Note(88, 65, 460.0, 390.0, .46, Tone.WOOD),
            Note(154, 215, 1200.0, 1320.0, .32, Tone.BELL),
        )

        // Reward: clear, short, uplifting; not a copy of a game jingle.
        "reward" -> listOf(
            Note(0, 130, 520.0, 570.0, .41, Tone.GLASS),
            Note(104, 155, 785.0, 840.0, .41, Tone.GLASS),
            Note(230, 310, 1175.0, 1240.0, .35, Tone.BELL),
        )

        // Achievement: deeper celebratory fanfare, unlike a basic reward.
        "achievement" -> listOf(
            Note(0, 140, 360.0, 440.0, .42, Tone.BASS),
            Note(120, 170, 540.0, 610.0, .39, Tone.GLASS),
            Note(253, 180, 805.0, 880.0, .36, Tone.GLASS),
            Note(390, 440, 1210.0, 1350.0, .38, Tone.BELL),
            Note(430, 385, 1815.0, 1910.0, .16, Tone.AIR),
        )

        // Social connection: two warm companion voices converging.
        "friend" -> listOf(
            Note(0, 220, 570.0, 665.0, .37, Tone.SOFT),
            Note(85, 220, 760.0, 715.0, .34, Tone.SOFT),
            Note(210, 245, 890.0, 890.0, .25, Tone.BELL),
        )

        // Habit complete: grounded success then clean upward resolution.
        "habit" -> listOf(
            Note(0, 125, 330.0, 440.0, .45, Tone.WOOD),
            Note(82, 175, 670.0, 740.0, .40, Tone.GLASS),
            Note(205, 275, 1050.0, 1155.0, .37, Tone.BELL),
        )

        // Equipment: tangible snap into place.
        "equip" -> listOf(
            Note(0, 52, 660.0, 310.0, .53, Tone.WOOD),
            Note(50, 130, 490.0, 520.0, .38, Tone.BASS),
        )

        // Error: soft low downward motion, non-punitive.
        "error" -> listOf(
            Note(0, 140, 430.0, 335.0, .33, Tone.SOFT),
            Note(132, 190, 320.0, 245.0, .30, Tone.SOFT),
        )
        else -> emptyList()
    }

    // La estética Cosmos utiliza timbres electrónicos y campanas inarmónicas:
    // no basta con alterar el pitch de los sonidos base.
    private fun cosmosScore(kind: String): List<Note> = when (kind) {
        "tap" -> listOf(Note(0, 50, 960.0, 620.0, .28, Tone.DIGITAL))
        "open" -> listOf(
            Note(0, 150, 480.0, 1000.0, .25, Tone.AIR),
            Note(75, 175, 1240.0, 1390.0, .25, Tone.GLASS))
        "guide" -> listOf(
            Note(0, 220, 880.0, 1090.0, .28, Tone.GLASS),
            Note(115, 260, 1320.0, 1600.0, .26, Tone.GLASS),
            Note(245, 360, 1940.0, 2110.0, .22, Tone.BELL))
        "talk" -> listOf(
            Note(0, 72, 730.0, 1050.0, .27, Tone.DIGITAL),
            Note(70, 86, 1180.0, 800.0, .22, Tone.DIGITAL))
        "purchase" -> listOf(
            Note(0, 95, 330.0, 490.0, .40, Tone.BASS),
            Note(78, 110, 680.0, 920.0, .30, Tone.DIGITAL),
            Note(170, 240, 1350.0, 1550.0, .27, Tone.BELL))
        "reward" -> listOf(
            Note(0, 130, 690.0, 880.0, .35, Tone.GLASS),
            Note(120, 155, 1040.0, 1240.0, .30, Tone.GLASS),
            Note(255, 290, 1640.0, 1770.0, .26, Tone.BELL))
        "achievement" -> listOf(
            Note(0, 190, 270.0, 410.0, .42, Tone.BASS),
            Note(150, 220, 680.0, 910.0, .30, Tone.GLASS),
            Note(300, 260, 1050.0, 1340.0, .29, Tone.GLASS),
            Note(445, 455, 1750.0, 1880.0, .32, Tone.BELL))
        "friend" -> listOf(
            Note(0, 175, 780.0, 925.0, .29, Tone.AIR),
            Note(90, 205, 1070.0, 1030.0, .27, Tone.GLASS),
            Note(195, 225, 1320.0, 1390.0, .24, Tone.GLASS))
        "habit" -> listOf(
            Note(0, 105, 550.0, 740.0, .34, Tone.DIGITAL),
            Note(80, 185, 910.0, 1180.0, .31, Tone.GLASS),
            Note(220, 330, 1510.0, 1690.0, .30, Tone.BELL))
        "equip" -> listOf(
            Note(0, 52, 1420.0, 470.0, .33, Tone.DIGITAL),
            Note(50, 145, 610.0, 830.0, .28, Tone.GLASS))
        "error" -> listOf(
            Note(0, 130, 560.0, 385.0, .24, Tone.DIGITAL),
            Note(123, 150, 420.0, 315.0, .22, Tone.DIGITAL))
        else -> emptyList()
    }

    /** Returns a human-readable result for the in-app diagnostic panel. */
    fun play(kind: String): String {
        val notes = if (kind.startsWith("cosmos_"))
            cosmosScore(kind.removePrefix("cosmos_")) else score(kind)
        if (notes.isEmpty()) return "Efecto desconocido: $kind"
        val durationMs = notes.maxOf { it.at + it.ms } + 35
        val count = RATE * durationMs / 1000
        val samples = DoubleArray(count)

        notes.forEach { note ->
            val begin = RATE * note.at / 1000
            val length = RATE * note.ms / 1000
            var phase = 0.0
            for (i in 0 until length) {
                val progress = i.toDouble() / max(1, length)
                val hz = note.hz + (note.endHz - note.hz) * progress
                phase += TAU * hz / RATE
                val attack = min(1.0, i / (RATE * .004))
                val release = min(1.0, (length - i) / (RATE * .025))
                val decay = when (note.tone) {
                    Tone.GLASS, Tone.BELL -> exp(-2.3 * progress)
                    Tone.WOOD -> exp(-5.2 * progress)
                    Tone.DIGITAL -> exp(-1.8 * progress)
                    Tone.AIR -> exp(-3.0 * progress)
                    Tone.BASS, Tone.SOFT -> exp(-2.1 * progress)
                }
                val base = sin(phase)
                val wave = when (note.tone) {
                    Tone.SOFT -> base + .08 * sin(2 * phase)
                    Tone.GLASS -> base + .30 * sin(2.71 * phase) +
                        .11 * sin(4.12 * phase)
                    Tone.WOOD -> .64 * base + .28 * sin(2 * phase) +
                        .10 * sin(3 * phase)
                    Tone.BELL -> base + .37 * sin(2.004 * phase) +
                        .21 * sin(3.72 * phase)
                    Tone.DIGITAL -> .55 * base + .22 * sin(2 * phase) +
                        .12 * sin(4 * phase)
                    Tone.AIR -> .48 * base + .31 * sin(1.51 * phase)
                    Tone.BASS -> base + .11 * sin(.5 * phase)
                }
                val idx = begin + i
                if (idx < count) {
                    samples[idx] += wave * note.volume *
                        attack.coerceIn(0.0, 1.0) *
                        release.coerceIn(0.0, 1.0) * decay
                }
            }
        }
        val peak = samples.maxOf { kotlin.math.abs(it) }
        val normalization = if (peak > 0.0) min(1.0, .83 / peak) else 1.0
        val pcm = ShortArray(count) { i ->
            (samples[i] * normalization * 26000.0)
                .toInt().coerceIn(-32767, 32767).toShort()
        }
        var track: AudioTrack? = null
        return try {
            val minimum = AudioTrack.getMinBufferSize(
                RATE, AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT)
            if (minimum <= 0) return "Android no admite esta configuración de audio ($minimum)"
            // MEDIA follows the multimedia volume, which users can raise for
            // the demo. SONIFICATION was inaudible on some OPPO devices.
            track = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build())
                .setAudioFormat(AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(RATE)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build())
                .setTransferMode(AudioTrack.MODE_STATIC)
                .setBufferSizeInBytes(max(minimum, pcm.size * 2))
                .build()
            if (track.state != AudioTrack.STATE_INITIALIZED) {
                "No se pudo inicializar AudioTrack"
            } else {
                val written = track.write(pcm, 0, pcm.size)
                if (written != pcm.size) {
                    "No se pudieron escribir las muestras ($written/${pcm.size})"
                } else {
                    track.play()
                    Thread.sleep(durationMs.toLong() + 85L)
                    "Reproducción enviada a Android: $kind (${durationMs} ms)"
                }
            }
        } catch (error: Exception) {
            "Error de audio: ${error.javaClass.simpleName}: ${error.message}"
        } finally {
            try { track?.release() } catch (_: Exception) {}
        }
    }
}
