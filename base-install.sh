#!/bin/bash
set +h

print_error() {
	echo -e "ERROR: $@"
}

if [ $(id -u) != 0 ]; then
	print_error "$0 script need to run as root!"
	exit 1
fi

LFS="/mnt/lfs"
PORT=core
LOCAL=0

while [[ "$1" != "" ]]; do
    case $1 in
        --lfs) shift
            LFS=$1
        ;;
		-p|--port) shift
			PORT=$1
		;;
		-lp|--lp)
			LOCAL=1
		;;
    esac
    shift
done

mount_cache() {
	mkdir -p $LFS/var/lib/pkg/{pkg,src} $SRCDIR $PKGDIR
	mount --bind $LFS/sources $LFS/var/lib/pkg/src
	mount --bind $LFS/packages $LFS/var/lib/pkg/pkg
}

umount_cache() {
	mountpoint -q $LFS/var/lib/pkg/src && umount $LFS/var/lib/pkg/src
	mountpoint -q $LFS/var/lib/pkg/pkg && umount $LFS/var/lib/pkg/pkg
}

interrupted() {
	die "script $(basename $0) aborted!"
}

die() {
	[ "$@" ] && print_error $@
	umount_cache
	exit 1
}

trap "interrupted" SIGHUP SIGINT SIGQUIT SIGTERM

CURDIR=$(cd "$(dirname $0)" && pwd)
SRCDIR="$LFS/sources"
PKGDIR="$LFS/packages"

mount_cache

if [ $LOCAL ]; then
	rm -rf $LFS/usr/ports/*
	ports="core extra xorg gnome"
	for p in $ports; do
		cp -ra $CURDIR/../lfs-ports/$p $LFS/usr/ports/
	done
else
	sh $CURDIR/chroot.sh --lfs $LFS ports -u || die
fi

pkgs=""
while read -r pkg; do
    pkgs="$pkgs$pkg "
done < $LFS/usr/ports/$PORT/list

if [ $PORT == "core" ]; then
	sh $CURDIR/chroot.sh --lfs $LFS /tools/bin/pkgin -i -ic $pkgs || die
else
	sh $CURDIR/chroot.sh --lfs $LFS pkgin -i -ic $pkgs || die
fi

umount_cache

exit 0
