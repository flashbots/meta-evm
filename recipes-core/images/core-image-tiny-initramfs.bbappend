include ${@bb.utils.contains('DISTRO_FEATURES', 'evm', 'core-image-tiny-initramfs.inc', '', d)}
