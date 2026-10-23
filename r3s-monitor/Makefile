include $(TOPDIR)/rules.mk

PKG_NAME:=r3s-monitor
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/r3s-monitor
  PKGARCH:=all
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=NanoPi R3S system monitor
  DEPENDS:=+uhttpd +uci +ubus +jsonfilter +ip +uclient-fetch
endef

define Build/Compile
endef

define Package/r3s-monitor/install
	$(INSTALL_DIR) $(1)/etc/init.d $(1)/usr/bin $(1)/usr/libexec $(1)/www/monitor
	$(INSTALL_BIN) ./files/etc/init.d/r3s-monitor $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/usr/bin/monitor-collector.sh $(1)/usr/bin/
	$(INSTALL_DATA) ./files/www/monitor/index.html $(1)/www/monitor/
	$(INSTALL_BIN) ./install.sh $(1)/usr/libexec/r3s-monitor-package-install
	$(INSTALL_BIN) ./uninstall.sh $(1)/usr/libexec/r3s-monitor-package-uninstall
endef

include $(CURDIR)/package-hooks.mk
$(eval $(call BuildPackage,r3s-monitor))
