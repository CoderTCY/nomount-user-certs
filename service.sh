#!/system/bin/sh
export PATH="/data/adb/ksu/bin:/data/adb/ap/bin:/data/adb/magisk:$PATH"

MODDIR=${0%/*}
[ "$MODDIR" = "$0" ] && MODDIR="."
MODDIR=$(CDPATH= cd -- "$MODDIR" && pwd)

USER_CERTS_DIR="/data/misc/user/0/cacerts-added"

waited=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$waited" -lt 60 ]; do
    sleep 1
    waited=$((waited + 1))
done

"$MODDIR/sync.sh" --live

mkdir -p "$USER_CERTS_DIR"

pkill -f "inotifyd $MODDIR/inotify.sh" 2>/dev/null || true
if [ -x /data/adb/ksu/bin/busybox ]; then
    nohup /data/adb/ksu/bin/busybox inotifyd "$MODDIR/inotify.sh" "$USER_CERTS_DIR:n,w,d,m,y" </dev/null >/dev/null 2>&1 &
else
    nohup inotifyd "$MODDIR/inotify.sh" "$USER_CERTS_DIR:n,w,d,m,y" </dev/null >/dev/null 2>&1 &
fi
