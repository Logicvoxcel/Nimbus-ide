package com.nimbus.ide

import android.app.IntentService
import android.content.Intent
import android.os.Handler
import android.os.Looper

/**
 * Termux invokes this (via the PendingIntent we hand it in RUN_COMMAND_PENDING_INTENT)
 * once a command finishes, delivering a Bundle under the "result" extra with
 * stdout/stderr/exit code. Runs on a background thread (that's what
 * IntentService is for), so results are handed back to TermuxBridge on the
 * main thread since Flutter's MethodChannel.Result must be called there.
 */
class TermuxResultService : IntentService("NimbusTermuxResultService") {

    override fun onHandleIntent(intent: Intent?) {
        if (intent == null) return
        val executionId = intent.getIntExtra(EXTRA_EXECUTION_ID, -1)
        if (executionId == -1) return

        val resultBundle = intent.getBundleExtra("result")
        val data: Map<String, Any?> = if (resultBundle != null) {
            mapOf(
                "stdout" to resultBundle.getString("stdout", ""),
                "stderr" to resultBundle.getString("stderr", ""),
                "exitCode" to resultBundle.getInt("exit_code", 0),
                "err" to resultBundle.getInt("err", 0),
                "errmsg" to resultBundle.getString("errmsg", "")
            )
        } else {
            mapOf(
                "stdout" to "",
                "stderr" to "",
                "exitCode" to -1,
                "err" to -1,
                "errmsg" to "No result returned by Termux"
            )
        }

        Handler(Looper.getMainLooper()).post {
            TermuxBridge.resolve(executionId, data)
        }
    }

    companion object {
        const val EXTRA_EXECUTION_ID = "com.nimbus.ide.EXECUTION_ID"
    }
}
