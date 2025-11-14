SUMMARY = "FlowProxy"
DESCRIPTION = "FlowProxy service"
HOMEPAGE = "https://github.com/BuilderNet/FlowProxy"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=cc10dc03cc36fb791b5fc9c2b91db893"

inherit cargo_bin update-rc.d useradd

DEPENDS += "libffi openssl protobuf-native"
RDEPENDS:${PN} += "libffi openssl cvm-reverse-proxy-server cvm-reverse-proxy-client render-config"

export BINDGEN_EXTRA_CLANG_ARGS
BINDGEN_EXTRA_CLANG_ARGS = "--sysroot=${WORKDIR}/recipe-sysroot -I${WORKDIR}/recipe-sysroot/usr/include"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://init"
SRC_URI += "file://env.mustache"
S = "${WORKDIR}/git"

INITSCRIPT_NAME = "flowproxy"
INITSCRIPT_PARAMS = "defaults 98"

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "-r -s /bin/false flowproxy"

# Specify the toolchain to use
TOOLCHAIN = "clang"

# Reproducible Rust flags
RUSTFLAGS += "-C target-cpu=generic"
RUSTFLAGS += "-C lto=off"
RUSTFLAGS += "-C link-arg=-Wl,--build-id=none"
RUSTFLAGS += "-C symbol-mangling-version=v0"
RUSTFLAGS += "-C strip=none"
RUSTFLAGS += "-C metadata=''"
RUSTFLAGS += "--remap-path-prefix=${S}=."

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

do_compile:prepend() {
    export CARGO_NET_GIT_FETCH_WITH_CLI=true
    export OPENSSL_STATIC=1
    export OPENSSL_DIR="${STAGING_DIR_NATIVE}/usr"
    export ZLIB_DIR="${STAGING_DIR_NATIVE}/usr"
    export PQ_LIB_DIR="${STAGING_LIBDIR_NATIVE}"
    export PQ_INCLUDE_DIR="${STAGING_INCDIR_NATIVE}"

    # Reproducible environment
    export LC_ALL=C
    export TZ=UTC

    # Optional jemalloc override to match local builds
    if [ -f "${STAGING_LIBDIR}/libjemalloc.a" ]; then
        export JEMALLOC_OVERRIDE="${STAGING_LIBDIR}/libjemalloc.a"
    fi
}

# Additional Cargo build arguments
EXTRA_OECARGO_BUILDARGS = "--locked --profile reproducible --target x86_64-unknown-linux-gnu --features jemalloc-unprefixed --package flowproxy --bin flowproxy"

do_install() {
    # Install the service
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${THISDIR}/init ${D}${sysconfdir}/init.d/flowproxy
    
    # Install the binary
    install -d ${D}${bindir}
    install -m 0755 ${B}/${CARGO_TARGET_SUBDIR}/flowproxy ${D}${bindir}/flowproxy
    
    # Install config files
    install -m 0755 -o flowproxy -g flowproxy -d ${D}${sysconfdir}/flowproxy
    install -m 0644 -o flowproxy -g flowproxy ${THISDIR}/env.mustache ${D}${sysconfdir}/flowproxy/env.mustache
    install -m 0640 -o flowproxy -g flowproxy /dev/null ${D}${sysconfdir}/flowproxy/env
}

# Ensure do_install task is re-run if CARGO_TARGET_SUBDIR changes
do_install[vardeps] += "CARGO_TARGET_SUBDIR"

# Define the files to be included in the package
FILES:${PN} += "${bindir}/flowproxy"
FILES:${PN} += "${sysconfdir}/init.d/${INITSCRIPT_NAME}"
FILES:${PN} += "${sysconfdir}/flowproxy/env.mustache"
