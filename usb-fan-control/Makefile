include $(TOPDIR)/rules.mk

PKG_NAME:=usb-fan-control
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/usb-fan-control
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=NanoPi R3S USB fan controller
  DEPENDS:=+uhttpd +uci +ubus +jsonfilter +gpiod-tools +uclient-fetch
endef

define Build/Compile
endef

define Package/usb-fan-control/conffiles
/etc/config/usbpower
endef

define Package/usb-fan-control/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d $(1)/usr/libexec $(1)/www/usb-power/cgi-bin
	$(INSTALL_DATA) ./files/etc/config/usbpower $(1)/etc/config/
	$(INSTALL_BIN) ./files/etc/init.d/usb-power $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/usr/libexec/usb-power-control $(1)/usr/libexec/
	$(INSTALL_BIN) ./files/usr/libexec/usb-power-thermal $(1)/usr/libexec/
	$(INSTALL_BIN) ./files/www/usb-power/cgi-bin/api $(1)/www/usb-power/cgi-bin/
	$(INSTALL_DATA) ./files/www/usb-power/index.html $(1)/www/usb-power/
	$(INSTALL_BIN) ./install.sh $(1)/usr/libexec/usb-fan-control-package-install
	$(INSTALL_BIN) ./uninstall.sh $(1)/usr/libexec/usb-fan-control-package-uninstall
endef

include $(CURDIR)/package-hooks.mk
$(eval $(call BuildPackage,usb-fan-control))
