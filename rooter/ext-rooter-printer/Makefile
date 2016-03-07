#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-rooter-printer
PKG_VERSION:=4.500
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-rooter-printer
  SECTION:=utils
  CATEGORY:=ROOter
  DEPENDS:=+kmod-usb-net +ext-p910nd \
	    +kmod-usb-ohci +usb-modeswitch \
	    +kmod-usb-uhci +kmod-usb2 +luci \
	    +wireless-tools +wpad-mini
  TITLE:=ROOter support for usbmodems
  PKGARCH:=all
endef

define Package/ext-rooter-printer/description
  Helper scripts to enable ROOter to manage usb modem interfaces
endef


define Build/Compile
endef

define Package/ext-rooter-printer/install
	$(CP) ./files/* $(1)/


endef

$(eval $(call BuildPackage,ext-rooter-printer))
