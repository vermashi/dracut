#!/bin/sh
#
# Format:
#	vlan=<vlanname>:<phydevice>
#

parsevlan() {
    local v=${1}:
    set --
    while [ -n "$v" ]; do
        set -- "$@" "${v%%:*}"
        v=${v#*:}
    done

    case $# in
    2)  vlanname=$1; phydevice=$2 ; return 0 ;;
    *)  die "vlan= requires two parameters" ;;
    esac
    return 1
}

unset vlanname phydevice

for vlan in $(getargs vlan); do
    [ "$vlan" = "vlan" ] && continue
    unset vlanname phydevice
    if parsevlan "$(getarg vlan=)"; then
        echo "$phydevice" > /tmp/vlan.${phydevice}.phy
        echo "$phydevice" >> /tmp/net.ifaces
        echo "$vlanname" > /tmp/vlan.${vlanname}.${phydevice}
    fi
done
