# NanoPi R3S Web 监控

## 安装

以 `root` 登录 R3S 后执行：

```sh
cd /tmp
wget -O R3S-main.tar.gz https://github.com/Johnn-Lee/R3S/archive/refs/heads/main.tar.gz
tar -xzf R3S-main.tar.gz
cd R3S-main/r3s-monitor
sh install.sh
```

安装完成后，终端会显示访问地址。重复运行安装脚本即可升级。

也可以将整个 `r3s-monitor` 文件夹上传到 R3S，再进入该目录执行 `sh install.sh`。

## 卸载

在安装包目录执行：

```sh
sh uninstall.sh
```
