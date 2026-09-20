package com.example.notes_app

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Δέχεται αρχεία που ανοίγει ο χρήστης από την εξερεύνηση αρχείων
 * (ACTION_VIEW / ACTION_SEND) — PDF, Word (.docx), markdown, κείμενο.
 *
 * Επειδή το URI που έρχεται είναι συνήθως `content://` (δεν έχει πραγματικό
 * path), αντιγράφουμε το περιεχόμενο σε αρχείο μέσα στην cache της
 * εφαρμογής και επιστρέφουμε ΑΥΤΟ το path στο Flutter μέσω του
 * MethodChannel `notes_app/intent` (το περιμένει ήδη το lib/main.dart).
 */
class MainActivity : FlutterActivity() {

    companion object {
        const val ACTION_QUICK_NOTE = "com.example.notes_app.ACTION_QUICK_NOTE"
    }

    private val channelName = "notes_app/intent"
    private var pendingFilePath: String? = null
    private var pendingQuickNote: Boolean = false
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingFilePath = resolveIntentFile(intent)
        pendingQuickNote = intent?.action == ACTION_QUICK_NOTE

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialFile" -> {
                    result.success(pendingFilePath)
                    pendingFilePath = null
                }
                "getLaunchAction" -> {
                    result.success(if (pendingQuickNote) "quick_note" else null)
                    pendingQuickNote = false
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Όταν η εφαρμογή τρέχει ήδη και ο χρήστης ανοίξει άλλο αρχείο,
     *  ή πατήσει το shortcut/tile "Γρήγορη σημείωση". */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == ACTION_QUICK_NOTE) {
            if (channel != null) {
                channel?.invokeMethod("onQuickNote", null)
            } else {
                pendingQuickNote = true
            }
            return
        }
        val path = resolveIntentFile(intent)
        if (path != null) {
            if (channel != null) {
                channel?.invokeMethod("onFileOpened", path)
            } else {
                pendingFilePath = path
            }
        }
    }

    private fun resolveIntentFile(intent: Intent?): String? {
        if (intent == null) return null
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_VIEW, Intent.ACTION_EDIT -> intent.data
            Intent.ACTION_SEND -> intent.getParcelableExtra(Intent.EXTRA_STREAM)
            else -> null
        }
        if (uri == null) return null
        return try {
            when (uri.scheme) {
                "file" -> uri.path
                "content" -> copyToCache(uri)
                else -> null
            }
        } catch (e: Exception) {
            null
        }
    }

    /** Αντιγράφει το content:// URI σε πραγματικό αρχείο στην cache. */
    private fun copyToCache(uri: Uri): String? {
        val name = queryDisplayName(uri) ?: "imported_${System.currentTimeMillis()}"
        val dir = File(cacheDir, "incoming").apply { mkdirs() }
        val out = File(dir, name)
        contentResolver.openInputStream(uri)?.use { input ->
            out.outputStream().use { output -> input.copyTo(output) }
        } ?: return null
        return out.absolutePath
    }

    private fun queryDisplayName(uri: Uri): String? {
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) return cursor.getString(index)
        }
        return null
    }
}
