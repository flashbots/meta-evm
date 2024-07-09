DESCRIPTION = "Rclone - rsync for cloud storage"
HOMEPAGE = "https://rclone.org/"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING;md5=bed161b82a1ecab65ff7ba3c3b960439"
SRC_URI = "https://github.com/rclone/rclone/archive/refs/tags/v1.66.0.tar.gz"
SRC_URI[md5sum] = "c0e861b546998b7043aa2c4d8b9f0d3e"
SRC_URI[sha256sum] = "9249391867044a0fa4c5a948b46a03b320706b4d5c4d59db9d4aeff8d47cade2"

inherit go

S = "${WORKDIR}/rclone-${PV}"

do_compile() {
    export GOPATH="${WORKDIR}/go"
    export GOBIN="${GOPATH}/bin"
    mkdir -p ${GOBIN}
    export PATH=${PATH}:${GOBIN}
    cd ${S}
    go build -trimpath -buildmode=pie -o rclone
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/rclone ${D}${bindir}/rclone
}

RDEPENDS_${PN} += "ca-certificates"
