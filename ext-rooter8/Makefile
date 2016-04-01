#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-rooter8
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-rooter8
  SECTION:=utils
  CATEGORY:=ROOter
  DEPENDS:=+luci +luci-app-qos +luci-app-ddns +luci-proto-relayd +luci-app-openvpn +luci-app-mwan3 \
		+ext-rooter-basic +ext-sms +ext-buttons +ext-p910nd +ext-samba \
		+ext-umount +ext-command \
		+openvpn-easy-rsa +openvpn-openssl \
		+rqmi +nano +picocom +kmod-usb-net-cdc-mbim +rmbim
  TITLE:=ROOter support for 8meg and larger routers
  PKGARCH:=all
endef

define Package/ext-rooter8/description
  Helper scripts to enable ROOter on 8meg and larger routers
endef


define Build/Compile
endef

define Package/ext-rooter8/install
	$(CP) ./files/* $(1)/


endef

$(eval $(call BuildPackage,ext-rooter8))
