#
# Copyright (C) 2015 T-Labs Deutsche Telekom Laboratories
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ecmh-dtag
PKG_VERSION:=2015-01-14
PKG_RELEASE=1

PKG_REV:=2c00efcac013a8227d031b367dd8ef4d5b8867bc
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=git@github.com:tlabs-openrouter/ecmh-dtag.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

include $(INCLUDE_DIR)/package.mk

define Package/ecmh-dtag
  SECTION:=utils
  CATEGORY:=Telekom
  TITLE:=Easy Cast du Multi Hub, T-Labs version
  URL:=http://unfix.org/projects/ecmh/
endef

define Package/ecmh-dtag/description
 Networking daemon that acts as a full IPv6 MLDv1 and MLDv2 multicast router/proxy.
endef

TARGET_CFLAGS += -DDEBUG

USE_LOCAL=$(shell ls ./src/ 2>/dev/null >/dev/null && echo 1)
ifneq ($(USE_LOCAL),)
define Build/Prepare
    $(CP) ./src/* $(PKG_BUILD_DIR)/
endef
endif

define Package/ecmh-dtag/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) $(PKG_BUILD_DIR)/src/ecmh $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/ecmh.config $(1)/etc/config/ecmh
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/ecmh.init $(1)/etc/init.d/ecmh

	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./files/ecmh.hotplug $(1)/etc/hotplug.d/iface/40-ecmh
endef

$(eval $(call BuildPackage,ecmh-dtag))
