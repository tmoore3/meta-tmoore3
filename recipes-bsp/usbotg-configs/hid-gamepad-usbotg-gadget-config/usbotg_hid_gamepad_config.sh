#!/bin/sh

configfs="/sys/kernel/config/usb_gadget"
g=g1
c=c.1
d="${configfs}/${g}"
func_hid_gamepad=hid.0
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
    echo "Gamepad" > "${d}/strings/0x409/product"
    echo "0123456789abcdef" > "${d}/strings/0x409/serialnumber"

    # Create gadget configuration
    mkdir -p "${d}/configs/${c}"
    #Set English Strings
    mkdir -p "${d}/configs/${c}/strings/0x409"

    # Create gadget hid mouse function
    mkdir -p "${d}/functions/${func_hid_gamepad}"
    echo 1 > "${d}/functions/${func_hid_gamepad}/subclass"
    echo 2 > "${d}/functions/${func_hid_gamepad}/protocol"
    echo 8 > "${d}/functions/${func_hid_gamepad}/report_length"
    echo -ne \\x05\\x01\\x09\\x05\\xA1\\x01\\xA1\\x00\\x85\\x01\\x05\\x01\\x09\\x30\\x09\\x31\\x15\\x00\\x26\\x7C\\x06\\x75\\x10\\x95\\x02\\x81\\x02\\x05\\x09\\x19\\x01\\x29\\x0F\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x0F\\x81\\x02\\xC0\\xC0 > "${d}/functions/${func_hid_gamepad}/report_desc"

    # 0x05, 0x01,        // Usage Page (Generic Desktop Ctrls)
    # 0x09, 0x05,        // Usage (Game Pad)
    # 0xA1, 0x01,        // Collection (Application)
    # 0xA1, 0x00,        //   Collection (Physical)
    # 0x85, 0x01,        //     Report ID (1)
    # 0x05, 0x01,        //     Usage Page (Generic Desktop Ctrls)
    # 0x09, 0x30,        //     Usage (X)
    # 0x09, 0x31,        //     Usage (Y)
    # 0x15, 0x00,        //     Logical Minimum (0)
    # 0x26, 0x7C, 0x06,  //     Logical Maximum (1660)
    # 0x75, 0x10,        //     Report Size (16)
    # 0x95, 0x02,        //     Report Count (2)
    # 0x81, 0x02,        //     Input (Data,Var,Abs,No Wrap,Linear,Preferred State,No Null Position)
    # 0x05, 0x09,        //     Usage Page (Button)
    # 0x19, 0x01,        //     Usage Minimum (0x01)
    # 0x29, 0x0F,        //     Usage Maximum (0x0F)
    # 0x15, 0x00,        //     Logical Minimum (0)
    # 0x25, 0x01,        //     Logical Maximum (1)
    # 0x75, 0x01,        //     Report Size (1)
    # 0x95, 0x0F,        //     Report Count (15)
    # 0x81, 0x02,        //     Input (Data,Var,Abs,No Wrap,Linear,Preferred State,No Null Position)
    # 0xC0,              //   End Collection
    # 0xC0,              // End Collection

    # Create gadget serial function
    mkdir -p "${d}/functions/${func_acm}"

    # Assign function to configuration
    ln -s "${d}/functions/${func_acm}" "${d}/configs/${c}"

    # Assign function to configuration
    ln -s "${d}/functions/${func_hid_gamepad}" "${d}/configs/${c}"

    # Bind to UDC
    echo "${udc}" > "${d}/UDC"
}

do_stop() {
    # Unbind the UDC
    echo "" > "${d}/UDC"

    # # Teardown gadget directory
    [ -d "${d}/configs/${c}/${func_hid_gamepad}" ] && rm -f "${d}/configs/${c}/${func_hid_gamepad}"
    [ -d "${d}/configs/${c}/${func_acm}" ] && rm -f "${d}/configs/${c}/${func_acm}"

    [ -d "${d}/strings/0x409/" ] && rmdir "${d}/strings/0x409/"
    [ -d "${d}/configs/${c}/strings/0x409" ] && rmdir "${d}/configs/${c}/strings/0x409"
    [ -d "${d}/configs/${c}" ] && rmdir "${d}/configs/${c}"
    [ -d "${d}/functions/${func_hid_gamepad}" ] && rmdir "${d}/functions/${func_hid_gamepad}"
    [ -d "${d}" ] && rmdir "${d}"
}

case $1 in
    start)
        echo "Start hid gamepad gadget"
        do_start
        ;;
    stop)
        echo "Stop hid gamepad gadget"
        do_stop
        ;;
    restart)
        echo "Stop hid gamepad gadget"
        do_stop
        sleep 1
        echo "Start hid gamepad gadget"
        do_start
        ;;
    *)
        echo "Usage: $0 (stop | start | restart)"
        ;;
esac
