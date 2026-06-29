package com.brainpass.brainpass

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings

/**
 * Opens the OEM-specific "Autostart" settings screen. On Xiaomi/Oppo/Vivo/etc.
 * Autostart is the master switch that decides whether the app may run/restart in
 * the background at all — without it, the guard gets killed and can't recover.
 * There's no API to read it, so we just deep-link the parent to the right page.
 */
object Autostart {
    private val candidates = listOf(
        // Xiaomi / MIUI / HyperOS
        ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
        // Oppo / ColorOS
        ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
        ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"),
        ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
        // Vivo / iQOO
        ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
        ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"),
        // Huawei / Honor
        ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
        ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"),
        // Letv / Meizu
        ComponentName("com.letv.android.letvsafe", "com.letv.android.letvsafe.AutobootManageActivity"),
        ComponentName("com.meizu.safe", "com.meizu.safe.security.SHOW_APPSEC"),
    )

    /** True on OEMs that have an Autostart-style control (so we show the step). */
    fun isRelevant(): Boolean {
        val m = (Build.MANUFACTURER + " " + Build.BRAND).lowercase()
        return listOf(
            "xiaomi", "redmi", "poco", "oppo", "vivo", "iqoo", "realme",
            "oneplus", "huawei", "honor", "letv", "meizu", "asus"
        ).any { m.contains(it) }
    }

    /** Try to open the Autostart screen; fall back to the app's settings page. */
    fun open(ctx: Context): Boolean {
        for (cn in candidates) {
            try {
                val intent = Intent().apply {
                    component = cn
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                if (ctx.packageManager.resolveActivity(intent, 0) != null) {
                    ctx.startActivity(intent)
                    return true
                }
            } catch (_: Throwable) {
            }
        }
        return try {
            ctx.startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:${ctx.packageName}")
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            true
        } catch (_: Throwable) {
            false
        }
    }
}
