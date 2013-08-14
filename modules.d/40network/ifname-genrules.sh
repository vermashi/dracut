#!/bin/sh

# if there are no ifname parameters, just use NAME=KERNEL
if ! getarg ifname= >/dev/null ; then
    return
fi

{

    echo 'SUBSYSTEM!="net",  GOTO="ifname_end"'
    echo 'ACTION!="add", GOTO="ifname_end"'
    echo 'DRIVERS!="?*", GOTO="ifname_end"'
    echo 'ATTR{type}!="1", GOTO="ifname_end"'

    for p in $(getargs ifname=); do
        parse_ifname_opts $p
	printf 'ATTR{address}=="%s", NAME="%s", GOTO="ifname_end"\n' "$ifname_mac" "$ifname_if"
    done

    # Rename non named interfaces out of the way for named ones.
    for p in $(getargs ifname=); do
        parse_ifname_opts $p
	printf 'ATTR{address}!="%s", KERNEL=="%s", NAME="rename$attr{ifindex}", GOTO="ifname_end"\n' "$ifname_mac"  "$ifname_if"
    done

    echo 'LABEL="ifname_end"'

} > /etc/udev/rules.d/50-ifname.rules
