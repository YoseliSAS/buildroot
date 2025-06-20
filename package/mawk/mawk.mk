################################################################################
#
# mawk
#
################################################################################

MAWK_VERSION = 1.3.4-20250131
MAWK_SITE = https://invisible-mirror.net/archives/mawk
MAWK_SOURCE = mawk-$(MAWK_VERSION).tgz
MAWK_LICENSE = GPL-2.0
MAWK_LICENSE_FILES = COPYING

define MAWK_CREATE_SYMLINK
	ln -sf mawk $(TARGET_DIR)/usr/bin/awk
endef

MAWK_POST_INSTALL_TARGET_HOOKS += MAWK_CREATE_SYMLINK

$(eval $(autotools-package))
