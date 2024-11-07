SUMMARY = "Recipe to inject SSH public keys"
DESCRIPTION = "Injects specified SSH public keys into the image"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} = "dropbear"

python () {
    ssh_pubkey = d.getVar('SSH_PUBKEY')
    
    if ssh_pubkey is None:
        origenv = d.getVar("BB_ORIGENV", False)
        if origenv:
            ssh_pubkey = origenv.getVar('SSH_PUBKEY')
    
    if ssh_pubkey:
        d.setVar('SSH_PUBKEY', ssh_pubkey)
        bb.note("SSH_PUBKEY is set to: %s" % ssh_pubkey)
    else:
        bb.note("No SSH_PUBKEY is set. The built image will have no SSH access!")
}

do_install() {
    # Create both possible directories for keys
    install -d ${D}/home/root/.ssh
    
    # Inject the SSH public key into the image
    echo "${SSH_PUBKEY}" > ${D}/home/root/.ssh/authorized_keys
    
    # Set proper permissions
    chmod 600 ${D}/home/root/.ssh/authorized_keys
}

FILES:${PN} += "\
    /home/root/.ssh \
    /home/root/.ssh/authorized_keys \
"
