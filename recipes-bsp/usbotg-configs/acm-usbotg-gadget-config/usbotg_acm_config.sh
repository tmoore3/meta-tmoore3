#!/bin/sh

configfs="/sys/kernel/config/usb_gadget"
g=g1
c=c.1
d="${configfs}/${g}"
func_acm=acm.0

VENDOR_ID="0x1d6b" # Linux Foundation 
PRODUCT_ID="0x0104" # Multifunction Composite Gadget

do_start() {
    if [ ! -d ${configfs} ]; then
        modprobe libcomposite
        if [ ! -d ${configfs} ]; then
        exit 1
        fi
    fi

    if [ -d ${d} ]; then
        exit 0
    fi

    udc=$(ls -1 -I dummy_udc* /sys/class/udc/)
    if [ -z $udc ]; then
        echo "No UDC driver registered"
        exit 1
    fi

    # Create gadget directory
    mkdir "${d}"

    # Assign USB ids
    echo ${VENDOR_ID} > "${d}/idVendor"
    echo ${PRODUCT_ID} > "${d}/idProduct"
    echo 0x0200 > "${d}/bcdUSB"
    # Windows extension to use IAD (Interface Association Descriptor)
    # https://learn.microsoft.com/en-us/windows-hardware/drivers/usbcon/usb-interface-association-descriptor
    echo "0xEF" > "${d}/bDeviceClass"
    echo "0x02" > "${d}/bDeviceSubClass"
    echo "0x01" > "${d}/bDeviceProtocol"
    echo "0x0100" > "${d}/bcdDevice"

    # Assign USB strings (optional)
    mkdir -p "${d}/strings/0x409"
    tr -d '\0' < /proc/device-tree/serial-number > "${d}/strings/0x409/serialnumber"
    echo "Tom's" > "${d}/strings/0x409/manufacturer"
    echo "CDC Serial" > "${d}/strings/0x409/product"
    echo "0123456789abcdef" > "${d}/strings/0x409/serialnumber"

    # Create gadget configuration
    mkdir -p "${d}/configs/${c}"
    #Set English Strings
    mkdir -p "${d}/configs/${c}/strings/0x409"

    # Create gadget serial function
    mkdir -p "${d}/functions/${func_acm}"

    # Assign function to configuration
    ln -s "${d}/functions/${func_acm}" "${d}/configs/${c}"

    # Bind to UDC
    echo "${udc}" > "${d}/UDC"
}

do_stop() {
    # Unbind the UDC
    echo "" > "${d}/UDC"

    # # Teardown gadget directory
    [ -d "${d}/configs/${c}/${func_acm}" ] && rm -f "${d}/configs/${c}/${func_acm}"

    [ -d "${d}/strings/0x409/" ] && rmdir "${d}/strings/0x409/"
    [ -d "${d}/configs/${c}/strings/0x409" ] && rmdir "${d}/configs/${c}/strings/0x409"
    [ -d "${d}/configs/${c}" ] && rmdir "${d}/configs/${c}"
    [ -d "${d}/functions/${func_acm}" ] && rmdir "${d}/functions/${func_acm}"
    [ -d "${d}" ] && rmdir "${d}"
}

case $1 in
    start)
        echo "Start acm gadget"
        do_start
        ;;
    stop)
        echo "Stop acm gadget"
        do_stop
        ;;
    restart)
        echo "Stop acm gadget"
        do_stop
        sleep 1
        echo "Start acm gadget"
        do_start
        ;;
    *)
        echo "Usage: $0 (stop | start | restart)"
        ;;
esac
