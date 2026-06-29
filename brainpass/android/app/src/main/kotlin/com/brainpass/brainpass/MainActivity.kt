package com.brainpass.brainpass

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter PARENT UI and bridges it to the native engine. The kid lock
 * is now 100% native (see GuardService + LockUi), so this no longer launches or
 * coordinates any lock screen — it just pushes parent config down to the engine.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "brainpass/engine"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GuardService.start(this) // start/keep the guard
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setRules" -> {
                        @Suppress("UNCHECKED_CAST")
                        val rules = (call.argument<List<Map<String, Any?>>>("rules")) ?: emptyList()
                        EnginePrefs.setRules(this, rules)
                        result.success(true)
                    }
                    "setMasterEnabled" -> {
                        EnginePrefs.setMasterEnabled(this, call.argument<Boolean>("enabled") ?: true)
                        result.success(true)
                    }
                    "setAgeBand" -> {
                        EnginePrefs.setAgeBand(this, call.argument<String>("band") ?: "b")
                        result.success(true)
                    }
                    "setPin" -> {
                        val hash = call.argument<String>("hash")
                        val salt = call.argument<String>("salt")
                        if (hash != null && salt != null) EnginePrefs.setPin(this, hash, salt)
                        result.success(true)
                    }
                    "clearBudgets" -> {
                        EnginePrefs.clearBudgets(this)
                        result.success(true)
                    }
                    "appStatus" -> {
                        val pkg = call.argument<String>("package")
                        if (pkg == null) result.success(null)
                        else result.success(
                            mapOf(
                                "usedMs" to EnginePrefs.usedMs(this, pkg),
                                "remMs" to EnginePrefs.remMs(this, pkg),
                                "minutes" to EnginePrefs.minutes(this, pkg),
                                "questions" to EnginePrefs.questions(this, pkg)
                            )
                        )
                    }
                    "hasUsageAccess" -> result.success(GuardService.hasUsageAccess(this))
                    "openUsageAccessSettings" -> {
                        // Best-effort: some OEMs honor a package URI and jump
                        // straight to Nupo's usage-access toggle; otherwise the
                        // list, otherwise all settings.
                        val attempts = listOf(
                            Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS, Uri.parse("package:$packageName")),
                            Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS),
                            Intent(Settings.ACTION_SETTINGS)
                        )
                        for (i in attempts) {
                            try {
                                startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); break
                            } catch (_: Exception) {
                            }
                        }
                        result.success(true)
                    }
                    "startGuard" -> {
                        GuardService.start(this)
                        WatchdogReceiver.schedule(this)
                        result.success(true)
                    }
                    "autostartRelevant" -> result.success(Autostart.isRelevant())
                    "openAutostartSettings" -> result.success(Autostart.open(this))
                    "canDrawOverlays" -> result.success(Settings.canDrawOverlays(this))
                    "requestOverlay" -> {
                        startActivity(
                            Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }
                    "isIgnoringBattery" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBattery" -> {
                        startActivity(
                            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName"))
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
