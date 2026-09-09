# NanoPi R3S USB 风扇温控

## 安装

使用 root 登录 R3S 后执行：

```sh
cd /tmp
wget -O R3S-main.tar.gz https://github.com/Johnn-Lee/R3S/archive/refs/heads/main.tar.gz
tar -xzf R3S-main.tar.gz
cd R3S-main/usb-fan-control
sh install.sh
```

安装成功后，根据终端显示的 LAN 地址访问网页，端口为 `54199`。重复运行安装器可升级，已有温控配置会保留。

也可以把整个 `usb-fan-control` 目录上传到 R3S，然后在目录中运行：

```sh
sh install.sh
```

## 卸载

进入 `usb-fan-control` 目录后执行：

```sh
sh uninstall.sh
```
