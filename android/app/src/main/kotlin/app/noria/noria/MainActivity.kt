package app.noria.noria

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Debug
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEMORY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getMemoryInfo" -> result.success(readMemoryInfo())
                    else -> result.notImplemented()
                }
            }
    }

    private fun readMemoryInfo(): Map<String, Any?> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val system = ActivityManager.MemoryInfo().also { activityManager.getMemoryInfo(it) }
        val process = Debug.MemoryInfo().also { Debug.getMemoryInfo(it) }
        val chip = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            "${Build.SOC_MANUFACTURER} ${Build.SOC_MODEL}"
        } else {
            Build.HARDWARE
        }

        return mapOf(
            "totalBytes" to system.totalMem,
            "availableBytes" to system.availMem,
            "appBytes" to process.totalPss.toLong() * 1024L,
            "lowMemory" to system.lowMemory,
            "chip" to chip,
        )
    }

    private companion object {
        const val MEMORY_CHANNEL = "app.noria/memory"
    }
}
