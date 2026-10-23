#!/usr/bin/env bash
set -euo pipefail
era="$1"
dist="$2"
host_apk="$3"
version=24.10.8
[ "$era" != apk ] || version=25.12.5
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
wget -q "https://downloads.openwrt.org/releases/$version/targets/x86/64/openwrt-$version-x86-64-rootfs.tar.gz" -O "$tmp/root.tar.gz"
mkdir -p "$tmp/root" "$tmp/keys"
tar -xzf "$tmp/root.tar.gz" -C "$tmp/root"
root="$tmp/root"
python3 scripts/fetch-test-dependencies.py "$era" "$version" "$tmp/repos" "$host_apk"
loader="$root/lib/ld-musl-x86_64.so.1"
if [ "$era" = apk ]; then
    cp "$root"/etc/apk/keys/* "$tmp/keys/"
    cp keys/r3s.pem "$tmp/keys/r3s.pem"
    "$loader" --library-path "$root/lib:$root/usr/lib" "$root/usr/bin/apk" \
        --root "$root" --keys-dir "$tmp/keys" --repositories-file /dev/null --network=no --scripts=no \
        --repository "file://$tmp/repos/base/packages.adb" --repository "file://$tmp/repos/packages/packages.adb" \
        add --usermode "$dist/r3s-monitor.apk" "$dist/usb-fan-control.apk"
else
    mkdir -p "$root/tmp/lock"
    "$loader" --library-path "$root/lib:$root/usr/lib" "$root/bin/opkg" \
        --conf "$root/etc/opkg.conf" --offline-root "$root" install \
        "$tmp"/repos/*/*.ipk "$dist/r3s-monitor.ipk" "$dist/usb-fan-control.ipk"
fi
for name in r3s-monitor usb-fan-control; do
    while IFS= read -r source; do
        relative="${source#"$name/files/"}"
        cmp "$source" "$root/$relative"
    done < <(find "$name/files" -type f)
    test -x "$root/usr/libexec/$name-package-install"
done
test -x "$root/etc/init.d/r3s-monitor"
test -x "$root/etc/init.d/usb-power"
test -x "$root/www/usb-power/cgi-bin/api"
echo 'Both packages installed with real dependencies, normal signature checks and byte-identical payloads (hardware hooks disabled/deferred).'
