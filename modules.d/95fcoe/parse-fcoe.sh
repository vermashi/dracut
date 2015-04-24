#!/bin/sh
#
# Supported formats:
# fcoe=<networkdevice>:<dcb|nodcb>
# fcoe=<macaddress>:<dcb|nodcb>
#
# Note currently only nodcb is supported, the dcb option is reserved for
# future use.
#
# Examples:
# fcoe=eth0:nodcb
# fcoe=4a:3f:4c:04:f8:d7:nodcb

[ -z "$fcoe" ] && fcoe=$(getarg fcoe=)

# If it's not set we don't continue
[ -z "$fcoe" ] && return

# FCoE actually supported?
# BRCM: Later, should check whether bnx2x is loaded first before loading bnx2fc so do not load bnx2fc when there are no Broadcom adapters
[ -e /sys/module/fcoe/parameters/create ] || modprobe -a fcoe || die "FCoE requested but kernel/initrd does not support FCoE"

initqueue --onetime modprobe -q -b bnx2fc

parse_fcoe_opts() {
    local IFS=:
    set $fcoe

    case $# in
        2)
            fcoe_interface=$1
            fcoe_dcb=$2
            return 0
            ;;
        7)
            fcoe_mac=$(echo $1:$2:$3:$4:$5:$6 | tr '[:upper:]' '[:lower:]')
            fcoe_dcb=$7
            return 0
            ;;
        *)
            warn "Invalid arguments for fcoe=$fcoe"
            return 1
            ;;
    esac
}

for fcoe in $(getargs fcoe=); do
    unset fcoe_mac
    unset fcoe_interface
    parse_fcoe_opts

    if [ "$fcoe_interface" = "edd" ]; then
        if [ "$fcoe_dcb" != "nodcb" -a "$fcoe_dcb" != "dcb" ] ; then
            warn "Invalid FCoE DCB option: $fcoe_dcb"
        fi
        /sbin/initqueue --settled --unique /sbin/fcoe-edd $fcoe_dcb
    else
        if [ "$fcoe_dcb" != "nodcb" -a "$fcoe_dcb" != "dcb" ] ; then
            warn "Invalid FCoE DCB option: $fcoe_dcb"
        fi
        . /sbin/fcoe-genrules.sh
    fi
done

