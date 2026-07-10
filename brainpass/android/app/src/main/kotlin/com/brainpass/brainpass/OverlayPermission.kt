package com.brainpass.brainpass

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings

/**
 * Opens the "Display over other apps" toggle for Nupo — the per-app page, not
 * the giant app list.
 *
 * Since Android 11 the public ACTION_MANAGE_OVERLAY_PERMISSION intent always
 * opens the LIST (the package URI is deliberately ignored), so we first try the
 * AOSP per-app action `android.settings.MANAGE_APP_OVERLAY_PERMISSION`
 * (Settings$AppDrawOverlaySettingsActivity — exported with a package-scheme
 * intent filter; verified to land straight on Nupo's toggle on HyperOS).
 * Falls back to the standard action (per-app on Android 10 and below, the list
 * on 11+), then to the plain list.
 *
 * NOTE: we deliberately use startActivity + try/catch, NOT resolveActivity
 * gating — package-visibility rules can make resolveActivity return null for
 * settings activities that startActivity is perfectly allowed to launch.
 */
object OverlayPermission {
    fun open(ctx: Context) {
        val uri = Uri.parse("package:${ctx.packageName}")
        val attempts = listOf(
            // Per-app page (hidden-but-exported AOSP action).
            Intent("android.settings.MANAGE_APP_OVERLAY_PERMISSION", uri),
            // Public action: per-app pre-11, list on 11+.
            Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, uri),
            // Last resort: the list without a package hint.
            Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION),
        )
        for (intent in attempts) {
            try {
                ctx.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return
            } catch (_: Throwable) {
                // Not available on this device — try the next form.
            }
        }
    }
}
