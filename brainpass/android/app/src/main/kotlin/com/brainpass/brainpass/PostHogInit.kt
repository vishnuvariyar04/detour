package com.brainpass.brainpass

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri

/**
 * Starts PostHog once per process, before any Activity or Service runs.
 *
 * A ContentProvider's onCreate runs at process start: the same way Firebase
 * starts itself. That matters because the guard can be started at boot by
 * BootReceiver or by the watchdog, with no Flutter engine and no
 * MainActivity. With PostHog started here, the parent app (through
 * posthog_flutter, whose own AUTO_INIT is off) and the guard (through
 * Analytics.kt) share one SDK instance, and so one distinct id.
 *
 * It provides no data; every query method is a stub.
 */
class PostHogInit : ContentProvider() {
    override fun onCreate(): Boolean {
        context?.let { Analytics.startPostHog(it) }
        return true
    }

    override fun query(u: Uri, p: Array<out String>?, s: String?, a: Array<out String>?, o: String?): Cursor? = null
    override fun getType(u: Uri): String? = null
    override fun insert(u: Uri, v: ContentValues?): Uri? = null
    override fun delete(u: Uri, s: String?, a: Array<out String>?): Int = 0
    override fun update(u: Uri, v: ContentValues?, s: String?, a: Array<out String>?): Int = 0
}
