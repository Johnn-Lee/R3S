#!/bin/sh

say() {
	printf '%s\n' "$*"
}

[ "$(id -u)" = "0" ] || {
	say "错误：请使用 root 用户运行卸载器。" >&2
	exit 1
}

if [ -x /etc/init.d/usb-power ]; then
	/etc/init.d/usb-power stop >/dev/null 2>&1 || {
		say "错误：无法停止 usb-power 服务。" >&2
		exit 1
	}
	/etc/init.d/usb-power disable >/dev/null 2>&1
fi

if [ -x /usr/libexec/usb-power-control ]; then
	/usr/libexec/usb-power-control release >/dev/null 2>&1
fi

if [ -r /sys/kernel/debug/gpio ]; then
	gpio_line="$(grep 'gpio-6 ' /sys/kernel/debug/gpio 2>/dev/null | head -n 1)"
	case "$gpio_line" in
		*usb-power-control*)
			say "错误：GPIO 仍被温控程序占用，已停止卸载。" >&2
			exit 1
			;;
	esac
fi

rm -f /etc/init.d/usb-power
rm -f /etc/config/usbpower
rm -f /usr/libexec/usb-power-control
rm -f /usr/libexec/usb-power-thermal
rm -f /usr/libexec/usb-power-scheduler
rm -rf /www/usb-power
rm -rf /var/run/usb-power
rm -rf /var/lock/usb-power.lockdir

say "NanoPi R3S USB 风扇温控已完整卸载。"
say "USB 供电已交还内核控制。"
exit 0
