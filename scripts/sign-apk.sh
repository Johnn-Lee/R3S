#!/usr/bin/env bash
set -euo pipefail

apk="$1"
package="$2"
private="$3"
public="$4"
test -s "$private"
openssl pkey -in "$private" -pubout 2>/dev/null | cmp - "$public"
# The input from mkpkg is unsigned; trust bypass is limited to the signing tool.
"$apk" adbsign --allow-untrusted --sign-key "$private" "$package"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/trusted" "$tmp/empty" "$tmp/wrong"
cp "$public" "$tmp/trusted/r3s.pem"

"$apk" --keys-dir "$tmp/trusted" verify "$package"
if "$apk" --keys-dir "$tmp/empty" verify "$package"; then
    echo 'Unsigned trust store unexpectedly accepted the package.' >&2
    exit 1
fi
openssl ecparam -name prime256v1 -genkey -noout -out "$tmp/wrong-key.pem"
openssl pkey -in "$tmp/wrong-key.pem" -pubout > "$tmp/wrong/wrong.pem"
if "$apk" --keys-dir "$tmp/wrong" verify "$package"; then
    echo 'Wrong public key unexpectedly accepted the package.' >&2
    exit 1
fi

cp "$package" "$tmp/tampered.apk"
python3 - "$tmp/tampered.apk" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
data = bytearray(p.read_bytes())
data[-8] ^= 0x80
p.write_bytes(data)
PY
if "$apk" --keys-dir "$tmp/trusted" verify "$tmp/tampered.apk"; then
    echo 'Tampered package unexpectedly passed verification.' >&2
    exit 1
fi
echo 'Signature checks passed: trusted key accepted; empty/wrong keys and tampering rejected.'
