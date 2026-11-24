#!/system/bin/sh
MODDIR=${0%/*}
sleep 1
exec "$MODDIR/sync.sh" --live
