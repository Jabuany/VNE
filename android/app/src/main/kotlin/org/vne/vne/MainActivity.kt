package org.vne.vne

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var imports: ImportTreeChannel? = null
    private var player: Html5PlayerChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        imports = ImportTreeChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        player = Html5PlayerChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        imports?.close()
        imports = null
        player?.close()
        player = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    @Deprecated("Android tree picker callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        imports?.onActivityResult(requestCode, resultCode, data)
    }
}
