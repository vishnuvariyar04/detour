#!/bin/bash
# Puts the learning ladder back to the very first stop.
#
# The gate keeps its own progress in nupo_progress.xml, separate from anything
# the Flutter app stores. Deleting it starts Think Like a Coder from stop 1.1.1.
# The earned minutes are cleared too, otherwise the gate will not fire until the
# child's current unlock runs out.
set -e
ADB="${ADB:-$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe}"
PKG=app.nupo.kid

"$ADB" shell am force-stop "$PKG"
"$ADB" shell "run-as $PKG rm -f /data/data/$PKG/shared_prefs/nupo_progress.xml"
"$ADB" shell "run-as $PKG sed -i '/rem_/d;/used_/d' /data/data/$PKG/shared_prefs/brainpass_engine.xml"

# HyperOS drops "draw over other apps" on every reinstall, and without it the
# gate silently never appears.
"$ADB" shell appops set "$PKG" SYSTEM_ALERT_WINDOW allow
"$ADB" shell appops set "$PKG" GET_USAGE_STATS allow

"$ADB" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
echo "Progress cleared. Open a gated app and the gate starts at stop 1.1.1."
