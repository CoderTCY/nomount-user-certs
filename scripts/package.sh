#!/bin/sh
set -eu

PYTHON=$(command -v python3 || command -v python || true)
if [ -z "$PYTHON" ]; then
    echo "ERROR: python3 or python is required" >&2
    exit 1
fi

VERSION="${1:-}"
"$PYTHON" - "$VERSION" <<'PYEOF'
import hashlib
import os
import sys
import zipfile

version = sys.argv[1].strip()
if not version:
    with open("module.prop", "r", encoding="utf-8") as f:
        for line in f:
            if line.startswith("version="):
                version = line.split("=", 1)[1].strip()
                break
if not version:
    raise SystemExit("ERROR: could not determine module version")

os.makedirs("dist", exist_ok=True)
zip_name = f"nomount-user-certs-{version}.zip"
zip_path = os.path.join("dist", zip_name)

files = [
    "META-INF/com/google/android/update-binary",
    "META-INF/com/google/android/updater-script",
    "customize.sh",
    "module.prop",
    "sync.sh",
    "post-fs-data.sh",
    "service.sh",
    "inotify.sh",
    "action.sh",
    "uninstall.sh",
    "extra_certs/.gitkeep",
    "LICENSE",
    "README.md",
]

with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for rel in files:
        with open(rel, "rb") as f:
            data = f.read()
        if rel.endswith(".sh") or rel.endswith("update-binary") or rel.endswith("updater-script") or rel == "module.prop":
            assert b"\r" not in data, f"CRLF found in {rel}"
            assert not data.startswith(b"\xef\xbb\xbf"), f"BOM found in {rel}"
        zi = zipfile.ZipInfo(rel)
        zi.date_time = (2026, 11, 24, 0, 0, 0)
        zi.create_system = 3
        mode = 0o100755 if (rel.endswith(".sh") or rel.endswith("update-binary")) else 0o100644
        zi.external_attr = mode << 16
        zf.writestr(zi, data)

with open(zip_path, "rb") as f:
    digest = hashlib.sha256(f.read()).hexdigest()

sha_path = zip_path + ".sha256"
with open(sha_path, "w", encoding="utf-8", newline="\n") as f:
    f.write(f"{digest}  {zip_name}\n")

print(f"Built {zip_path} ({os.path.getsize(zip_path)} bytes)")
print(f"SHA256: {digest}")
PYEOF
