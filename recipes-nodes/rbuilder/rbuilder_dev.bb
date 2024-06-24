SUMMARY = "Rust Builder"
HOMEPAGE = "https://github.com/flashbots/rbuilder-private"
LICENSE = "CLOSED"

inherit cargo_bin pkgconfig

python () {
    import os
    origenv = d.getVar("BB_ORIGENV", False)
    git_token = origenv.getVar('GIT_TOKEN') or os.getenv('GIT_TOKEN')
    if not git_token:
        bb.fatal("GIT_TOKEN environment variable not set or is empty")
    else:
        bb.note("GIT_TOKEN is set")
    
    # Set the SRC_URI with the token included
    d.setVar('SRC_URI', f"git://{git_token}@github.com/flashbots/rbuilder-private.git;protocol=https;branch=main")
}

SRCREV = "49eee1f3af9dd7bbeecd331f371c288047d4481c"
PV = "1.0+git${SRCPV}"
S = "${WORKDIR}/git"

DEPENDS += "pkgconfig-native openssl libffi virtual/libc virtual/libintl virtual/${TARGET_PREFIX}compilerlibs virtual/${TARGET_PREFIX}gcc"
RDEPENDS:${PN} += "openssl libffi"

export CC = "${CCACHE}${HOST_PREFIX}gcc ${HOST_CC_ARCH}${TOOLCHAIN_OPTIONS}"
export CFLAGS = "${HOST_CFLAGS}"
export LDFLAGS = "${HOST_LDFLAGS}"

# Enable network access for cargo to fetch dependencies
do_compile[network] = "1"

# Avoid caching sensitive information
BB_BASEHASH_IGNORE_VARS:append = " GIT_TOKEN"
BB_DONT_CACHE = "1"

# Exclude GIT_TOKEN from being logged
GIT_TOKEN[vardepsexclude] = "GIT_TOKEN"

# Add debugging information and handle file conflicts
python do_prepare_recipe_sysroot:append() {
    bb.debug(2, "In do_prepare_recipe_sysroot:append")
    bb.debug(2, "STAGING_DIR_NATIVE: %s" % d.getVar('STAGING_DIR_NATIVE'))
    bb.debug(2, "STAGING_DIR_HOST: %s" % d.getVar('STAGING_DIR_HOST'))
    bb.debug(2, "WORKDIR: %s" % d.getVar('WORKDIR'))
    
    import os
    manifest_path = os.path.join(d.getVar('WORKDIR'), "recipe-sysroot-native/usr/lib/rustlib/manifest-rustc")
    if os.path.islink(manifest_path):
        bb.debug(2, "Removing existing manifest-rustc symlink")
        os.remove(manifest_path)
}

# Add verbose output for debugging
EXTRA_OEMAKE = "V=1"
EXTRA_OECARGO_BUILDFLAGS = "-vv"

# Set up Rust wrapper for proper environment
RUSTC_WRAPPER = "${WORKDIR}/wrapper/rust-wrapper.sh"

do_configure:prepend() {
    mkdir -p ${WORKDIR}/wrapper
    cat <<- EOF > ${WORKDIR}/wrapper/rust-wrapper.sh
#!/bin/sh
export CC="${CC}"
export CFLAGS="${CFLAGS}"
export LDFLAGS="${LDFLAGS}"
\$@
EOF
    chmod +x ${WORKDIR}/wrapper/rust-wrapper.sh
}