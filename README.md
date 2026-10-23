# NanoPi R3S 实用工具

两个独立网页工具，使用亮色 Apple 系统设置风格。原有采集、温控、GPIO、接口和操作功能保持不变。

| 软件包 | 功能 | 访问地址 |
| --- | --- | --- |
| `r3s-monitor` | CPU、内存、温度、网络上传和下载监控 | `http://R3S的LAN地址:54188/` |
| `usb-fan-control` | USB 供电开关、CPU 自动温控、持久配置 | `http://R3S的LAN地址:54199/` |

## 支持范围

仅支持 **NanoPi R3S** 的 OpenWrt / ImmortalWrt。安装前仍检查型号和 CPU 温度接口，风扇工具还检查 GPIO0_A6、gpiochip0 和固定稳压器驱动接口。风扇依赖 `gpiod-tools` 2.x；其他设备不会因为软件包架构为 all/noarch 而获得支持。

## 安装与升级

以 root 登录 R3S，一次安装两个工具：

```sh
wget -O /tmp/r3s-install.sh https://raw.githubusercontent.com/Johnn-Lee/R3S/main/install-packages.sh
sh /tmp/r3s-install.sh
```

也可只安装一个：

```sh
sh /tmp/r3s-install.sh r3s-monitor
sh /tmp/r3s-install.sh usb-fan-control
```

脚本从最新 [Release](https://github.com/Johnn-Lee/R3S/releases/latest) 下载对应包，更新系统软件源索引以解析依赖。opkg 系统使用 IPK，apk 系统使用 APK。APK 首次安装会核对固定公钥并导入 `/etc/apk/keys/r3s.pem`，随后正常验签安装，不使用 `--allow-untrusted`。已有不同的同名公钥不会被静默替换。再次执行即可升级，已有风扇温控配置保留。

### 手动安装

从 Release 下载对应安装包。opkg 系统：

```sh
opkg update
opkg install /tmp/r3s-monitor.ipk /tmp/usb-fan-control.ipk
```

apk 系统首次额外下载 `r3s.pem` 并导入：

```sh
echo 'b6ef910d5ecb94cfcd7dc82540a2cd59bff0bc13207858ac83a054a726bce856  /tmp/r3s.pem' | sha256sum -c - &&
mkdir -p /etc/apk/keys &&
cp /tmp/r3s.pem /etc/apk/keys/r3s.pem &&
chmod 0644 /etc/apk/keys/r3s.pem &&
apk update &&
apk add /tmp/r3s-monitor.apk /tmp/usb-fan-control.apk
```

IPK 可以通过 LuCI 软件包页面上传安装；APK 先完成公钥导入后也可以上传。第三方签名公钥需要首次信任引导，不会自动成为原厂固件的受信任密钥。没有所需依赖或硬件接口时，安装会报出相应错误。

原有源码安装器保留供手动部署使用；采用软件包管理器安装后，请使用软件包管理器升级和卸载，避免混用源码卸载器。

## 卸载

```sh
# opkg 系统
opkg remove r3s-monitor usb-fan-control
# apk 系统
apk del r3s-monitor usb-fan-control
```

可只指定要卸载的一个包。卸载风扇工具沿用原有流程，停止温控并把 USB 供电交还内核；升级不删除现有温控配置。

## 编译和签名

GitHub Actions 使用官方 rockchip/armv8 SDK：24.10.8 构建两个 IPK，25.12.5 构建两个 APK。普通 main 推送生成 Actions Artifacts；推送与两个 Makefile 中 `PKG_VERSION` 一致的 `v*` 标签发布 Release。

本仓库的固定私钥保存于 `APK_SIGNING_KEY` Actions Secret，Git 中只有 `keys/r3s.pem` 公钥。APK 均单独签名，并验证正确公钥接受、空信任库和错误公钥拒绝、篡改包拒绝。其他 fork 需要配置自己的密钥，并同步替换公钥和安装器中的公钥 SHA-256。

CI 同时检查 7 个运行脚本/配置文件与原始版本字节一致，页面脚本除等价颜色替换外保持一致，所有控件 ID、输入限制和操作保持一致。包安装测试在官方 x86 根文件系统中使用真实依赖执行，硬件钩子禁用或延后；它验证包和依赖，不代表在 x86 上支持 R3S 硬件。型号/GPIO 钩子另用模拟文件测试，实际 GPIO、温控与路由器服务仍需 R3S 实机确认。
