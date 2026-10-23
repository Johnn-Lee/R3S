#!/bin/sh
set -eu
BASE_URL=https://github.com/Johnn-Lee/R3S/releases/latest/download
KEY_SHA256=b6ef910d5ecb94cfcd7dc82540a2cd59bff0bc13207858ac83a054a726bce856
[ "$#" -gt 0 ] || set -- r3s-monitor usb-fan-control
for name in "$@"; do
    case "$name" in r3s-monitor|usb-fan-control) ;; *) echo 'Unknown package.' >&2; exit 1 ;; esac
done
compatible="$(tr '\0' '\n' </proc/device-tree/compatible 2>/dev/null)"
printf '%s\n' "$compatible" | grep -qx friendlyarm,nanopi-r3s || {
    echo 'These packages support NanoPi R3S only.' >&2; exit 1;
}
tmp="$(mktemp -d /tmp/r3s-packages.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT
trap 'exit 1' HUP INT TERM
if command -v apk >/dev/null 2>&1; then
    for name in "$@"; do wget -O "$tmp/$name.apk" "$BASE_URL/$name.apk"; done
    wget -O "$tmp/r3s.pem" "$BASE_URL/r3s.pem"
    printf '%s  %s\n' "$KEY_SHA256" "$tmp/r3s.pem" | sha256sum -c - >/dev/null
    if [ -f /etc/apk/keys/r3s.pem ]; then
        cmp -s "$tmp/r3s.pem" /etc/apk/keys/r3s.pem || {
            echo 'Existing R3S signing key differs; refusing to replace it.' >&2; exit 1;
        }
    else
        mkdir -p /etc/apk/keys
        cp "$tmp/r3s.pem" /etc/apk/keys/r3s.pem
        chmod 0644 /etc/apk/keys/r3s.pem
    fi
    apk update
    apk add "$tmp/"*.apk
elif command -v opkg >/dev/null 2>&1; then
    for name in "$@"; do wget -O "$tmp/$name.ipk" "$BASE_URL/$name.ipk"; done
    opkg update
    opkg install "$tmp/"*.ipk
else
    echo 'Neither apk nor opkg was found.' >&2; exit 1
fi
