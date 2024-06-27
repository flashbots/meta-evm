SUMMARY = "Reth"
DESCRIPTION = "reth is the command line interface for running a full ethereum node implemented in rust."
LICENSE="CLOSED"
LIC_FILES_CHKSUM=""

inherit cargo_bin update-rc.d

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

export BINDGEN_EXTRA_CLANG_ARGS
BINDGEN_EXTRA_CLANG_ARGS = "--sysroot=${WORKDIR}/recipe-sysroot -I${WORKDIR}/recipe-sysroot/usr/include"
CARGO_BUILD_PROFILE = "profiling"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://init"
INITSCRIPT_NAME = "reth"
INITSCRIPT_PARAMS = "defaults 98"

S = "${WORKDIR}/git"

do_install:append() {
    install -d ${D}${bindir}
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${THISDIR}/init ${D}${sysconfdir}/init.d/reth
}

RDEPENDS:${PN} += "disk-encryption config-parser"
