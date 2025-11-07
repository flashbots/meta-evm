SUMMARY = "Rbuilder Rebalancer"
DESCRIPTION = "Rbuilder rebalancer service"
HOMEPAGE = "https://github.com/flashbots/rbuilder"
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
SRC_URI += "file://config.toml.mustache"
SRC_URI += "file://env.mustache"
S = "${WORKDIR}/git"

INITSCRIPT_NAME = "rbuilder-rebalancer"
INITSCRIPT_PARAMS = "defaults 98"

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "-r -s /bin/false -G eth rbuilder-rebalancer"

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
RUSTFLAGS += "--remap-path-prefix=${WORKDIR}=/usr/src/rbuilder-rebalancer"

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
EXTRA_OECARGO_BUILDARGS += "--frozen --package rbuilder-rebalancer --bin rbuilder-rebalancer"

do_install() {
    # Install the service
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${THISDIR}/init ${D}${sysconfdir}/init.d/rbuilder-rebalancer

    # Install the binary
    install -d ${D}${bindir}
    install -m 0755 ${B}/${CARGO_TARGET_SUBDIR}/rbuilder-rebalancer ${D}${bindir}/rbuilder-rebalancer

    # Install config files
    install -m 0755 -o rbuilder-rebalancer -g rbuilder-rebalancer -d ${D}${sysconfdir}/rbuilder-rebalancer
    install -m 0644 -o rbuilder-rebalancer -g rbuilder-rebalancer    ${THISDIR}/config.toml.mustache ${D}${sysconfdir}/rbuilder-rebalancer/config.toml.mustache
    install -m 0644 -o rbuilder-rebalancer -g rbuilder-rebalancer    ${THISDIR}/env.mustache         ${D}${sysconfdir}/rbuilder-rebalancer/env.mustache
    install -m 0644 -o rbuilder-rebalancer -g rbuilder-rebalancer    /dev/null                       ${D}${sysconfdir}/rbuilder-rebalancer/config.toml
    install -m 0640 -o rbuilder-rebalancer -g rbuilder-rebalancer    /dev/null                       ${D}${sysconfdir}/rbuilder-rebalancer/env
}

# Ensure do_install task is re-run if CARGO_TARGET_SUBDIR changes
do_install[vardeps] += "CARGO_TARGET_SUBDIR"

# Define the files to be included in the package
FILES:${PN} += "${bindir}/rbuilder-rebalancer"
FILES:${PN} += "${sysconfdir}/init.d/${INITSCRIPT_NAME}"
FILES:${PN} += "${sysconfdir}/rbuilder-rebalancer/config.toml.mustache"
FILES:${PN} += "${sysconfdir}/rbuilder-rebalancer/config.toml"
FILES:${PN} += "${sysconfdir}/rbuilder-rebalancer/env.mustache"
