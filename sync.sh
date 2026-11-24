#!/system/bin/sh
export PATH="/data/adb/ksu/bin:/data/adb/ap/bin:/data/adb/magisk:$PATH"

MODDIR=${0%/*}
[ "$MODDIR" = "$0" ] && MODDIR="."
MODDIR=$(CDPATH= cd -- "$MODDIR" && pwd)

NM_BIN="/data/adb/modules/nomount/bin/nm"
USER_CERTS_DIR="/data/misc/user/0/cacerts-added"
EXTRA_CERTS_DIR="$MODDIR/extra_certs"
SYS_DST="$MODDIR/system/etc/security/cacerts"
APEX_DST="$MODDIR/apex/com.android.conscrypt/cacerts"
LOG_FILE="$MODDIR/sync.log"
LOCK_DIR="$MODDIR/.sync.lock"
PROP_FILE="$MODDIR/module.prop"

MODE="live"
case "${1:-}" in
    --stage-only) MODE="stage" ;;
    --live|"") MODE="live" ;;
    *)
        echo "Usage: $0 [--live|--stage-only]" >&2
        exit 1
        ;;
esac

log_msg() {
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$MODE" "$1" >> "$LOG_FILE"
    if [ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)" -gt 300 ]; then
        tail -n 200 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}

update_desc() {
    desc="$1"
    if [ -x /data/adb/ksud ]; then
        KSU_MODULE="nomount_user_certs" MODULE_ID="nomount_user_certs" /data/adb/ksud module config set override.description "$desc" >/dev/null 2>&1 && return 0
    fi
    sed -i "s|^description=.*|description=$desc|" "$PROP_FILE" 2>/dev/null || true
}

acquire_lock() {
    waited=0
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        if [ -f "$LOCK_DIR/pid" ]; then
            holder=$(cat "$LOCK_DIR/pid" 2>/dev/null)
            if [ -n "$holder" ] && ! kill -0 "$holder" 2>/dev/null; then
                rm -rf "$LOCK_DIR" 2>/dev/null
                continue
            fi
        fi
        waited=$((waited + 1))
        if [ "$waited" -ge 15 ]; then
            log_msg "WARN: lock timeout after 15s, forcing cleanup"
            rm -rf "$LOCK_DIR" 2>/dev/null
            mkdir "$LOCK_DIR" 2>/dev/null || return 1
            break
        fi
        sleep 1
    done
    echo "$$" > "$LOCK_DIR/pid"
}

release_lock() {
    rm -rf "$LOCK_DIR" 2>/dev/null || true
}

trap release_lock EXIT INT TERM
acquire_lock || { log_msg "ERROR: failed to acquire lock"; exit 1; }

nm_ready=0
if [ "$MODE" = "live" ] && [ -x "$NM_BIN" ] && "$NM_BIN" version >/dev/null 2>&1; then
    nm_ready=1
    "$NM_BIN" module unload "$MODDIR" >/dev/null 2>&1 || true
fi

rm -rf "$MODDIR/system" "$MODDIR/apex"

count=0
for src_dir in "$USER_CERTS_DIR" "$EXTRA_CERTS_DIR"; do
    [ -d "$src_dir" ] || continue
    for f in "$src_dir"/*; do
        [ -f "$f" ] && [ -s "$f" ] || continue
        if [ "$count" -eq 0 ]; then
            mkdir -p "$SYS_DST" "$APEX_DST"
        fi
        base="${f##*/}"
        cp -f "$f" "$SYS_DST/$base"
        cp -f "$f" "$APEX_DST/$base"
        count=$((count + 1))
    done
done

if [ "$count" -gt 0 ]; then
    chown -R 0:0 "$MODDIR/system" "$MODDIR/apex"
    chmod 0755 "$MODDIR/system" "$MODDIR/system/etc" "$MODDIR/system/etc/security" "$SYS_DST" \
               "$MODDIR/apex" "$MODDIR/apex/com.android.conscrypt" "$APEX_DST"
    chmod 0644 "$SYS_DST"/* "$APEX_DST"/*
    chcon u:object_r:system_file:s0 \
        "$MODDIR/system" "$MODDIR/system/etc" "$MODDIR/system/etc/security" \
        "$MODDIR/apex" "$MODDIR/apex/com.android.conscrypt" 2>/dev/null || true
    chcon u:object_r:system_security_cacerts_file:s0 \
        "$SYS_DST" "$APEX_DST" "$SYS_DST"/* "$APEX_DST"/* 2>/dev/null || true
fi

if [ "$MODE" = "stage" ]; then
    log_msg "Staged $count user CA cert(s)"
    exit 0
fi

if [ "$nm_ready" -eq 1 ]; then
    if [ "$count" -gt 0 ]; then
        if load_out=$("$NM_BIN" module load "$MODDIR" 2>&1); then
            log_msg "Loaded $count user CA cert(s) into system + apex via NoMount"
            update_desc "🟢 Synced $count user CA cert(s) via NoMount (no tmpfs)"
        else
            log_msg "ERROR: nm module load failed: $load_out"
            update_desc "🔴 Failed to load certs via NoMount"
            exit 1
        fi
    else
        log_msg "No user CA certs found (0 active)"
        update_desc "🟡 No user CA certs to sync (0 active)"
    fi
else
    log_msg "Staged $count user CA cert(s), NoMount LKM not active"
    update_desc "🟡 Staged $count user CA cert(s) (NoMount inactive)"
fi

exit 0
