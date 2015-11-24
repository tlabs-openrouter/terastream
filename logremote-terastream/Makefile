#
# Copyright (C) 2006-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=logremote-terastream
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/logremote-terastream
  SECTION:=telekom
  CATEGORY:=Telekom
  TITLE:=Remote logging

#  DEPENDS+= ubox
endef

define Package/logremote-terastream/description
  Log init script that uses log_ip6 on wan interface for remote logging
endef

define Build/Compile
endef

define Package/logremote-terastream/install
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/logremote.init $(1)/etc/init.d/logremote
endef

$(eval $(call BuildPackage,logremote-terastream))
