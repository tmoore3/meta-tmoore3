SUMMARY = "Configure a USB HID gamepad gadget on boot"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " file://usbotg_hid_gamepad_config.sh \
    file://usbotg-config.service \
    file://97-ustotg.rules \
    "

S = "${WORKDIR}"

do_install() {
    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${systemd_unitdir}/system
        install -m 0644 ${S}/usbotg-config.service ${D}${systemd_unitdir}/system
    fi

    install -d ${D}${base_sbindir}
    install -m 0755 ${S}/usbotg_hid_gamepad_config.sh ${D}${base_sbindir}

    install -D -p -m0644 ${S}/97-ustotg.rules ${D}${sysconfdir}/udev/rules.d/97-ustotg.rules
}

FILES:${PN} += "${systemd_unitdir}/system ${sysconfdir}/udev"
