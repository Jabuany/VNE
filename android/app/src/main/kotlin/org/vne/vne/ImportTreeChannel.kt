package org.vne.vne

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream
import java.util.concurrent.Executors

internal class ImportTreeChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "org.vne.vne/import_tree")
    private val worker = Executors.newSingleThreadExecutor()
    private var selection: MethodChannel.Result? = null
    private var input: InputStream? = null

    init {
        channel.setMethodCallHandler(::handle)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "pick") {
            if (selection != null) {
                result.error("busy", "Ya hay un selector abierto.", null)
                return
            }
            selection = result
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                putExtra(Intent.EXTRA_LOCAL_ONLY, true)
            }
            try {
                @Suppress("DEPRECATION")
                activity.startActivityForResult(intent, pickerRequest)
            } catch (_: RuntimeException) {
                selection = null
                result.error("picker_failed", "No se pudo abrir el selector.", null)
            }
            return
        }

        worker.execute {
            try {
                val value = when (call.method) {
                    "root" -> {
                        val tree = treeUri(call)
                        val id = DocumentsContract.getTreeDocumentId(tree)
                        val uri = DocumentsContract.buildDocumentUriUsingTree(tree, id)
                        activity.contentResolver.query(
                            uri, arrayOf(Document.COLUMN_DISPLAY_NAME), null, null, null,
                        )?.use {
                            check(it.moveToFirst())
                            mapOf("id" to id, "name" to (it.getString(0) ?: "Juego"))
                        } ?: error("Unavailable directory")
                    }
                    "children" -> children(treeUri(call), requireNotNull(call.argument("id")))
                    "open" -> {
                        check(input == null)
                        val uri = DocumentsContract.buildDocumentUriUsingTree(
                            treeUri(call), requireNotNull(call.argument("id")),
                        )
                        input = requireNotNull(activity.contentResolver.openInputStream(uri))
                        null
                    }
                    "read" -> {
                        val size = requireNotNull(call.argument<Int>("size"))
                        require(size in 1..65536)
                        val bytes = ByteArray(size)
                        val count = requireNotNull(input).read(bytes)
                        if (count == bytes.size) bytes else bytes.copyOf(count.coerceAtLeast(0))
                    }
                    "closeFile" -> {
                        try {
                            input?.close()
                        } finally {
                            input = null
                        }
                        null
                    }
                    "retain" -> {
                        activity.contentResolver.takePersistableUriPermission(
                            treeUri(call), Intent.FLAG_GRANT_READ_URI_PERMISSION,
                        )
                        null
                    }
                    else -> {
                        result.notImplemented()
                        return@execute
                    }
                }
                result.success(value)
            } catch (_: Exception) {
                result.error("source_unavailable", "No se pudo leer el origen seleccionado.", null)
            }
        }
    }

    private fun treeUri(call: MethodCall): Uri =
        Uri.parse(requireNotNull(call.argument<String>("source"))).also {
            require(isLocalGameTree(it))
        }

    private fun children(tree: Uri, id: String): List<Map<String, Any?>> {
        val args = arrayOf(
            Document.COLUMN_DOCUMENT_ID,
            Document.COLUMN_DISPLAY_NAME,
            Document.COLUMN_MIME_TYPE,
            Document.COLUMN_SIZE,
            Document.COLUMN_FLAGS,
        )
        val uri = DocumentsContract.buildChildDocumentsUriUsingTree(tree, id)
        return requireNotNull(activity.contentResolver.query(uri, args, null, null, null))
            .use { cursor ->
                buildList {
                    while (cursor.moveToNext()) {
                        check(size < 10_000)
                        check(cursor.getInt(4) and Document.FLAG_VIRTUAL_DOCUMENT == 0)
                        add(mapOf(
                            "id" to requireNotNull(cursor.getString(0)),
                            "name" to requireNotNull(cursor.getString(1)),
                            "directory" to (cursor.getString(2) == Document.MIME_TYPE_DIR),
                            "size" to if (cursor.isNull(3)) null else cursor.getLong(3),
                        ))
                    }
                }
            }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != pickerRequest) return
        val result = selection ?: return
        selection = null
        val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
        if (uri == null || isLocalGameTree(uri)) {
            result.success(uri?.toString())
        } else {
            result.error("unsupported_provider", "Selecciona una carpeta del dispositivo.", null)
        }
    }

    fun close() {
        channel.setMethodCallHandler(null)
        selection?.success(null)
        selection = null
        worker.execute { runCatching { input?.close() } }
        worker.shutdown()
    }

    companion object {
        private const val pickerRequest = 641
    }
}
