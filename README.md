# NanoPi R3S 实用工具

## USB 风扇温控

通过网页查看 CPU 温度和 USB 供电状态，可手动开关 USB 供电，也可设置启动温度与降温幅度，自动控制连接在 USB 口上的散热风扇。配置可持久保存，服务支持开机自动运行。

## 系统监控

提供轻量 Web 监控页面，实时显示 CPU 占用率、内存占用率、CPU 温度以及网络上传、下载速度，服务支持开机自动运行。

## 系统适配

目前两个工具均面向 **NanoPi R3S**，已在 **ImmortalWrt** 上测试。

它们并不适用于所有 OpenWrt 设备：安装程序会校验 NanoPi R3S 型号，并依赖 OpenWrt/ImmortalWrt 的 `procd`、`uhttpd`、UCI、`ubus` 等组件；风扇温控还依赖 R3S 特定的 USB 供电 GPIO。其他设备或系统版本不能直接保证兼容。
