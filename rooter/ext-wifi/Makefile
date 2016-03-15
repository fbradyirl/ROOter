#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-wifi
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-wifi
  SECTION:=utils
  CATEGORY:=ROOter
  SUBMENU:=Wifi
  DEPENDS:=+kmod-ath9k-htc +kmod-carl9170 +kmod-brcmfmac +kmod-brcmutil +kmod-cfg80211 \
	 +kmod-lib80211 +kmod-libertas-sdio +kmod-libertas-usb  +kmod-mac80211 \
	 +kmod-mac80211-hwsim +kmod-net-rtl8188eu +kmod-net-rtl8192su +kmod-p54-common \
 	 +kmod-p54-usb +kmod-rt2500-usb +kmod-rt2800-usb +kmod-rt2x00-lib +kmod-rt73-usb \
	 +kmod-rtl8187 +kmod-rtl8192cu +kmod-zd1211rw 
  TITLE:=support for wifi
  PKGARCH:=all
endef

define Package/ext-wifi/description
  Helper scripts to enable wifi
endef


define Build/Compile
endef


$(eval $(call BuildPackage,ext-wifi))
