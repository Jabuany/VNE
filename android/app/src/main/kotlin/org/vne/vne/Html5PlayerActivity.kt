package org.vne.vne

import android.app.Activity
import android.graphics.Color
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.webkit.GeolocationPermissions
import android.webkit.JsPromptResult
import android.webkit.JsResult
import android.webkit.PermissionRequest
import android.webkit.RenderProcessGoneDetail
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature

class Html5PlayerActivity : Activity() {
    private var session: Html5Session? = null
    private var webView: WebView? = null
    private lateinit var container: LinearLayout
    private lateinit var status: TextView
    private lateinit var pause: Button
    private lateinit var fullscreenButton: Button
    private var fullscreen = false
    private var userPaused = false
    private var foreground = false
    private var suspended = false
    private var rendererGone = false
    private var canMuteAudio = false
    private val reported = mutableSetOf<String>()
    private val main = Handler(Looper.getMainLooper())
    private val startupTimeout = Runnable {
        if (session?.starting == true) {
            abort("load_timeout", "El juego tardó demasiado en cargar.")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val active = Html5PlayerChannel.active
        if (active == null || active.view != null) {
            finish()
            return
        }
        session = active
        active.view = this
        if (active.closing) {
            finish()
            return
        }
        volumeControlStream = AudioManager.STREAM_MUSIC
        showControls()
        setFullscreen(active.fullscreen)
        try {
            val resources = Html5Resources(this, active)
            if (!WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE)) {
                abort("profile_unavailable", "El WebView del dispositivo no admite perfiles de juego separados.")
                return
            }
            if (!WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROCESS) ||
                !WebViewCompat.isMultiProcessEnabled()
            ) {
                abort("sandbox_unavailable", "El WebView no tiene activo el renderizador separado.")
                return
            }
            canMuteAudio = WebViewFeature.isFeatureSupported(WebViewFeature.MUTE_AUDIO)
            val web = WebView(this)
            webView = web
            WebViewCompat.setProfile(web, "vne-${active.gameId}")
            configure(web, resources)
            container.addView(web, LinearLayout.LayoutParams(-1, 0, 1f))
            main.postDelayed(startupTimeout, 15_000)
            web.loadUrl(resources.entryUrl)
        } catch (_: Exception) {
            abort("source_unavailable", "No se pudo abrir el juego o acceder a su carpeta.")
        }
    }

    private fun showControls() {
        container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.rgb(23, 26, 33))
            setOnApplyWindowInsetsListener { view, insets ->
                @Suppress("DEPRECATION")
                view.setPadding(
                    insets.systemWindowInsetLeft, insets.systemWindowInsetTop,
                    insets.systemWindowInsetRight, insets.systemWindowInsetBottom,
                )
                insets
            }
        }
        val controls = LinearLayout(this)
        fun button(label: String, action: () -> Unit) = Button(this).apply {
            text = label
            isAllCaps = false
            setOnClickListener { action() }
            controls.addView(this, LinearLayout.LayoutParams(0, -2, 1f))
        }
        button("Volver") { finish() }
        pause = button("Pausar") { setUserPaused(!userPaused) }.apply { isEnabled = false }
        fullscreenButton = button("Pantalla completa") { setFullscreen(!fullscreen) }
        status = TextView(this).apply {
            text = "Cargando juego…"
            setTextColor(Color.WHITE)
        }
        container.addView(controls)
        container.addView(status)
        setContentView(container)
    }

    @Suppress("DEPRECATION")
    private fun configure(web: WebView, resources: Html5Resources) {
        WebView.setWebContentsDebuggingEnabled(false)
        web.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = false
            allowContentAccess = false
            allowFileAccessFromFileURLs = false
            allowUniversalAccessFromFileURLs = false
            blockNetworkLoads = true
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            javaScriptCanOpenWindowsAutomatically = false
            setSupportMultipleWindows(true)
            mediaPlaybackRequiresUserGesture = true
            useWideViewPort = true
            loadWithOverviewMode = true
            builtInZoomControls = true
            displayZoomControls = false
        }
        web.setDownloadListener { _, _, _, _, _ ->
            warn("download_blocked", "Se bloqueó una descarga.")
        }
        web.setOnLongClickListener { true }
        web.webChromeClient = object : WebChromeClient() {
            override fun onCreateWindow(
                view: WebView, isDialog: Boolean, isUserGesture: Boolean, resultMsg: android.os.Message,
            ): Boolean {
                warn("popup_blocked", "Se bloqueó una ventana adicional.")
                return false
            }

            override fun onPermissionRequest(request: PermissionRequest) {
                request.deny()
                warn("permission_blocked", "Se bloqueó un permiso web.")
            }

            override fun onGeolocationPermissionsShowPrompt(
                origin: String, callback: GeolocationPermissions.Callback,
            ) {
                callback.invoke(origin, false, false)
                warn("permission_blocked", "Se bloqueó un permiso web.")
            }

            override fun onShowFileChooser(
                webView: WebView, callback: ValueCallback<Array<Uri>>, params: FileChooserParams,
            ): Boolean {
                callback.onReceiveValue(null)
                warn("file_picker_blocked", "Se bloqueó una solicitud de archivos.")
                return true
            }

            override fun onJsAlert(view: WebView, url: String, message: String, result: JsResult): Boolean {
                result.cancel()
                return true
            }

            override fun onJsConfirm(view: WebView, url: String, message: String, result: JsResult): Boolean {
                result.cancel()
                return true
            }

            override fun onJsPrompt(
                view: WebView, url: String, message: String, defaultValue: String, result: JsPromptResult,
            ): Boolean {
                result.cancel()
                return true
            }
        }
        web.webViewClient = object : WebViewClient() {
            override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest) =
                resources.intercept(request.url, request.method)

            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                if (resources.owns(request.url) && request.method == "GET") return false
                warn("navigation_blocked", "Se bloqueó una navegación fuera del juego.")
                return true
            }

            override fun onPageFinished(view: WebView, url: String) {
                if (session?.starting == true && resources.owns(Uri.parse(url))) {
                    main.removeCallbacks(startupTimeout)
                    if (reported.isEmpty()) status.visibility = View.GONE
                    pause.isEnabled = true
                    session?.ready()
                }
            }

            override fun onReceivedError(
                view: WebView, request: WebResourceRequest, error: WebResourceError,
            ) = resourceError(request, resources)

            override fun onReceivedHttpError(
                view: WebView, request: WebResourceRequest, response: WebResourceResponse,
            ) = resourceError(request, resources)

            override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail): Boolean {
                rendererGone = true
                abort("renderer_stopped", "El proceso de reproducción se detuvo.")
                return true
            }
        }
    }

    private fun resourceError(request: WebResourceRequest, resources: Html5Resources) {
        if (!resources.owns(request.url)) return
        if (request.isForMainFrame && session?.starting == true) {
            abort("entry_load_failed", "No se pudo cargar la entrada HTML del juego.")
        } else {
            warn("resource_unavailable", "No se pudo cargar un recurso del juego.")
        }
    }

    private fun warn(code: String, text: String) {
        if (!reported.add(code)) return
        status.text = text
        status.visibility = View.VISIBLE
        session?.diagnostic(code, text)
    }

    private fun abort(code: String, message: String) {
        session?.fail(code, message)
        finish()
    }

    fun setUserPaused(value: Boolean) {
        userPaused = value
        pause.text = if (value) "Reanudar" else "Pausar"
        updatePause()
    }

    private fun updatePause() {
        val web = webView ?: return
        val shouldSuspend = userPaused || !foreground
        if (rendererGone || suspended == shouldSuspend) return
        suspended = shouldSuspend
        if (canMuteAudio) WebViewCompat.setAudioMuted(web, suspended)
        if (suspended) {
            web.evaluateJavascript("document.querySelectorAll('audio,video').forEach(x=>x.pause())", null)
            web.onPause()
            web.pauseTimers()
        } else {
            web.resumeTimers()
            web.onResume()
        }
    }

    override fun onResume() {
        super.onResume()
        foreground = true
        updatePause()
    }

    override fun onPause() {
        foreground = false
        updatePause()
        super.onPause()
    }

    @Suppress("DEPRECATION")
    private fun setFullscreen(value: Boolean) {
        fullscreen = value
        fullscreenButton.text = if (fullscreen) "Salir de pantalla completa" else "Pantalla completa"
        if (Build.VERSION.SDK_INT >= 30) {
            window.insetsController?.let {
                it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                if (fullscreen) it.hide(WindowInsets.Type.systemBars()) else it.show(WindowInsets.Type.systemBars())
            }
        } else {
            window.decorView.systemUiVisibility = if (fullscreen) {
                View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            } else 0
        }
    }

    override fun onDestroy() {
        main.removeCallbacks(startupTimeout)
        webView?.let { web ->
            container.removeView(web)
            if (!rendererGone) {
                if (suspended) web.resumeTimers()
                web.stopLoading()
            }
            web.destroy()
        }
        webView = null
        session?.closed()
        session = null
        super.onDestroy()
    }
}
