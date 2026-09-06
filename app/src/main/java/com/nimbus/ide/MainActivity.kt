package com.nimbus.ide

import android.annotation.SuppressLint
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.KeyEvent
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.documentfile.provider.DocumentFile
import androidx.webkit.WebViewAssetLoader
import androidx.webkit.WebViewClientCompat
import org.json.JSONArray
import org.json.JSONObject
import kotlin.concurrent.thread

/**
 * Hosts the Nimbus IDE web app (bundled under assets/www) inside a WebView.
 *
 * Static files are served through WebViewAssetLoader on the
 * https://appassets.androidplatform.net virtual origin instead of a raw
 * file:// URL. That gives the page a normal https-style origin, which is
 * what Monaco's worker loader and modern fetch()/CORS-sensitive code expect.
 */
class MainActivity : AppCompatActivity() {

    private lateinit var webView: WebView

    // relative path -> content Uri, built each time a folder is opened, used
    // to route the web app's write-backs to the right document.
    private val pathToUri = mutableMapOf<String, Uri>()

    private val skipDirs = setOf(
        "node_modules", ".git", "dist", "build", ".next", "target",
        "venv", ".venv", "__pycache__", ".idea", ".gradle"
    )
    private val maxFiles = 300
    private val maxFileBytes = 2_000_000L

    private val openFolderLauncher = registerForActivityResult(
        ActivityResultContracts.OpenDocumentTree()
    ) { uri: Uri? ->
        if (uri == null) {
            notifyFolderOpenFailed("Folder selection cancelled")
        } else {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
            thread { readFolderAndNotify(uri) }
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Let the web app's CSS env(safe-area-inset-*) rules see the real
        // notch/gesture-bar insets by drawing edge-to-edge.
        WindowCompat.setDecorFitsSystemWindows(window, false)

        setContentView(R.layout.activity_main)
        webView = findViewById(R.id.webview)

        val assetLoader = WebViewAssetLoader.Builder()
            .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(this))
            .build()

        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        webView.settings.allowFileAccess = false
        webView.settings.allowContentAccess = false

        webView.webViewClient = object : WebViewClientCompat() {
            override fun shouldInterceptRequest(
                view: WebView,
                request: WebResourceRequest
            ): WebResourceResponse? = assetLoader.shouldInterceptRequest(request.url)
        }

        // Exposes window.AndroidBridge to the page: on-device key/value storage,
        // Downloads-folder file export, and the native "Open folder" flow.
        webView.addJavascriptInterface(
            WebAppBridge(
                context = this,
                onPickFolder = { runOnUiThread { openFolderLauncher.launch(null) } },
                onWriteFolderFile = { path, content -> writeFolderFile(path, content) }
            ),
            "AndroidBridge"
        )

        webView.loadUrl("https://appassets.androidplatform.net/assets/index.html")
    }

    private fun readFolderAndNotify(treeUri: Uri) {
        try {
            val root = DocumentFile.fromTreeUri(this, treeUri)
            if (root == null) {
                notifyFolderOpenFailed("Could not open that folder")
                return
            }
            pathToUri.clear()
            val filesJson = JSONArray()
            var count = 0

            fun walk(dir: DocumentFile, prefix: String) {
                for (child in dir.listFiles()) {
                    if (count >= maxFiles) return
                    val name = child.name ?: continue
                    val path = if (prefix.isEmpty()) name else "$prefix/$name"
                    if (child.isDirectory) {
                        if (name in skipDirs || name.startsWith(".")) continue
                        walk(child, path)
                    } else if (child.length() in 0..maxFileBytes) {
                        val text = readText(child.uri) ?: continue
                        filesJson.put(JSONObject().put("path", path).put("content", text))
                        pathToUri[path] = child.uri
                        count++
                    }
                    if (count >= maxFiles) return
                }
            }
            walk(root, "")

            val result = JSONObject()
                .put("folderName", root.name ?: "folder")
                .put("truncated", count >= maxFiles)
                .put("files", filesJson)
            runOnUiThread {
                webView.evaluateJavascript(
                    "window.onFolderOpened(" + JSONObject.quote(result.toString()) + ")",
                    null
                )
            }
        } catch (e: Exception) {
            notifyFolderOpenFailed("Could not read that folder")
        }
    }

    private fun readText(uri: Uri): String? = try {
        contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() }
    } catch (e: Exception) {
        null // binary or unreadable file — skip it rather than fail the whole import
    }

    private fun writeFolderFile(path: String, content: String) {
        val uri = pathToUri[path] ?: return
        try {
            contentResolver.openOutputStream(uri, "wt")?.use { it.write(content.toByteArray()) }
        } catch (e: Exception) {
            // best-effort — the in-app copy is still safe in AndroidBridge's own storage
        }
    }

    private fun notifyFolderOpenFailed(message: String) {
        runOnUiThread {
            webView.evaluateJavascript(
                "window.onFolderOpenFailed(" + JSONObject.quote(message) + ")",
                null
            )
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK && webView.canGoBack()) {
            webView.goBack()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
}
