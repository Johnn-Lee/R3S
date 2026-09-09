#!/bin/sh

PORT=54188

say() {
    printf '%s\n' "$*"
}

[ "$(id -u)" = "0" ] || {
    say "错误：请使用 root 用户运行卸载器" >&2
    exit 1
}

if [ -x /etc/init.d/r3s-monitor ]; then
    /etc/init.d/r3s-monitor stop >/dev/null 2>&1
    /etc/init.d/r3s-monitor disable >/dev/null 2>&1
fi

if command -v uci >/dev/null 2>&1 && uci -q get uhttpd.monitor >/dev/null 2>&1; then
    uci -q delete uhttpd.monitor
    uci -q commit uhttpd
    [ -x /etc/init.d/uhttpd ] && /etc/init.d/uhttpd restart >/dev/null 2>&1
fi

rm -f /etc/init.d/r3s-monitor /usr/bin/monitor-collector.sh
rm -rf /www/monitor /tmp/r3s-monitor

say "NanoPi R3S Web 监控已卸载。"
say "端口 $PORT 已释放。"
