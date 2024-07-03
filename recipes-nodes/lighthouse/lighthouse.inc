SUMMARY = "Lighthouse"
DESCRIPTION = "Consensus client to run on the side with the execution client"
HOMEPAGE = "https://lighthouse.sigmaprime.io/"
LICENSE="CLOSED"
LIC_FILES_CHKSUM=""

inherit cargo_bin

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

# DEPENDS += "cmake gcc"
DEPENDS += " openssl"


S = "${WORKDIR}/git"
