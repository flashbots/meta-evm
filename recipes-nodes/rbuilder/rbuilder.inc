SUMMARY = "Rust Builder"
DESCRIPTION = "Rust builder running with a full ethereum node (reth) implemented in rust."
HOMEPAGE = "https://github.com/flashbots/rbuilder-operator"
LICENSE="CLOSED"
LIC_FILES_CHKSUM=""

inherit cargo_bin update-rc.d useradd

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

DEPENDS += "libffi openssl eth-group protobuf-native"
RDEPENDS:${PN} += "libffi openssl eth-group reth cvm-reverse-proxy-server cvm-reverse-proxy-client render-config"

export BINDGEN_EXTRA_CLANG_ARGS
BINDGEN_EXTRA_CLANG_ARGS = "--sysroot=${WORKDIR}/recipe-sysroot -I${WORKDIR}/recipe-sysroot/usr/include"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://init"
SRC_URI += "file://config.mustache"
SRC_URI += "file://ofac.json"
S = "${WORKDIR}/git"

INITSCRIPT_NAME = "rbuilder"
INITSCRIPT_PARAMS = "defaults 98"

FILES:${PN} += "${sysconfdir}/init.d/rbuilder"
FILES:${PN} += "${sysconfdir}/rbuilder.config.mustache"
FILES:${PN} += "${sysconfdir}/rbuilder.config"
FILES:${PN} += "${sysconfdir}/rbuilder.blocklist.json"

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "-r -s /bin/false -G eth rbuilder"

# Specify the toolchain to use
TOOLCHAIN = "clang"

# Rust flags for build configuration
# Disable CPU-specific optimizations for better portability
RUSTFLAGS += "-C target-cpu=generic"

# Disable Link Time Optimization
RUSTFLAGS += "-C lto=off"

# Flags for reproducible builds
# Remove build ID for better reproducibility
RUSTFLAGS += "-C link-arg=-Wl,--build-id=none"
# Use a consistent symbol mangling version
RUSTFLAGS += "-C symbol-mangling-version=v0"
# Remap the build path to a generic path
RUSTFLAGS += "--remap-path-prefix=${WORKDIR}=/usr/src/rbuilder-operator"

# Cargo profile settings for release builds
# Optimize for size
CARGO_PROFILE_RELEASE_OPT_LEVEL = "z"
# Use a single codegen unit for better optimization
CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "1"
# Abort on panic for smaller binary size
CARGO_PROFILE_RELEASE_PANIC = "abort"
# Disable incremental compilation for reproducibility
CARGO_PROFILE_RELEASE_INCREMENTAL = "false"

# Set Cargo home directory
CARGO_HOME = "${WORKDIR}/cargo_home"
export CARGO_HOME

# Define the target subdirectory for Cargo build artifacts
CARGO_TARGET_SUBDIR = "x86_64-unknown-linux-gnu/release"

# Python function to set SOURCE_DATE_EPOCH for reproducible builds
python do_set_source_date_epoch() {
    import subprocess
    import time

    # Get the commit date of the latest commit
    cmd = f"git -C {d.getVar('S')} log -1 --pretty=%ct"
    commit_date = subprocess.check_output(cmd, shell=True).decode('utf-8').strip()

    # Set SOURCE_DATE_EPOCH to the commit date
    d.setVar('SOURCE_DATE_EPOCH', commit_date)

    # Log the date for debugging
    human_date = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(int(commit_date)))
    bb.note(f"Set SOURCE_DATE_EPOCH to {commit_date} ({human_date} UTC)")
}

# Add the source date epoch task to run after unpacking and before compiling
addtask set_source_date_epoch after do_unpack before do_compile

# Allow network access during compilation (needed for cargo to fetch dependencies)
do_compile[network] = "1"

# Set environment variables before compilation
do_compile:prepend() {
    # Use system git for fetching
    export CARGO_NET_GIT_FETCH_WITH_CLI=true
    # Configure OpenSSL
    export OPENSSL_STATIC=1
    export OPENSSL_DIR="${STAGING_DIR_NATIVE}/usr"
    # Configure zlib
    export ZLIB_DIR="${STAGING_DIR_NATIVE}/usr"
    # Configure PostgreSQL
    export PQ_LIB_DIR="${STAGING_LIBDIR_NATIVE}"
    export PQ_INCLUDE_DIR="${STAGING_INCDIR_NATIVE}"
}

# Additional Cargo build arguments
EXTRA_OECARGO_BUILDARGS += "--features modern --frozen"

do_install:append() {
    install -d ${D}${sysconfdir}/init.d
    install -d ${D}/persistent/rbuilder
    install -m 0755 ${THISDIR}/init ${D}${sysconfdir}/init.d/rbuilder

    # Install config files owned by root, readable by rbuilder
    install -m 0644 ${THISDIR}/config.mustache ${D}${sysconfdir}/rbuilder.config.mustache
    install -m 0640 ${THISDIR}/config.mustache ${D}${sysconfdir}/rbuilder.config
    install -m 0640 ${THISDIR}/ofac.json ${D}/persistent/rbuilder/rbuilder.blocklist.json

    # Ensure rbuilder can read these files
    chown rbuilder:rbuilder ${D}${sysconfdir}/rbuilder.config ${D}/persistent/rbuilder/rbuilder.blocklist.json
}

# Ensure do_install task is re-run if CARGO_TARGET_SUBDIR changes
do_install[vardeps] += "CARGO_TARGET_SUBDIR"

# Define the files to be included in the package
FILES:${PN} += "${bindir}/rbuilder"
FILES:${PN} += "/persistent/rbuilder/rbuilder.blocklist.json"
FILES:${PN} += "${sysconfdir}/init.d/rbuilder"
FILES:${PN} += "${sysconfdir}/rbuilder.config.mustache"
FILES:${PN} += "${sysconfdir}/rbuilder.config"
