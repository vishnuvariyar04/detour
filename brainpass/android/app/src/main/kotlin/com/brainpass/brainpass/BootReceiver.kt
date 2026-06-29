package com.brainpass.brainpass

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restarts the guard after a reboot or an app update, so gating works without
 * the parent having to open the app first. (On aggressive OEMs this also needs
 * Autostart enabled for the app.)
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON" -> {
                GuardService.start(context)
                WatchdogReceiver.schedule(context)
            }
        }
    }
}
