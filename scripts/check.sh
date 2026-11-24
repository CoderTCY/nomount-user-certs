#!/bin/sh
set -eu

PYTHON=$(command -v python3 || command -v python || true)
if [ -z "$PYTHON" ]; then
    echo "ERROR: python3 or python is required" >&2
    exit 1
fi

"$PYTHON" - <<'PYEOF'
import json

lf_files = [
    "sync.sh",
    "post-fs-data.sh",
    "service.sh",
    "inotify.sh",
    "action.sh",
    "uninstall.sh",
    "customize.sh",
    "scripts/check.sh",
    "scripts/package.sh",
    "META-INF/com/google/android/update-binary",
    "META-INF/com/google/android/updater-script",
    "module.prop",
]

for path in lf_files:
    with open(path, "rb") as f:
        data = f.read()
    assert b"\r" not in data, f"CRLF found in {path}"
    assert not data.startswith(b"\xef\xbb\xbf"), f"UTF-8 BOM found in {path}"

props = {}
with open("module.prop", "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if "=" in line and not line.startswith("#"):
            k, v = line.split("=", 1)
            props[k.strip()] = v.strip()

with open("update.json", "r", encoding="utf-8") as f:
    upd = json.load(f)

assert isinstance(upd.get("versionCode"), int), "update.json versionCode must be an integer"
assert str(upd["versionCode"]) == props.get("versionCode"), (
    f"versionCode mismatch: update.json={upd['versionCode']} vs module.prop={props.get('versionCode')}"
)
assert upd.get("version") == props.get("version"), (
    f"version mismatch: update.json={upd.get('version')} vs module.prop={props.get('version')}"
)
print(f"Metadata & LF/BOM checks OK: version={props['version']} versionCode={props['versionCode']}")
PYEOF

for f in sync.sh post-fs-data.sh service.sh inotify.sh action.sh uninstall.sh customize.sh scripts/check.sh scripts/package.sh META-INF/com/google/android/update-binary; do
    sh -n "$f"
done
echo "sh -n syntax check OK"

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -s sh -e SC1091,SC2034 \
        sync.sh post-fs-data.sh service.sh inotify.sh action.sh uninstall.sh customize.sh \
        scripts/check.sh scripts/package.sh META-INF/com/google/android/update-binary
    echo "shellcheck OK"
else
    echo "shellcheck not installed locally; skipping shellcheck"
fi
