package org.vne.vne

import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import android.system.Os
import android.system.OsConstants
import android.webkit.MimeTypeMap
import android.webkit.WebResourceResponse
import java.io.File
import java.io.InputStream
import java.util.Locale
import androidx.webkit.WebViewAssetLoader

internal fun resourcePath(path: String): List<String>? {
    if (path.length > 8192 || path.any { it == '\\' || it == ':' || it < ' ' }) return null
    return path.split('/').takeIf { segments ->
        segments.size <= 33 && segments.all {
            it.isNotEmpty() && it != "." && it != ".." && it.toByteArray().size <= 255
        }
    }
}

internal fun isLocalGameTree(uri: Uri): Boolean =
    uri.scheme == "content" && DocumentsContract.isTreeUri(uri) &&
        (uri.authority == "com.android.externalstorage.documents" ||
            uri.authority == "com.android.providers.downloads.documents")

internal class Html5Resources(context: Context, session: Html5Session) {
    val host = "vne-${session.gameId}.invalid"
    val entryUrl = Uri.Builder().scheme("https").authority(host)
        .apply { requireNotNull(resourcePath(session.entryPoint)).forEach { appendPath(it) } }
        .build().toString()
    private val resolver = context.contentResolver
    private val tree = if (session.managed) null else session.source.also { uri ->
        require(isLocalGameTree(uri))
        require(resolver.persistedUriPermissions.any { it.uri == uri && it.isReadPermission })
    }
    private val directory = if (!session.managed) null else {
        val uri = session.source
        require(uri.scheme == "file" && uri.authority.isNullOrEmpty())
        val root = File(context.filesDir, "games").canonicalFile
        File(requireNotNull(uri.path)).canonicalFile.also {
            require(it.parentFile == root && it.isDirectory && it.name.startsWith("game-"))
        }
    }
    private val loader = WebViewAssetLoader.Builder().setDomain(host)
        .addPathHandler("/") { path -> load(path) }
        .build()

    fun owns(uri: Uri): Boolean =
        uri.scheme == "https" && uri.host == host && uri.userInfo == null &&
            (uri.port == -1 || uri.port == 443)

    fun intercept(uri: Uri, method: String): WebResourceResponse {
        if (!owns(uri) || method != "GET") return denied()
        val encoded = uri.encodedPath.orEmpty().lowercase(Locale.ROOT)
        if (encoded.contains("%2f") || encoded.contains("%5c")) return denied()
        return loader.shouldInterceptRequest(uri) ?: denied()
    }

    private fun load(path: String): WebResourceResponse {
        val segments = resourcePath(path) ?: return denied()
        val stream = try {
            directory?.let { fileStream(it, segments) } ?: tree?.let { documentStream(it, segments) }
        } catch (_: Exception) {
            null
        } ?: return response(404, "Not Found")
        val extension = segments.last().substringAfterLast('.', "").lowercase(Locale.ROOT)
        val type = when (extension) {
            "js", "mjs" -> "application/javascript"
            "json" -> "application/json"
            "wav" -> "audio/wav"
            "woff2" -> "font/woff2"
            else -> MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
                ?: "application/octet-stream"
        }
        val charset = if (type.startsWith("text/") ||
            type == "application/javascript" || type == "application/json"
        ) "UTF-8" else null
        return WebResourceResponse(type, charset, 200, "OK", headers, stream)
    }

    private fun fileStream(root: File, path: List<String>): InputStream? {
        var cursor = root
        path.forEachIndexed { index, name ->
            cursor = File(cursor, name)
            val mode = Os.lstat(cursor.path).st_mode
            if (index == path.lastIndex && !OsConstants.S_ISREG(mode)) return null
            if (index != path.lastIndex && !OsConstants.S_ISDIR(mode)) return null
        }
        return cursor.inputStream()
    }

    private fun documentStream(tree: Uri, path: List<String>): InputStream? {
        var id = DocumentsContract.getTreeDocumentId(tree)
        for ((index, name) in path.withIndex()) {
            val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, id)
            val columns = arrayOf(
                Document.COLUMN_DOCUMENT_ID, Document.COLUMN_DISPLAY_NAME,
                Document.COLUMN_MIME_TYPE, Document.COLUMN_FLAGS,
            )
            id = resolver.query(children, columns, null, null, null)?.use { cursor ->
                var match: String? = null
                var checked = 0
                while (cursor.moveToNext()) {
                    if (++checked > 10_000) return null
                    if (cursor.getString(1) != name) continue
                    if (match != null || cursor.getInt(3) and Document.FLAG_VIRTUAL_DOCUMENT != 0 ||
                        (cursor.getString(2) == Document.MIME_TYPE_DIR) != (index != path.lastIndex)
                    ) return null
                    match = cursor.getString(0)
                }
                match
            } ?: return null
        }
        return resolver.openInputStream(DocumentsContract.buildDocumentUriUsingTree(tree, id))
    }

    companion object {
        private val headers = mapOf(
            "Cache-Control" to "no-store",
            "X-Content-Type-Options" to "nosniff",
            "Content-Security-Policy" to "default-src 'none'; script-src 'self' 'unsafe-inline'; " +
                "style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; " +
                "font-src 'self' data:; media-src 'self' blob:; connect-src 'self'; " +
                "base-uri 'none'; form-action 'none'; frame-ancestors 'none'; worker-src 'none'",
        )

        fun denied(): WebResourceResponse = response(403, "Forbidden")

        private fun response(code: Int, reason: String) = WebResourceResponse(
            "text/plain", "UTF-8", code, reason, headers, reason.byteInputStream(),
        )
    }
}
