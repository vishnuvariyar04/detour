package com.brainpass.brainpass

import android.app.Activity
import android.os.Bundle

/**
 * Debug builds only: the real lesson (CoderGate) in a plain Activity, so its
 * look can be checked without the guard, the overlay permission, or a gated
 * app. Progress lives in this install's own prefs.
 *
 *   adb shell am start -n <pkg>/com.brainpass.brainpass.GatePreviewActivity \
 *     --es band d --ei stop 3
 */
class GatePreviewActivity : Activity() {
    private var gate: GateUi? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent.getStringExtra("band")?.let { EnginePrefs.setAgeBand(this, it) }
        val skill = Curriculum.skillFor(this) ?: return finish()
        if (intent.hasExtra("stop")) {
            // Start fresh at that stop (index into the skill's ladder).
            getSharedPreferences("nupo_progress", MODE_PRIVATE).edit().clear()
                .putInt("stopIndex__${skill.id}", intent.getIntExtra("stop", 0))
                .commit()
        }
        val session = Curriculum.session(this, 3)
        val ui = CoderGate(this, 15, session, skill, { finish() }, { finish() })
        gate = ui
        // The guard's overlay sits below the status bar; an Activity on a
        // recent Android is edge to edge, so pad for the bars here.
        val frame = android.widget.FrameLayout(this)
        frame.addView(ui.root)
        frame.setOnApplyWindowInsetsListener { v, insets ->
            val bars = insets.getInsets(android.view.WindowInsets.Type.systemBars())
            v.setPadding(0, bars.top, 0, bars.bottom)
            insets
        }
        setContentView(frame)
    }

    override fun onDestroy() {
        gate?.release()
        super.onDestroy()
    }
}
