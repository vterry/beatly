package com.souza.beatly

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Build
import android.os.Process
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.sin

/**
 * Motor de áudio nativo de baixa latência e timing sample-accurate para o metrônomo Beatly (ADR-002 / ADR-006).
 *
 * Utiliza [AudioTrack] no modo STREAM com buffers PCM 16-bit a 44.1kHz gerados programaticamente
 * em memória RAM. O loop de áudio é executado em uma thread dedicada de alta prioridade
 * ([Process.THREAD_PRIORITY_URGENT_AUDIO]), calculando o número exato de amostras por batimento
 * para eliminar qualquer jitter ou instabilidade rítmica.
 */
class BeatlyAudioEngine {

    companion object {
        const val SAMPLE_RATE = 44100
        private const val CHUNK_SIZE = 512
        private const val MAX_VOICES = 16
    }

    // Amostras PCM 16-bit pré-computadas na inicialização
    private val samples = HashMap<String, ShortArray>()

    // Pool de vozes para mixagem sem alocação dinâmica no loop de áudio
    private val voices = Array(MAX_VOICES) { Voice() }

    // Fila concorrente de chimes aguardando disparo
    private val pendingChimes = ArrayList<PendingChime>()

    private val lock = Object()

    @Volatile
    private var isRunning = false

    @Volatile
    private var isReleased = false

    @Volatile
    private var currentBpm = 120

    @Volatile
    private var currentSubdivision = 1

    @Volatile
    private var resetRequested = false

    private var activePattern: List<String> = listOf("forte", "normal", "fraco", "mudo")

    private var audioTrack: AudioTrack? = null
    private var audioThread: Thread? = null

    init {
        preloadSamples()
        setupAudioTrack()
        startAudioThread()
    }

    private fun preloadSamples() {
        val clickHigh = generatePcmSample(frequencyHz = 1200.0, durationSeconds = 0.035, attackSeconds = 0.002, decayExponent = 8.0)
        val clickMid = generatePcmSample(frequencyHz = 800.0, durationSeconds = 0.04, attackSeconds = 0.002, decayExponent = 7.0)
        val clickLow = generatePcmSample(frequencyHz = 440.0, durationSeconds = 0.05, attackSeconds = 0.003, decayExponent = 6.0)

        val chimeZen = generatePcmSample(frequencyHz = 528.0, durationSeconds = 0.5, attackSeconds = 0.01, decayExponent = 3.5)
        val chimeMarimba = generatePcmSample(frequencyHz = 440.0, durationSeconds = 0.35, attackSeconds = 0.005, decayExponent = 5.0)
        val chimeGong = generatePcmSample(frequencyHz = 220.0, durationSeconds = 0.6, attackSeconds = 0.015, decayExponent = 3.0)

        // Cliques
        samples["click_high"] = clickHigh
        samples["click_wood_high"] = clickHigh
        samples["forte"] = clickHigh

        samples["click_mid"] = clickMid
        samples["click_wood_mid"] = clickMid
        samples["normal"] = clickMid

        samples["click_low"] = clickLow
        samples["click_wood_low"] = clickLow
        samples["fraco"] = clickLow

        // Chimes
        samples["chime_zen"] = chimeZen
        samples["chime_tibetan_bowl"] = chimeZen
        samples["zen"] = chimeZen
        samples["zenChime"] = chimeZen

        samples["chime_marimba"] = chimeMarimba
        samples["softMarimba"] = chimeMarimba
        samples["marimba"] = chimeMarimba

        samples["chime_gong"] = chimeGong
        samples["meditativeGong"] = chimeGong
        samples["gong"] = chimeGong
    }

    private fun generatePcmSample(
        frequencyHz: Double,
        durationSeconds: Double,
        attackSeconds: Double,
        decayExponent: Double,
        peakAmplitude: Double = 1.0
    ): ShortArray {
        val numSamples = (SAMPLE_RATE * durationSeconds).toInt()
        val buffer = ShortArray(numSamples)
        val twoPi = 2.0 * PI
        for (i in 0 until numSamples) {
            val t = i.toDouble() / SAMPLE_RATE
            val progress = t / durationSeconds
            val envelope = if (t < attackSeconds) {
                t / attackSeconds
            } else {
                exp(-decayExponent * progress)
            }
            val sampleValue = sin(twoPi * frequencyHz * t) * envelope * peakAmplitude
            val sampleInt16 = (sampleValue * 32767.0).coerceIn(-32768.0, 32767.0).toInt().toShort()
            buffer[i] = sampleInt16
        }
        return buffer
    }

