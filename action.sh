#!/system/bin/sh
export PATH="/data/adb/ksu/bin:/data/adb/ap/bin:/data/adb/magisk:$PATH"
MODDIR=${0%/*}
NM_BIN="/data/adb/modules/nomount/bin/nm"

"$MODDIR/sync.sh" --live
echo "=== Synced Certs ==="
ls -1 "$MODDIR/apex/com.android.conscrypt/cacerts" 2>/dev/null || echo "(none)"
echo "=== Active NoMount CA Rules ==="
"$NM_BIN" rule list 2>/dev/null | grep "cacerts" || echo "(none)"
