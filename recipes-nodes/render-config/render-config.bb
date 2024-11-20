SUMMARY = "Mustache templates renderer wrapper"
DESCRIPTION = "Render a mustache template using the provided JSON input configuration"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/:"
SRC_URI = "file://render-config.sh \
           file://fetch-config.sh"

S = "${WORKDIR}"

python () {
    # Check if INIT_CONFIG_URL is set in the environment or in local.conf
    init_config_url = d.getVar('INIT_CONFIG_URL')

    if init_config_url is None:
        # If not set, check the original environment
        origenv = d.getVar("BB_ORIGENV", False)
        if origenv:
            init_config_url = origenv.getVar('INIT_CONFIG_URL')

    if init_config_url:
        # If INIT_CONFIG_URL is set (to any non-empty value), keep its value
        d.setVar('INIT_CONFIG_URL', init_config_url)
    else:
        # If INIT_CONFIG_URL is not set, set it to default hub-atls.builder.flashbots.net
        d.setVar('INIT_CONFIG_URL', 'https://hub-atls.builder.flashbots.net')
}

do_install() {
    # Create necessary directories
    install -d ${D}${bindir}
    install -d ${D}${sysconfdir}
    install -d ${D}${sysconfdir}/init.d

    # Install scripts
    install -m 0755 ${S}/render-config.sh ${D}${bindir}
    install -m 0755 ${S}/fetch-config.sh ${D}${sysconfdir}/init.d/fetch-config

    # Create configuration file with the URL
    echo "export INIT_CONFIG_URL=\"${INIT_CONFIG_URL}\"" > ${D}${sysconfdir}/init-config.conf
}

RDEPENDS:${PN} += "jq curl coreutils mustache"

inherit update-rc.d

INITSCRIPT_NAME = "fetch-config"
INITSCRIPT_PARAMS = "defaults 80"
