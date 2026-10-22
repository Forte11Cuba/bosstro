package foundation.mostro.bosstro

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.PersistableBundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The device I/O the solver key needs and Flutter does not offer
 * (lib/core/services/device_security.dart):
 *
 * - `setSecure`: FLAG_SECURE while a screen shows the secret key, so it is
 *   kept out of screenshots, screen recording and the recent-apps thumbnail.
 * - `copySensitive`: copies text marked EXTRA_IS_SENSITIVE, so Android 13+
 *   hides it in the copy preview and keyboards keep it out of their
 *   clipboard history.
 * - `clearSensitive`: clears the clipboard if it still holds what
 *   `copySensitive` put there, and nothing else.
 */
class MainActivity : FlutterActivity() {
    /** What `copySensitive` last copied, until it is cleared or replaced. */
    private var sensitive: String? = null

    /**
     * Whether the activity is in the foreground. From Android 10 a background
     * app reads an empty clipboard, which must not pass for a cleared one.
     */
    private var resumed = false

    override fun onResume() {
        super.onResume()
        resumed = true
    }

    override fun onPause() {
        resumed = false
        super.onPause()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        if (call.arguments as Boolean) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    "copySensitive" -> {
                        copySensitive(call.arguments as String)
                        result.success(null)
                    }
                    "clearSensitive" -> result.success(clearSensitive())
                    else -> result.notImplemented()
                }
            }
    }

    private fun clipboard() =
        getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

    private fun copySensitive(text: String) {
        val clip = ClipData.newPlainText("", text)
        clip.description.extras = PersistableBundle().apply {
            // The constant exists from API 33; the key is honoured by
            // keyboards on older versions too.
            val key = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                ClipDescription.EXTRA_IS_SENSITIVE
            } else {
                "android.content.extra.IS_SENSITIVE"
            }
            putBoolean(key, true)
        }
        clipboard().setPrimaryClip(clip)
        sensitive = text
    }

    /**
     * Clears the clipboard if it still holds the sensitive text. Returns
     * whether that is settled: true when cleared, or when the clipboard holds
     * something else now (the user copied over it); false when it cannot be
     * read (the app is in the background), so Dart retries on resume.
     */
    private fun clearSensitive(): Boolean {
        val expected = sensitive ?: return true
        if (!resumed) return false
        val clip = clipboard().primaryClip
        val current =
            if (clip != null && clip.itemCount > 0) clip.getItemAt(0).text?.toString() else null
        if (current == expected) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                clipboard().clearPrimaryClip()
            } else {
                clipboard().setPrimaryClip(ClipData.newPlainText("", ""))
            }
        }
        sensitive = null
        return true
    }

    private companion object {
        const val CHANNEL = "foundation.mostro.bosstro/device_security"
    }
}
