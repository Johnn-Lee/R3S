#!/bin/sh

PORT=54199
NAME="NanoPi R3S USB 风扇温控"
BASE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
BACKUP="/tmp/usb-fan-control-backup.$$"
TARGETS="/etc/init.d/usb-power /etc/config/usbpower /usr/libexec/usb-power-control /usr/libexec/usb-power-thermal /usr/libexec/usb-power-scheduler /www/usb-power/index.html /www/usb-power/cgi-bin/api"
ROLLBACK_READY=0
WAS_RUNNING=0
WAS_ENABLED=0

say() {
	printf '%s\n' "$*"
}

rollback() {
	[ "$ROLLBACK_READY" = "1" ] || return
	if [ -x /etc/init.d/usb-power ]; then
		/etc/init.d/usb-power stop >/dev/null 2>&1
		/etc/init.d/usb-power disable >/dev/null 2>&1
	fi
	for path in $TARGETS; do
		rm -f "$path"
	done
	[ -d "$BACKUP/root" ] && cp -a "$BACKUP/root/." / >/dev/null 2>&1
	if [ "$WAS_ENABLED" = "1" ] && [ -x /etc/init.d/usb-power ]; then
		/etc/init.d/usb-power enable >/dev/null 2>&1
	fi
	if [ "$WAS_RUNNING" = "1" ] && [ -x /etc/init.d/usb-power ]; then
		/etc/init.d/usb-power start >/dev/null 2>&1
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

for cmd in uhttpd uci ubus jsonfilter gpioset wget netstat awk grep sed dd pidof; do
	need "$cmd"
done

[ -c /dev/gpiochip0 ] || die "未找到 /dev/gpiochip0"
[ -r /sys/kernel/debug/gpio ] || die "无法读取 GPIO 调试接口"
gpio_line="$(grep 'gpio-6 ' /sys/kernel/debug/gpio 2>/dev/null | head -n 1)"
case "$gpio_line" in
	*regulator-vcc5v0_usb*|*usb-power-control*) ;;
	*) die "GPIO0_A6 与 NanoPi R3S USB 供电线路不匹配" ;;
esac

[ -e /sys/bus/platform/drivers/reg-fixed-voltage/unbind ] || die "缺少固定稳压器驱动控制接口"
[ -e /sys/bus/platform/drivers/reg-fixed-voltage/bind ] || die "缺少固定稳压器恢复接口"

cpu_zone=""
for zone in /sys/class/thermal/thermal_zone*; do
	[ "$(cat "$zone/type" 2>/dev/null)" = "cpu-thermal" ] || continue
	cpu_zone="$zone"
	break
done
[ -n "$cpu_zone" ] && [ -r "$cpu_zone/temp" ] || die "未找到 cpu-thermal 温度接口"

lan_ip="$(ubus call network.interface.lan status 2>/dev/null | jsonfilter -e '@["ipv4-address"][0].address')"
[ -n "$lan_ip" ] || lan_ip="$(uci -q get network.lan.ipaddr)"
[ -n "$lan_ip" ] || die "无法读取 LAN IPv4 地址"

mkdir -p "$BACKUP/root" || die "无法创建临时备份"
for path in $TARGETS; do
	if [ -f "$path" ]; then
		relative="${path#/}"
		mkdir -p "$BACKUP/root/$(dirname "$relative")" || die "创建备份目录失败"
		cp -p "$path" "$BACKUP/root/$relative" || die "备份 $path 失败"
	fi
done

[ -e /etc/rc.d/S99usb-power ] && WAS_ENABLED=1
if [ -x /etc/init.d/usb-power ]; then
	running="$(ubus call service list '{"name":"usb-power"}' 2>/dev/null | jsonfilter -e '@["usb-power"].instances.web.running')"
	[ "$running" = "true" ] && WAS_RUNNING=1
fi
ROLLBACK_READY=1

if [ -x /etc/init.d/usb-power ]; then
	/etc/init.d/usb-power stop >/dev/null 2>&1 || die "无法停止旧版服务"
	sleep 1
fi

if netstat -lnt 2>/dev/null | awk -v port=":$PORT" '$4 ~ port"$" { found=1 } END { exit !found }'; then
	die "端口 $PORT 已被其他服务占用"
fi

for path in /etc/init.d/usb-power /usr/libexec/usb-power-control /usr/libexec/usb-power-thermal /www/usb-power/index.html /www/usb-power/cgi-bin/api; do
	source="$BASE_DIR/files$path"
	[ -f "$source" ] || die "缺少安装文件 $source"
	mkdir -p "$(dirname "$path")" || die "无法创建目标目录"
	cp "$source" "$path" || die "安装 $path 失败"
done

if [ ! -f /etc/config/usbpower ]; then
	cp "$BASE_DIR/files/etc/config/usbpower" /etc/config/usbpower || die "安装配置失败"
fi

chmod 755 /etc/init.d/usb-power /usr/libexec/usb-power-control /usr/libexec/usb-power-thermal /www/usb-power/cgi-bin/api || die "设置执行权限失败"
chmod 644 /etc/config/usbpower /www/usb-power/index.html || die "设置文件权限失败"
rm -f /usr/libexec/usb-power-scheduler

enabled="$(uci -q get usbpower.main.enabled)"
state="$(uci -q get usbpower.main.state)"
temperature="$(uci -q get usbpower.main.temperature)"
hysteresis="$(uci -q get usbpower.main.hysteresis)"

[ "$enabled" = "0" ] || [ "$enabled" = "1" ] || enabled=0
[ "$state" = "0" ] || [ "$state" = "1" ] || state=1
printf '%s\n' "$temperature" | grep -Eq '^[0-9]+$' || temperature=45
[ "$temperature" -ge 20 ] 2>/dev/null && [ "$temperature" -le 90 ] 2>/dev/null || temperature=45
printf '%s\n' "$hysteresis" | grep -Eq '^[0-9]+$' || hysteresis=3
[ "$hysteresis" -ge 1 ] 2>/dev/null && [ "$hysteresis" -le 20 ] 2>/dev/null && [ "$hysteresis" -lt "$temperature" ] 2>/dev/null || hysteresis=3

uci -q set usbpower.main.enabled="$enabled"
uci -q set usbpower.main.state="$state"
uci -q set usbpower.main.temperature="$temperature"
uci -q set usbpower.main.hysteresis="$hysteresis"
uci -q delete usbpower.main.on_time
uci -q delete usbpower.main.off_time
uci -q delete usbpower.main.timezone
uci -q commit usbpower || die "保存 UCI 配置失败"

/etc/init.d/usb-power enable || die "设置开机启动失败"
/etc/init.d/usb-power start || die "启动服务失败"
sleep 2

netstat -lnt 2>/dev/null | awk -v addr="$lan_ip:$PORT" '$4 == addr { found=1 } END { exit !found }' || die "Web 服务未监听 LAN 地址"
api="$(wget -qO- "http://$lan_ip:$PORT/cgi-bin/api" 2>/dev/null)"
printf '%s\n' "$api" | grep -q '"ok":true' || die "Web API 自检失败"
printf '%s\n' "$api" | grep -q '"cpu_temp":' || die "CPU 温度读取自检失败"

ROLLBACK_READY=0
rm -rf "$BACKUP"
say "$NAME 安装成功。"
say "访问地址：http://$lan_ip:$PORT/"
say "温控参数：${temperature}°C，降温强度 ${hysteresis}°C。"
exit 0
