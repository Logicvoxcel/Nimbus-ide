package com.nimbus.ide

import android.app.PendingIntent
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges Flutter to Termux's documented RUN_COMMAND intent API
 * (https://github.com/termux/termux-app/wiki/RUN_COMMAND-Intent), plus a
 * small MediaStore helper to stage a file somewhere Termux can read it
 * (our app's own private storage isn't visible to other apps).
 */
class MainActivity : FlutterActivity() {

    private val channelName = "com.nimbus.ide/termux"
    private val termuxPackage = "com.termux"
    private val runCommandPermission = "com.termux.permission.RUN_COMMAND"
    private val permissionRequestCode = 4201

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isInstalled" -> result.success(isTermuxInstalled())
                "hasPermission" -> result.success(hasRunCommandPermission())
                "requestPermission" -> {
                    requestRunCommandPermission()
                    result.success(null)
                }
                "runCommand" -> handleRunCommand(call, result)
                "stageFile" -> handleStageFile(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun isTermuxInstalled(): Boolean = try {
        packageManager.getPackageInfo(termuxPackage, 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    private fun hasRunCommandPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, runCommandPermission) == PackageManager.PERMISSION_GRANTED

    private fun requestRunCommandPermission() {
        ActivityCompat.requestPermissions(this, arrayOf(runCommandPermission), permissionRequestCode)
    }

    private fun handleRunCommand(call: MethodCall, result: MethodChannel.Result) {
        if (!isTermuxInstalled()) {
            result.error("NOT_INSTALLED", "Termux is not installed", null)
            return
        }
        if (!hasRunCommandPermission()) {
            result.error("NO_PERMISSION", "RUN_COMMAND permission not granted", null)
            return
        }

        val path = call.argument<String>("path")
        if (path == null) {
            result.error("BAD_ARGS", "Missing executable path", null)
            return
        }
        @Suppress("UNCHECKED_CAST")
        val arguments = (call.argument<List<String>>("arguments") ?: emptyList()).toTypedArray()
        val workdir = call.argument<String>("workdir")
        val background = call.argument<Boolean>("background") ?: true

        val executionId = TermuxBridge.nextExecutionId()
        TermuxBridge.registerPending(executionId, result)

        try {
            val resultServiceIntent = Intent(this, TermuxResultService::class.java)
            resultServiceIntent.putExtra(TermuxResultService.EXTRA_EXECUTION_ID, executionId)
            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_ONE_SHOT
            }
            val pendingIntent = PendingIntent.getService(
                this, executionId, resultServiceIntent, pendingIntentFlags
            )

            val commandIntent = Intent()
            commandIntent.setClassName(termuxPackage, "com.termux.app.RunCommandService")
            commandIntent.action = "com.termux.RUN_COMMAND"
            commandIntent.putExtra("com.termux.RUN_COMMAND_PATH", path)
            commandIntent.putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arguments)
            if (workdir != null) {
                commandIntent.putExtra("com.termux.RUN_COMMAND_WORKDIR", workdir)
            }
            commandIntent.putExtra("com.termux.RUN_COMMAND_BACKGROUND", background)
            commandIntent.putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0")
            commandIntent.putExtra("com.termux.RUN_COMMAND_PENDING_INTENT", pendingIntent)

            startService(commandIntent)
        } catch (e: Exception) {
            TermuxBridge.fail(executionId, e.message ?: "Failed to start Termux command")
        }
    }

    /**
     * Writes [content] into the public Downloads/NimbusIDE/<subDir> folder via
     * MediaStore (no MANAGE_EXTERNAL_STORAGE needed -- that permission is
     * heavily scrutinized for Play Store approval and isn't warranted here),
     * and returns the real filesystem path so it can be handed to Termux as
     * a plain path argument. Requires the user to have granted Termux
     * storage access so it can see files here too.
     */
    private fun handleStageFile(call: MethodCall, result: MethodChannel.Result) {
        val subDir = call.argument<String>("subDir") ?: "run"
        val filename = call.argument<String>("filename")
        val content = call.argument<String>("content")
        if (filename == null || content == null) {
            result.error("BAD_ARGS", "Missing filename or content", null)
            return
        }
        val relativePath = "Download/NimbusIDE/$subDir"
        try {
            val resolver = contentResolver
            resolver.delete(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                "${MediaStore.Downloads.RELATIVE_PATH}=? AND ${MediaStore.Downloads.DISPLAY_NAME}=?",
                arrayOf("$relativePath/", filename)
            )

            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, filename)
                put(MediaStore.Downloads.MIME_TYPE, "text/plain")
                put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            if (uri == null) {
                result.error("STAGE_FAILED", "Could not create file", null)
                return
            }
            resolver.openOutputStream(uri)?.use { it.write(content.toByteArray(Charsets.UTF_8)) }
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            val storageRoot = Environment.getExternalStorageDirectory().path
            result.success("$storageRoot/$relativePath/$filename")
        } catch (e: Exception) {
            result.error("STAGE_FAILED", e.message ?: "Could not stage file", null)
        }
    }
}
