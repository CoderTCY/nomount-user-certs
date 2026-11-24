#!/system/bin/sh
SKIPUNZIP=0

ui_print "- Installing NoMount User Certs Sync..."

if [ ! -x /data/adb/modules/nomount/bin/nm ]; then
  ui_print "! Warning: NoMount metamodule (/data/adb/modules/nomount/bin/nm) was not detected."
  ui_print "! Please make sure the NoMount metamodule is installed and enabled."
fi

set_perm_recursive "$MODPATH" 0 0 0755 0644
for s in sync.sh post-fs-data.sh service.sh inotify.sh action.sh uninstall.sh; do
  [ -f "$MODPATH/$s" ] && set_perm "$MODPATH/$s" 0 0 0755
done

ui_print "- User CA certs in /data/misc/user/0/cacerts-added will be mirrored"
ui_print "  automatically on boot and live via inotifyd."
ui_print "- You can also tap Action in KernelSU Manager to sync immediately."
