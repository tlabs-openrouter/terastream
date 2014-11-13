#
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ecmh-dtag
PKG_VERSION:=2014-03-04
PKG_RELEASE=7

PKG_REV:=17bd60c12e39c9292b9b1211f4d5f69340ba7a9e
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=git@slowspeed.hopto.org:ecmh.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

include $(INCLUDE_DIR)/package.mk

define Package/ecmh-dtag
  SECTION:=utils
  CATEGORY:=Telekom
  TITLE:=Easy Cast du Multi Hub
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
