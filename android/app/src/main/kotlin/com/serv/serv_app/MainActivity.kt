package com.serv.serv_app

import android.content.Context
import android.os.PowerManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    // TEMPORARY DIAGNOSTIC: registers the native Fused Location Provider
    // comparison channel used only by the debug-only GPS diagnostic tool.
    // Does not touch the production attendance/check-in/tracking plugins,
    // which remain auto-registered by GeneratedPluginRegistrant as before.
    //
    // Also exposes a tiny battery-optimization channel so Dart can check
    // whether the exemption is already granted before prompting - the
    // Play-safe REQUEST_IGNORE_BATTERY_OPTIMIZATIONS intent should only be
    // shown when actually needed (foreground-location is a permitted use).
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(NativeGpsDiagnostic(applicationContext))
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "serv/battery_opt"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    try {
                        val pm =
                            getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    } catch (e: Exception) {
                        // Unknown state must not break check-in - report
                        // not-exempt so the one-time prompt can still run.
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
