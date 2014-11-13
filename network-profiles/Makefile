#
# Copyright (C) 2014 Deutsche Telekom AG
#
# Author: Kaspar Schleiser
#
include $(TOPDIR)/rules.mk
PKG_NAME:=network-profiles
PKG_VERSION:=0.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/network-profiles
  SECTION:=telekom
  CATEGORY:=Telekom
  TITLE:=Network profile infrastructure
endef

define Package/network-profiles/description
  This package adds infrastructure to bundle network settings into profiles.
endef

define Package/network-profiles/install
	$(INSTALL_DIR) \
		$(1)/etc/profiles/network/hooks \
		$(1)/usr/sbin

	$(INSTALL_BIN) ./files/setup_network.sh $(1)/usr/sbin/setup_network
endef

define Build/Compile
endef

$(eval $(call BuildPackage,network-profiles))
