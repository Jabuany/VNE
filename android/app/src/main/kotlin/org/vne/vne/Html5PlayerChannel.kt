package org.vne.vne

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

internal class Html5PlayerChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "org.vne.vne/html5")
    private var owned: Html5Session? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "launch" -> {
                    val gameId = call.argument<String>("gameId")
                    val source = call.argument<String>("source")
                    val entry = call.argument<String>("entryPoint")
                    val managed = call.argument<Boolean>("managed")
                    val token = call.argument<Int>("token")
                    if (activity.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) {
                        result.error("activation_required", "El motor HTML5 requiere activación.", null)
                    } else if (activity.checkSelfPermission(Manifest.permission.INTERNET) ==
                        PackageManager.PERMISSION_GRANTED
                    ) {
                        result.error("network_permission", "Usa la compilación HTML5 sin permiso de Internet.", null)
                    } else if (active != null) {
                        result.error("busy", "Ya hay una partida abierta.", null)
                    } else if (gameId == null || !gameId.matches(Regex("[0-9a-f]{32}")) ||
                        source == null || entry == null || managed == null || token == null ||
                        resourcePath(entry) == null
                    ) {
                        result.error("invalid_game", "La entrada del juego no es válida.", null)
                    } else {
                        val session = Html5Session(
                            token, gameId, Uri.parse(source), entry, managed,
                            call.argument<Boolean>("fullscreen") == true, result, channel,
                        ) {
                            owned = null
                            active = null
                        }
                        owned = session
                        active = session
                        try {
                            activity.startActivity(Intent(activity, Html5PlayerActivity::class.java))
                        } catch (_: RuntimeException) {
                            session.fail("start_failed", "No se pudo abrir el reproductor.")
                            session.closed()
                        }
                    }
                }
                "pause", "resume" -> {
                    owned?.takeIf { it.token == call.argument<Int>("token") }
                        ?.view?.setUserPaused(call.method == "pause")
                    result.success(null)
                }
                "close" -> {
                    owned?.takeIf { it.token == call.argument<Int>("token") }?.requestClose()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun close() {
        owned?.requestClose()
        channel.setMethodCallHandler(null)
    }

    companion object {
        var active: Html5Session? = null
            private set
    }
}

internal class Html5Session(
    val token: Int,
    val gameId: String,
    val source: Uri,
    val entryPoint: String,
    val managed: Boolean,
    val fullscreen: Boolean,
    private var launchResult: MethodChannel.Result?,
    private val channel: MethodChannel,
    private val release: () -> Unit,
) {
    var view: Html5PlayerActivity? = null
    var closing = false
        private set
    val starting: Boolean get() = launchResult != null

    fun ready() {
        launchResult?.success(null)
        launchResult = null
    }

    fun diagnostic(code: String, message: String, error: Boolean = false) {
        channel.invokeMethod(
            "diagnostic", mapOf("token" to token, "code" to code, "message" to message, "error" to error),
        )
    }

    fun fail(code: String, message: String) {
        if (starting) {
            launchResult?.error(code, message, null)
            launchResult = null
        } else {
            diagnostic(code, message, error = true)
        }
    }

    fun requestClose() {
        closing = true
        view?.finish()
    }

    fun closed() {
        launchResult?.error("closed", "El reproductor se cerró antes de cargar el juego.", null)
        launchResult = null
        view = null
        release()
        channel.invokeMethod("closed", mapOf("token" to token))
    }
}
