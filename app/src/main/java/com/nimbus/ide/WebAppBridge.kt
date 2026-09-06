package com.nimbus.ide

import android.content.ContentValues
import android.content.Context
import android.provider.MediaStore
import android.util.Base64
import android.webkit.JavascriptInterface
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

/**
 * Bridges the web app (assets/www/index.html) to native Android capabilities.
 *
 * The page feature-detects `window.AndroidBridge` at runtime, so the exact
 * same HTML file also works standalone in a normal browser or inside the
 * Claude.ai artifact preview -- there it just falls back to localStorage /
 * the Claude storage API, a plain browser download, and (on desktop Chrome
 * or Edge) the browser's own File System Access API instead.
 *
 * Requires minSdk 29+ so every Downloads write goes through scoped-storage
 * MediaStore APIs with no storage permission needed. Folder access uses the
 * Storage Access Framework instead, so it doesn't need a storage permission
 * either -- MainActivity owns the actual picker launch and the folder-tree
 * read/write; this class just relays JS calls to it.
 */
class WebAppBridge(
    private val context: Context,
    private val onPickFolder: () -> Unit,
    private val onWriteFolderFile: (String, String) -> Unit
) {

    private val prefs = context.getSharedPreferences("nimbus_storage", Context.MODE_PRIVATE)

    @JavascriptInterface
    fun getItem(key: String): String? = prefs.getString(key, null)

    @JavascriptInterface
    fun setItem(key: String, value: String) {
        prefs.edit().putString(key, value).apply()
    }

    @JavascriptInterface
    fun saveTextFile(filename: String, content: String) {
        writeToDownloads(filename, content.toByteArray(Charsets.UTF_8), "text/plain")
    }

    @JavascriptInterface
    fun saveBinaryFile(filename: String, base64Content: String) {
        val bytes = Base64.decode(base64Content, Base64.DEFAULT)
        writeToDownloads(filename, bytes, "application/zip")
    }

    /** Triggers the native ACTION_OPEN_DOCUMENT_TREE picker (async — result
     *  arrives back in JS via window.onFolderOpened / window.onFolderOpenFailed). */
    @JavascriptInterface
    fun pickFolder() {
        onPickFolder()
    }

    /** Writes an updated file back into a previously opened folder tree. */
    @JavascriptInterface
    fun writeFolderFile(path: String, content: String) {
        onWriteFolderFile(path, content)
    }

    private fun writeToDownloads(filename: String, bytes: ByteArray, mime: String) {
        try {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, filename)
                put(MediaStore.Downloads.MIME_TYPE, mime)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val resolver = context.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("MediaStore insert failed")

            resolver.openOutputStream(uri)?.use { it.write(bytes) }
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            postToast("Saved to Downloads: $filename")
        } catch (e: Exception) {
            postToast("Could not save $filename")
        }
    }

    private fun postToast(message: String) {
        val activity = context as? AppCompatActivity ?: return
        activity.runOnUiThread {
            Toast.makeText(activity, message, Toast.LENGTH_SHORT).show()
        }
    }
}
