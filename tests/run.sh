#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
python3 scripts/generate-hooks.py --check
python3 tests/check-function-preservation.py
python3 tests/check-hooks.py
sh tests/installer.sh
for file in */install.sh */uninstall.sh */files/etc/init.d/* */files/usr/bin/*.sh */files/usr/libexec/* usb-fan-control/files/www/usb-power/cgi-bin/api; do
    [ ! -f "$file" ] || sh -n "$file"
done
python3 - <<'PY'
from pathlib import Path
import re,subprocess
for path in Path('.').glob('*/files/www/*/index.html'):
    for script in re.findall(r'<script>(.*?)</script>',path.read_text(),re.S):
        subprocess.run(['node','--check'],input=script.encode(),check=True)
PY
