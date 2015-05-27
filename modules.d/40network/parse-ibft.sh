#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

. /lib/dracut-lib.sh

for p in $(getargs ip=); do
    [ "ibft" = "$p" ] || continue

    modprobe iscsi_ibft
    num=0
    (
        for iface in /sys/firmware/ibft/ethernet*; do
            unset ifname_mac
            unset ifname_if
            unset dhcp
            unset ip
            unset gw
            unset mask
            unset hostname
            unset vlan
            [ -e ${iface}/mac ] || continue
            ifname_mac=$(read a < ${iface}/mac; echo $a)
            [ -z "$ifname_mac" ] && continue
            unset dev
            for ifname in $(getargs ifname=); do
                if strstr "$ifname" "$ifname_mac"; then
                    dev=${ifname%%:*}
                    break
                fi
            done
            if [ -z "$dev" ]; then
                ifname_if=ibft$num
                num=$(( $num + 1 ))
                echo "ifname=$ifname_if:$ifname_mac"
                dev=$ifname_if
            fi

            [ -e ${iface}/dhcp ] && dhcp=$(read a < ${iface}/dhcp; echo $a)
            if [ -n "$dhcp" ]; then
                echo "ip=$dev:dhcp"
            else
                [ -e ${iface}/ip-addr ] && ip=$(read a < ${iface}/ip-addr; echo $a)
                [ "$ip" = "0.0.0.0" ] && unset ip
                [ -e ${iface}/gateway ] && gw=$(read a < ${iface}/gateway; echo $a)
                [ -e ${iface}/subnet-mask ] && mask=$(read a < ${iface}/subnet-mask; echo $a)
                [ -e ${iface}/hostname ] && hostname=$(read a < ${iface}/hostname; echo $a)
                [ -n "$ip" ] && echo "ip=$ip::$gw:$mask:$hostname:$dev:none"
            fi

            if [ -e ${iface}/vlan ]; then
                vlan=$(read a < ${iface}/vlan; echo $a)
                if [ "$vlan" -ne "0" ]; then
                    case "$vlan" in
                        [0-9]*)
                            echo "vlan=$dev.$vlan:$dev"
                            ;;
                        *)
                            echo "vlan=$vlan:$dev"
                            ;;
                    esac
                fi
            fi
        done
    ) >> /etc/cmdline
    # reread cmdline
    unset CMDLINE
done
