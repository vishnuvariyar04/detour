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
 * Hosts the Flutter UI AND bridges Flutter <-> the native engine.
 *  - Flutter pushes per-app rules down (setRules) and the master switch.
 *  - The earn screen reports success (earned) or a parent override (override).
 *  - Permission state + opening the right system settings screens.
 *  - When launched as a lock, exposes which app + mode + question count.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "brainpass/engine"
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Start/keep the guard (foreground service + UsageStats detection loop).
        GuardService.start(this)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel = ch
        ch.setMethodCallHandler { call, result ->
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
                "clearBudgets" -> {
                    EnginePrefs.clearBudgets(this)
                    result.success(true)
                }
                "earned" -> {
                    call.argument<String>("package")?.let { EnginePrefs.addEarned(this, it) }
                    result.success(true)
                }
                "parentOverride" -> {
                    call.argument<String>("package")?.let { EnginePrefs.addOverride(this, it) }
                    result.success(true)
                }
                "appStatus" -> {
                    val pkg = call.argument<String>("package")
                    if (pkg == null) { result.success(null) }
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
                    try {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    } catch (e: Exception) {
                        startActivity(Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    }
                    result.success(true)
                }
                "startGuard" -> {
                    GuardService.start(this)
                    result.success(true)
                }
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
                "getLaunchLockInfo" -> result.success(lockInfo(intent))
                "finishLock" -> {
                    finishAndRemoveTask()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Relaunched (warm) as a lock — tell Flutter to show the earn screen. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getStringExtra("lock_package") != null) {
            channel?.invokeMethod("showLock", lockInfo(intent))
        }
    }

    private fun lockInfo(intent: Intent?): Map<String, Any?>? {
        val pkg = intent?.getStringExtra("lock_package") ?: return null
        return mapOf(
            "package" to pkg,
            "mode" to (intent.getStringExtra("lock_mode") ?: "earn"),
            "questions" to intent.getIntExtra("lock_questions", 3),
            "minutes" to intent.getIntExtra("lock_minutes", 15)
        )
    }

}
