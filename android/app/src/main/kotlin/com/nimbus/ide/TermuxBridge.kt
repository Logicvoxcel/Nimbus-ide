package com.nimbus.ide

import io.flutter.plugin.common.MethodChannel

/**
 * Termux runs each command asynchronously and calls us back later via a
 * PendingIntent, on a different Android component (TermuxResultService)
 * than the one that sent the request (MainActivity). Since both run in the
 * same process, this object -- shared by reference -- is how the result
 * finds its way back to the Flutter [MethodChannel.Result] that's still
 * waiting on it.
 */
object TermuxBridge {
    private val pendingResults = mutableMapOf<Int, MethodChannel.Result>()
    private var nextId = 1000

    @Synchronized
    fun nextExecutionId(): Int {
        nextId += 1
        return nextId
    }

    @Synchronized
    fun registerPending(id: Int, result: MethodChannel.Result) {
        pendingResults[id] = result
    }

    @Synchronized
    fun resolve(id: Int, data: Map<String, Any?>) {
        pendingResults.remove(id)?.success(data)
    }

    @Synchronized
    fun fail(id: Int, message: String) {
        pendingResults.remove(id)?.error("TERMUX_ERROR", message, null)
    }
}
