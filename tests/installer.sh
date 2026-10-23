#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin" "$tmp/keys"
printf 'friendlyarm,nanopi-r3s\000' > "$tmp/compatible"
sed "s|/proc/device-tree/compatible|$tmp/compatible|;s|/etc/apk/keys|$tmp/keys|g" "$ROOT/install-packages.sh" > "$tmp/install"
export TEST_ROOT="$ROOT" TEST_LOG="$tmp/calls"
cat > "$tmp/bin/wget" <<'SH'
#!/bin/sh
if [ "${TEST_BAD_KEY:-0}" = 1 ] && [ "${3##*/}" = r3s.pem ]; then printf wrong > "$2"; exit; fi
case "$3" in *.pem) cp "$TEST_ROOT/keys/r3s.pem" "$2" ;; *) printf package > "$2" ;; esac
SH
for cmd in apk opkg; do
    cat > "$tmp/bin/$cmd" <<'SH'
#!/bin/sh
printf '%s' "${0##*/}" >> "$TEST_LOG"
printf ' <%s>' "$@" >> "$TEST_LOG"
printf '\n' >> "$TEST_LOG"
exit 0
SH
done
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH"
sh "$tmp/install" >/dev/null 2>&1
grep -q 'apk <update>' "$TEST_LOG"
grep -q 'r3s-monitor.apk.*usb-fan-control.apk' "$TEST_LOG"
! grep -q allow-untrusted "$TEST_LOG"
cmp "$tmp/keys/r3s.pem" "$ROOT/keys/r3s.pem"
rm "$TEST_LOG"
if TEST_BAD_KEY=1 sh "$tmp/install" >/dev/null 2>&1; then exit 1; fi
[ ! -e "$TEST_LOG" ]
printf other-device > "$tmp/compatible"
if sh "$tmp/install" >/dev/null 2>&1; then exit 1; fi
[ ! -e "$TEST_LOG" ]
printf 'friendlyarm,nanopi-r3s\000' > "$tmp/compatible"
mv "$tmp/bin/apk" "$tmp/bin/apk.disabled"
sh "$tmp/install" r3s-monitor >/dev/null 2>&1
grep -q 'r3s-monitor.ipk' "$TEST_LOG"
! grep -q 'usb-fan-control.ipk' "$TEST_LOG"
echo 'Installer passed: device gate, pinned public key, strict APK path and individual package selection.'