    private fun setupAudioTrack() {
        val minBufferSize = AudioTrack.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        val bufferSizeInBytes = maxOf(minBufferSize, CHUNK_SIZE * 4 * 2)

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()

        val audioFormat = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(SAMPLE_RATE)
            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
            .build()

        val builder = AudioTrack.Builder()
            .setAudioAttributes(audioAttributes)
            .setAudioFormat(audioFormat)
            .setBufferSizeInBytes(bufferSizeInBytes)
            .setTransferMode(AudioTrack.MODE_STREAM)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)
        }

        audioTrack = builder.build()
    }

    private fun startAudioThread() {
        val thread = Thread({
            Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
            audioLoop()
        }, "BeatlyAudioThread")
        thread.isDaemon = true
        audioThread = thread
        thread.start()
    }

    private fun audioLoop() {
        val chunkBuffer = ShortArray(CHUNK_SIZE)
        var currentSamplePosition = 0L
        var nextBeatSamplePosition = 0.0
        var currentBeatIndex = 0
        var currentSubdivisionIndex = 0

        while (!isReleased) {
            var shouldPlayTrack = false

            synchronized(lock) {
                while (!isReleased && !isRunning && pendingChimes.isEmpty() && !hasActiveVoices()) {
                    try {
                        if (audioTrack?.playState == AudioTrack.PLAYSTATE_PLAYING) {
                            audioTrack?.pause()
                            audioTrack?.flush()
                        }
                        lock.wait()
                    } catch (e: InterruptedException) {
                        if (isReleased) return
                    }
                }

                if (isReleased) return

                // Processa chimes pendentes
                while (pendingChimes.isNotEmpty()) {
                    val pending = pendingChimes.removeAt(0)
                    triggerVoice(pending.sample, pending.volume)
                }

                shouldPlayTrack = isRunning || hasActiveVoices()
            }

            if (shouldPlayTrack && audioTrack?.playState != AudioTrack.PLAYSTATE_PLAYING) {
                try {
                    audioTrack?.play()
                } catch (e: IllegalStateException) {
                    // Ignora caso track esteja sendo reinicializado
                }
            }

            val bpmSnapshot: Int
            val subdivisionSnapshot: Int
            val patternSnapshot: List<String>
            val isRunningSnapshot: Boolean

            synchronized(lock) {
                bpmSnapshot = currentBpm
                subdivisionSnapshot = currentSubdivision
                patternSnapshot = activePattern
                isRunningSnapshot = isRunning
                if (resetRequested) {
                    resetRequested = false
                    currentSamplePosition = 0L
                    nextBeatSamplePosition = 0.0
                    currentBeatIndex = 0
                    currentSubdivisionIndex = 0
                }
            }

            val samplesPerBeat = (SAMPLE_RATE.toDouble() * 60.0) / (bpmSnapshot.toDouble() * subdivisionSnapshot.toDouble())

            // Renderiza 1 chunk de áudio (CHUNK_SIZE amostras)
            for (i in 0 until CHUNK_SIZE) {
                if (isRunningSnapshot && patternSnapshot.isNotEmpty()) {
                    if (currentSamplePosition >= nextBeatSamplePosition.toLong()) {
                        // Resincronização preventiva caso a thread tenha sofrido jitter acentuado do SO:
                        if (currentSamplePosition - nextBeatSamplePosition.toLong() > (samplesPerBeat * 2).toLong()) {
                            nextBeatSamplePosition = currentSamplePosition.toDouble()
                        }
                        nextBeatSamplePosition += samplesPerBeat

                        if (currentSubdivisionIndex == 0) {
                            // Cabeça do tempo do compasso: utiliza a acentuação configurada no pulso
                            val emphasis = patternSnapshot[currentBeatIndex % patternSnapshot.size]
                            when (emphasis.lowercase()) {
                                "forte", "high", "click_high" -> {
                                    samples["click_high"]?.let { triggerVoice(it, 1.0f) }
                                }
                                "normal", "mid", "click_mid" -> {
                                    samples["click_mid"]?.let { triggerVoice(it, 0.75f) }
                                }
                                "fraco", "low", "click_low" -> {
                                    samples["click_low"]?.let { triggerVoice(it, 0.45f) }
                                }
                                "mudo", "mute", "silent" -> {
                                    // Sem emissão sonora na cabeça do tempo
                                }
                                else -> {
                                    samples["click_mid"]?.let { triggerVoice(it, 0.75f) }
                                }
                            }
                        } else {
                            // Toques intermediários da subdivisão (colcheia, tercina, semicolcheia)
                            val parentEmphasis = patternSnapshot[currentBeatIndex % patternSnapshot.size]
                            if (parentEmphasis.lowercase() !in listOf("mudo", "mute", "silent")) {
                                samples["click_low"]?.let { triggerVoice(it, 0.30f) }
                            }
                        }

                        currentSubdivisionIndex++
                        if (currentSubdivisionIndex >= subdivisionSnapshot) {
                            currentSubdivisionIndex = 0
                            currentBeatIndex = (currentBeatIndex + 1) % patternSnapshot.size
                        }
                    }
                }

                // Mixagem das vozes ativas
                var mixedSample = 0.0f
                for (v in 0 until MAX_VOICES) {
                    val voice = voices[v]
                    if (voice.active && voice.sample != null) {
                        val sampleArray = voice.sample!!
                        val sampleVal = sampleArray[voice.position].toFloat()
                        mixedSample += sampleVal * voice.volume
                        voice.position++
                        if (voice.position >= sampleArray.size) {
                            voice.active = false
                            voice.sample = null
                        }
                    }
                }

                chunkBuffer[i] = mixedSample.coerceIn(-32768.0f, 32767.0f).toInt().toShort()
                currentSamplePosition++
            }

            // Gravação no AudioTrack
            audioTrack?.let { track ->
                if (track.playState == AudioTrack.PLAYSTATE_PLAYING) {
                    val written = track.write(chunkBuffer, 0, CHUNK_SIZE)
                    if (written < 0) {
                        try {
                            setupAudioTrack()
                            audioTrack?.play()
                        } catch (e: Exception) {
                            // Previne interrupção da thread
                        }
                    }
                }
            }
        }
    }

    private fun triggerVoice(sample: ShortArray, volume: Float) {
        // Procura primeira voz livre
        for (i in 0 until MAX_VOICES) {
            val v = voices[i]
            if (!v.active) {
                v.sample = sample
                v.position = 0
                v.volume = volume
                v.active = true
                return
            }
        }
        // Se todas ativas, substitui a mais próxima de terminar
        var oldestIdx = 0
        var maxPos = -1
        for (i in 0 until MAX_VOICES) {
            val v = voices[i]
            if (v.position > maxPos) {
                maxPos = v.position
                oldestIdx = i
            }
        }
        val target = voices[oldestIdx]
        target.sample = sample
        target.position = 0
        target.volume = volume
        target.active = true
    }

    private fun hasActiveVoices(): Boolean {
        for (i in 0 until MAX_VOICES) {
            if (voices[i].active) return true
        }
        return false
    }

    /**
     * Inicia o metrônomo sample-accurate com [bpm], padrão de acentuações [pattern] e [subdivision].
     */
    fun start(bpm: Int, pattern: List<String>, subdivision: Int) {
        synchronized(lock) {
            currentBpm = bpm.coerceIn(20, 300)
            activePattern = if (pattern.isEmpty()) listOf("forte", "normal", "fraco", "mudo") else pattern
            currentSubdivision = subdivision.coerceIn(1, 4)
            isRunning = true
            resetRequested = true
            lock.notifyAll()
        }
    }

    /**
     * Atualiza o BPM em tempo real sem saltos ou cortes.
     */
    fun updateBpm(bpm: Int) {
        synchronized(lock) {
            currentBpm = bpm.coerceIn(20, 300)
            lock.notifyAll()
        }
    }

    /**
     * Atualiza o padrão e a subdivisão em tempo real.
     */
    fun updatePattern(pattern: List<String>, subdivision: Int) {
        synchronized(lock) {
            if (pattern.isNotEmpty()) {
                activePattern = pattern
            }
            currentSubdivision = subdivision.coerceIn(1, 4)
            lock.notifyAll()
        }
    }

    /**
     * Interrompe o metrônomo imediatamente e silencia o áudio.
     */
    fun stop() {
        synchronized(lock) {
            isRunning = false
            resetRequested = true
            for (i in 0 until MAX_VOICES) {
                voices[i].active = false
                voices[i].sample = null
                voices[i].position = 0
            }
            pendingChimes.clear()
            lock.notifyAll()
        }
    }

    /**
     * Dispara um chime sonoro (ex: 'chime_zen', 'chime_marimba', 'chime_gong') com volume customizado.
     * Funciona tanto com o metrônomo tocando quanto parado.
     */
    fun playChime(soundName: String, volume: Double) {
        val sample = samples[soundName]
            ?: samples["chime_zen"]
            ?: return

        val vol = volume.coerceIn(0.0, 1.0).toFloat()
        synchronized(lock) {
            pendingChimes.add(PendingChime(sample, vol))
            lock.notifyAll()
        }
    }

    /**
     * Libera permanentemente os recursos nativos de áudio e destrói o [AudioTrack].
     */
    fun release() {
        synchronized(lock) {
            isReleased = true
            isRunning = false
            lock.notifyAll()
        }

        try {
            audioThread?.join(500)
        } catch (e: InterruptedException) {
            // Ignora
        }

        try {
            audioTrack?.stop()
            audioTrack?.release()
            audioTrack = null
        } catch (e: Exception) {
            // Ignora se já finalizado
        }
    }

    private class Voice {
        var sample: ShortArray? = null
        var position: Int = 0
        var volume: Float = 1.0f
        var active: Boolean = false
    }

    private class PendingChime(
        val sample: ShortArray,
        val volume: Float
    )
}
