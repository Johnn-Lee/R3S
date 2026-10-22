# NanoPi R3S 系统监控

亮色 Apple 风格界面，保留原有功能和 `http://R3S的LAN地址:54188/` 访问地址。

推荐使用 [仓库安装说明](../README.md#安装与升级) 中的原生 IPK / 签名 APK。单独安装本工具：

```sh
wget -O /tmp/r3s-install.sh https://raw.githubusercontent.com/Johnn-Lee/R3S/main/install-packages.sh
sh /tmp/r3s-install.sh r3s-monitor
```

使用软件包管理器安装后，通过 `opkg remove r3s-monitor` 或 `apk del r3s-monitor` 卸载。

原有源码安装方式仍保留：将整个 `r3s-monitor` 文件夹上传到 R3S，进入目录执行 `sh install.sh`；仅源码安装的部署使用 `sh uninstall.sh` 卸载。不要用源码卸载器删除软件包管理器安装的文件。
