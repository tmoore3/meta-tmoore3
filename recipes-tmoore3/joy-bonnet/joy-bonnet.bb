SUMMARY = "Joy Bonnet USB HID Gamepad Application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit systemd

SYSTEMD_AUTO_ENABLE = "enable"
SYSTEMD_SERVICE:${PN} = "joy-bonnet.service"

SRC_URI = "git://github.com/tmoore3/joy-bonnet.git;protocol=https;branch=main"
SRCREV = "${AUTOREV}"
PV = "1.0+git${SRCPV}"

S = "${WORKDIR}/git"

DEPENDS += "libevdev"

inherit pkgconfig cmake

EXTRA_OECMAKE = ""

do_install() {
    install -d ${D}${bindir}
    install -m 0755 joy-bonnet ${D}${bindir}

    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${systemd_unitdir}/system
        install -m 0644 ${S}/joy-bonnet.service ${D}${systemd_unitdir}/system
    fi
}

FILES:${PN} += "${systemd_unitdir}/system"
