package com.souza.beatly

import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Atividade principal Android do aplicativo Beatly.
 *
 * Integra o motor nativo [BeatlyAudioEngine] com o Flutter via [MethodChannel]
 * ('com.beatly.app/audio') garantindo controle de [AudioManager] AudioFocus e
 * controle de tela sempre ativa ('com.beatly.app/wakelock') e execução contínua
 * em primeiro plano ('com.beatly.app/foreground_service').
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val AUDIO_CHANNEL = "com.beatly.app/audio"
        private const val WAKELOCK_CHANNEL = "com.beatly.app/wakelock"
        private const val FOREGROUND_CHANNEL = "com.beatly.app/foreground_service"
    }

    private var audioEngine: BeatlyAudioEngine? = null
    private var audioChannel: MethodChannel? = null
    private var wakelockChannel: MethodChannel? = null
    private var foregroundChannel: MethodChannel? = null

    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var allowBackgroundAudio: Boolean = true

    private val audioFocusListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                if (!allowBackgroundAudio) {
                    audioEngine?.stop()
                    runOnUiThread {
                        audioChannel?.invokeMethod("onAudioFocusLost", null)
                    }
                }
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                // Foco recuperado
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        if (audioEngine == null) {
            audioEngine = BeatlyAudioEngine()
        }

        // Canal de Áudio Nativo
        audioChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                handleAudioMethodCall(call, result)
            }
        }

        // Canal de Wakelock Nativo
        wakelockChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WAKELOCK_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                handleWakelockMethodCall(call, result)
            }
        }

        // Canal de Foreground Service Nativo
        foregroundChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOREGROUND_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                handleForegroundMethodCall(call, result)
            }
        }
    }

    private fun handleAudioMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val engine = audioEngine ?: run {
            result.error("ENGINE_UNAVAILABLE", "Audio engine is not initialized", null)
            return
        }

        when (call.method) {
            "initialize" -> {
                result.success(null)
            }

            "setAllowBackgroundAudio" -> {
                val allow = call.argument<Boolean>("allow") ?: true
                allowBackgroundAudio = allow
                result.success(null)
            }

            "start" -> {
                val bpm = call.argument<Int>("bpm") ?: 120
                val pattern = call.argument<List<String>>("pattern") ?: listOf("forte", "normal", "fraco", "mudo")
                val subdivision = call.argument<Int>("subdivision") ?: 1
                val allowBg = call.argument<Boolean>("allowBackground") ?: allowBackgroundAudio
                allowBackgroundAudio = allowBg

                val focusGranted = requestAudioFocus()
                if (focusGranted || allowBackgroundAudio) {
                    engine.start(bpm, pattern, subdivision)
                    result.success(null)
                } else {
                    result.error("AUDIO_FOCUS_FAILED", "Failed to acquire audio focus from system", null)
                }
            }

            "updateBpm" -> {
                val bpm = call.argument<Int>("bpm") ?: 120
                engine.updateBpm(bpm)
                result.success(null)
            }

            "updatePattern" -> {
                val pattern = call.argument<List<String>>("pattern") ?: emptyList()
                val subdivision = call.argument<Int>("subdivision") ?: 1
                val resetCycle = call.argument<Boolean>("resetCycle") ?: false
                engine.updatePattern(pattern, subdivision, resetCycle)
                result.success(null)
            }

            "stop" -> {
                engine.stop()
                abandonAudioFocus()
                result.success(null)
            }

            "playChime" -> {
                val soundName = call.argument<String>("soundName") ?: "chime_zen"
                val volume = call.argument<Double>("volume") ?: 0.8
                engine.playChime(soundName, volume)
                result.success(null)
            }

            "dispose" -> {
                engine.stop()
                abandonAudioFocus()
                result.success(null)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleWakelockMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enable" -> {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                result.success(null)
            }

            "disable" -> {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                result.success(null)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleForegroundMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startForeground" -> {
                val title = call.argument<String>("title") ?: "Beatly em Execução"
                val subtitle = call.argument<String>("subtitle") ?: "Treino ativo em segundo plano"
                val intent = Intent(this, BeatlyForegroundService::class.java).apply {
                    action = BeatlyForegroundService.ACTION_START
                    putExtra(BeatlyForegroundService.EXTRA_TITLE, title)
                    putExtra(BeatlyForegroundService.EXTRA_SUBTITLE, subtitle)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }
                result.success(null)
            }

            "stopForeground" -> {
                val intent = Intent(this, BeatlyForegroundService::class.java).apply {
                    action = BeatlyForegroundService.ACTION_STOP
                }
                startService(intent)
                result.success(null)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun requestAudioFocus(): Boolean {
        val am = audioManager ?: return false

        val focusGain = if (allowBackgroundAudio) {
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
        } else {
            AudioManager.AUDIOFOCUS_GAIN
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val playbackAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()

            val focusRequest = AudioFocusRequest.Builder(focusGain)
                .setAudioAttributes(playbackAttributes)
                .setAcceptsDelayedFocusGain(false)
                .setOnAudioFocusChangeListener(audioFocusListener)
                .build()

            audioFocusRequest = focusRequest
            val res = am.requestAudioFocus(focusRequest)
            res == AudioManager.AUDIOFOCUS_REQUEST_GRANTED || allowBackgroundAudio
        } else {
            @Suppress("DEPRECATION")
            val res = am.requestAudioFocus(
                audioFocusListener,
                AudioManager.STREAM_MUSIC,
                focusGain
            )
            res == AudioManager.AUDIOFOCUS_REQUEST_GRANTED || allowBackgroundAudio
        }
    }

    private fun abandonAudioFocus() {
        val am = audioManager ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
            audioFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(audioFocusListener)
        }
    }

    override fun onDestroy() {
        abandonAudioFocus()
        val intent = Intent(this, BeatlyForegroundService::class.java).apply {
            action = BeatlyForegroundService.ACTION_STOP
        }
        try {
            startService(intent)
        } catch (_: Exception) {}
        audioEngine?.release()
        audioEngine = null
        super.onDestroy()
    }
}
