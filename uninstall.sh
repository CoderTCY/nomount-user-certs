#!/system/bin/sh
export PATH="/data/adb/ksu/bin:/data/adb/ap/bin:/data/adb/magisk:$PATH"
MODDIR=${0%/*}
NM_BIN="/data/adb/modules/nomount/bin/nm"

pkill -f "inotifyd $MODDIR/inotify.sh" 2>/dev/null || true
if [ -x "$NM_BIN" ]; then
    "$NM_BIN" module unload "$MODDIR" >/dev/null 2>&1 || true
fi
