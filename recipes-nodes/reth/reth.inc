SUMMARY = "Reth"
DESCRIPTION = "reth is the command line interface for running a full ethereum node implemented in rust."
LICENSE = "MIT | Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE-MIT;md5=762893aeb79bf290840d33562df482fd \
                    file://LICENSE-APACHE;md5=a343d9147ff9bc8b5864578c4e2118e1"

inherit cargo_bin update-rc.d useradd

# Set the source directory
S = "${WORKDIR}/git"

TOOLCHAIN = "clang"

# Enable network for cargo
do_compile[network] = "1"

# Required system dependencies
DEPENDS += "eth-group zlib-native"
RDEPENDS:${PN} += "disk-encryption render-config eth-group lighthouse cvm-reverse-proxy-server cvm-reverse-proxy-client"

# Configure cargo features
CARGO_FEATURES = "jemalloc asm-keccak min-debug-logs"

# Configure rustflags
RUSTFLAGS:append = " -C target-cpu=generic"
RUSTFLAGS:append = " --remap-path-prefix=${WORKDIR}=/usr/src/reth"
RUSTFLAGS:append = " -C link-arg=-Wl,--compress-debug-sections=zlib"
RUSTFLAGS:append = " -C link-arg=-Wl,--build-id=none"
RUSTFLAGS:append = " -C symbol-mangling-version=v0"
RUSTFLAGS:append = " -C strip=none"

# User/group setup
USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "-r -s /bin/false -G eth reth"
GROUPADD_PARAM:${PN} = "eth"

# Init script configuration
INITSCRIPT_NAME = "reth"
INITSCRIPT_PARAMS = "defaults 97"

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

# Set environment variables before compilation
do_compile:prepend() {
    # Configure zlib
    export ZLIB_DIR="${STAGING_DIR_NATIVE}/usr"
}

do_install:append() {
    # Install the init script
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${THISDIR}/init ${D}${sysconfdir}/init.d/reth
}

# Let Yocto handle stripping
INHIBIT_PACKAGE_STRIP = "0"
INHIBIT_PACKAGE_DEBUG_SPLIT = "0"

DEPENDS += "eth-group zlib-native"
RDEPENDS:${PN} += "disk-encryption render-config eth-group lighthouse cvm-reverse-proxy-server cvm-reverse-proxy-client"

python () {
    # Check if INCLUDE_RCLONE is set in the environment or in local.conf
    include_rclone = d.getVar('INCLUDE_RCLONE')
    
    if include_rclone is None:
        # If not set, check the original environment
        origenv = d.getVar("BB_ORIGENV", False)
        if origenv:
            include_rclone = origenv.getVar('INCLUDE_RCLONE')
    
    if include_rclone:
        # If INCLUDE_RCLONE is set (to any non-empty value), keep its value
        d.setVar('INCLUDE_RCLONE', include_rclone)
    else:
        # If INCLUDE_RCLONE is not set, set it to '1' by default
        d.setVar('INCLUDE_RCLONE', '1')
}
RDEPENDS:${PN} += "${@'reth-sync' if d.getVar('INCLUDE_RCLONE') == '1' else ''}"
