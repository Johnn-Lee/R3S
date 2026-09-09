#!/bin/sh

PORT=54188
NAME="NanoPi R3S Web 监控"
BASE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
BACKUP="/tmp/r3s-monitor-backup.$$"
PROJECT_TARGETS="/etc/init.d/r3s-monitor /usr/bin/monitor-collector.sh /www/monitor/index.html /www/monitor/data.json"
ROLLBACK_READY=0
WAS_RUNNING=0
WAS_ENABLED=0

say() {
    printf '%s\n' "$*"
}

rollback() {
    [ "$ROLLBACK_READY" = "1" ] || return
    if [ -x /etc/init.d/r3s-monitor ]; then
        /etc/init.d/r3s-monitor stop >/dev/null 2>&1
        /etc/init.d/r3s-monitor disable >/dev/null 2>&1
    fi
    for path in $PROJECT_TARGETS; do
        rm -f "$path"
    done
    [ -d "$BACKUP/root" ] && cp -a "$BACKUP/root/." / >/dev/null 2>&1
    [ -x /etc/init.d/uhttpd ] && /etc/init.d/uhttpd restart >/dev/null 2>&1
    if [ "$WAS_ENABLED" = "1" ] && [ -x /etc/init.d/r3s-monitor ]; then
        /etc/init.d/r3s-monitor enable >/dev/null 2>&1
    fi
    if [ "$WAS_RUNNING" = "1" ] && [ -x /etc/init.d/r3s-monitor ]; then
        /etc/init.d/r3s-monitor start >/dev/null 2>&1
    fi
    rm -rf "$BACKUP"
}

die() {
    say "错误：$*" >&2
    rollback
    exit 1
}

need() {
    command -v "$1" >/dev/null 2>&1 || die "缺少命令 $1"
}

[ "$(id -u)" = "0" ] || die "请使用 root 用户运行安装器"
[ -n "$BASE_DIR" ] && [ -d "$BASE_DIR/files" ] || die "安装文件不完整"

compatible="$(tr '\0' '\n' </proc/device-tree/compatible 2>/dev/null)"
printf '%s\n' "$compatible" | grep -qx 'friendlyarm,nanopi-r3s' || die "此安装包仅支持 NanoPi R3S"

for cmd in uhttpd uci ubus jsonfilter ip wget netstat awk grep sed mv ln; do
    need "$cmd"
done

cpu_zone=""
for zone in /sys/class/thermal/thermal_zone*; do
    [ "$(cat "$zone/type" 2>/dev/null)" = "cpu-thermal" ] || continue
    cpu_zone="$zone"
    break
done
if [ -z "$cpu_zone" ] && [ ! -r /sys/class/hwmon/hwmon0/temp1_input ]; then
    die "未找到 CPU 温度接口"
fi

lan_ip="$(ubus call network.interface.lan status 2>/dev/null | jsonfilter -e '@["ipv4-address"][0].address')"
[ -n "$lan_ip" ] || lan_ip="$(uci -q get network.lan.ipaddr)"
[ -n "$lan_ip" ] || die "无法读取 LAN IPv4 地址"

mkdir -p "$BACKUP/root" || die "无法创建临时备份"
for path in $PROJECT_TARGETS /etc/config/uhttpd; do
    if [ -e "$path" ] || [ -L "$path" ]; then
        relative="${path#/}"
        mkdir -p "$BACKUP/root/$(dirname "$relative")" || die "创建备份目录失败"
        cp -a "$path" "$BACKUP/root/$relative" || die "备份 $path 失败"
    fi
done

[ -e /etc/rc.d/S99r3s-monitor ] && WAS_ENABLED=1
if [ -x /etc/init.d/r3s-monitor ]; then
    running="$(ubus call service list '{"name":"r3s-monitor"}' 2>/dev/null | jsonfilter -e '@["r3s-monitor"].instances.collector.running')"
    [ "$running" = "true" ] || running="$(ubus call service list '{"name":"r3s-monitor"}' 2>/dev/null | jsonfilter -e '@["r3s-monitor"].instances.instance1.running')"
    [ "$running" = "true" ] && WAS_RUNNING=1
fi
ROLLBACK_READY=1

if [ -x /etc/init.d/r3s-monitor ]; then
    /etc/init.d/r3s-monitor stop >/dev/null 2>&1 || die "无法停止旧版监控服务"
fi

if uci -q get uhttpd.monitor >/dev/null 2>&1; then
    uci -q delete uhttpd.monitor
    uci -q commit uhttpd || die "无法清理旧版 uhttpd 配置"
    /etc/init.d/uhttpd restart >/dev/null 2>&1 || die "无法重载 uhttpd"
    sleep 1
fi

if netstat -lnt 2>/dev/null | awk -v port=":$PORT" '$4 ~ port"$" { found=1 } END { exit !found }'; then
    die "端口 $PORT 已被其他服务占用"
fi

for path in /etc/init.d/r3s-monitor /usr/bin/monitor-collector.sh /www/monitor/index.html; do
    source="$BASE_DIR/files$path"
    [ -f "$source" ] || die "缺少安装文件 $source"
    mkdir -p "$(dirname "$path")" || die "无法创建目标目录"
    cp "$source" "$path" || die "安装 $path 失败"
done

chmod 755 /etc/init.d/r3s-monitor /usr/bin/monitor-collector.sh || die "设置执行权限失败"
chmod 644 /www/monitor/index.html || die "设置页面权限失败"
mkdir -p /tmp/r3s-monitor
ln -sfn /tmp/r3s-monitor/data.json /www/monitor/data.json || die "创建运行数据链接失败"

/etc/init.d/r3s-monitor enable || die "设置开机启动失败"
/etc/init.d/r3s-monitor start || die "启动监控服务失败"
sleep 4

netstat -lnt 2>/dev/null | awk -v addr="$lan_ip:$PORT" '$4 == addr { found=1 } END { exit !found }' || die "Web 服务未监听 LAN 地址"
data="$(wget -qO- "http://$lan_ip:$PORT/data.json" 2>/dev/null)"
printf '%s\n' "$data" | grep -q '"cpu":' || die "CPU 数据自检失败"
printf '%s\n' "$data" | grep -q '"mem":' || die "内存数据自检失败"
printf '%s\n' "$data" | grep -q '"temp":' || die "温度数据自检失败"
printf '%s\n' "$data" | grep -q '"rx":' || die "网络数据自检失败"

ROLLBACK_READY=0
rm -rf "$BACKUP"
say "$NAME 安装成功。"
say "访问地址：http://$lan_ip:$PORT/"
exit 0
