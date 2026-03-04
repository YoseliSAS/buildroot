################################################################################
#
# libpam-policycache
#
################################################################################

# Using YoseliSAS fork with uClibc-ng compatibility patches:
# - crypt_r() replaced with crypt() for uClibc
# - innetgr() stubbed for systems without NIS
# - hardening flags (-fstack-protector-all, -pie) made conditional
LIBPAM_POLICYCACHE_VERSION = v0.11
LIBPAM_POLICYCACHE_SITE = https://github.com/google/libpam-policycache.git
LIBPAM_POLICYCACHE_SITE_METHOD = git
LIBPAM_POLICYCACHE_LICENSE = Apache-2.0
LIBPAM_POLICYCACHE_LICENSE_FILES = LICENSE
LIBPAM_POLICYCACHE_DEPENDENCIES = host-pkgconf linux-pam libglib2 libscrypt
LIBPAM_POLICYCACHE_AUTORECONF = YES

$(eval $(autotools-package))
