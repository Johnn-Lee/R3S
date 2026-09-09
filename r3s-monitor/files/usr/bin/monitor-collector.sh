#!/bin/sh

OUT_DIR=/tmp/r3s-monitor
OUT="$OUT_DIR/data.json"
TMP="$OUT_DIR/data.json.tmp"
mkdir -p "$OUT_DIR"

WAN_IF="$(ip -4 route show default 2>/dev/null | sed -n 's/.* dev \([^ ]*\) .*/\1/p' | head -n 1)"
[ -n "$WAN_IF" ] || WAN_IF="eth0"

TEMP_PATH=""
for zone in /sys/class/thermal/thermal_zone*; do
    [ "$(cat "$zone/type" 2>/dev/null)" = "cpu-thermal" ] || continue
    TEMP_PATH="$zone/temp"
    break
done
[ -n "$TEMP_PATH" ] || TEMP_PATH=/sys/class/hwmon/hwmon0/temp1_input

cpu_stat() { awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat; }
net_stat() { awk -v i="$WAN_IF:" '$1==i{print $2, $10}' /proc/net/dev; }

set -- $(cpu_stat); PT=$1; PI=$2
set -- $(net_stat); PRX=${1:-0}; PTX=${2:-0}

while :; do
    sleep 2
    set -- $(cpu_stat); CT=$1; CI=$2
    set -- $(net_stat); CRX=${1:-0}; CTX=${2:-0}

    DT=$((CT - PT)); [ "$DT" -le 0 ] && DT=1
    CPU=$(awk -v t="$DT" -v idle=$((CI - PI)) 'BEGIN{c=(t-idle)*100/t; if(c<0)c=0; if(c>100)c=100; printf "%.2f", c}')

    RX=$(( (CRX - PRX) / 2 )); [ "$RX" -lt 0 ] && RX=0
    TX=$(( (CTX - PTX) / 2 )); [ "$TX" -lt 0 ] && TX=0

    MEMT=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
    MEMA=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
    [ "$MEMT" -gt 0 ] && MEM=$(( (MEMT - MEMA) * 100 / MEMT )) || MEM=0

    TEMP=$(cat "$TEMP_PATH" 2>/dev/null || echo 0)

    printf '{"cpu":%s,"mem":%d,"temp":%.1f,"rx":%d,"tx":%d,"wan":"%s","ts":%s}\n' \
        "$CPU" "$MEM" "$((TEMP))e-3" "$RX" "$TX" "$WAN_IF" "$(date +%s)" > "$TMP"
    mv "$TMP" "$OUT"

    PT=$CT; PI=$CI; PRX=$CRX; PTX=$CTX
done
