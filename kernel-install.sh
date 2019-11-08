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
KV="5.3.8"
CURDIR=$(cd "$(dirname $0)" && pwd)
URL="https://www.kernel.org/pub/linux/kernel/v5.x/linux-$KV.tar.xz"
CLEAN=0

while [[ "$1" != "" ]]; do
    case $1 in
        --lfs) shift
            LFS=$1
        ;;
        -v|--version) shift
            KV=$1
        ;;
        -c|--clean)
            CLEAN=1
    esac
    shift
done

interrupted() {
	die "script $(basename $0) aborted!"
}

die() {
	[ "$@" ] && print_error $@
	exit 1
}

trap "interrupted" SIGHUP SIGINT SIGQUIT SIGTERM

if [ ! -f $CURDIR/config-$KV ]; then
    print_error "./config-$KV not found!"
	exit 1
fi

SRCDIR="$LFS/sources"
mkdir -p $SRCDIR

if [ ! -d $LFS/usr/src/linux-$KV ]; then
    if [ ! -f $SRCDIR/linux-$KV.tar.xz ]; then
        echo "=======> Downloading '$URL'."
        wget --no-check-certificate --passive-ftp --tries=3 --waitretry=3 --output-document=$SRCDIR/linux-$KV.tar.xz $URL
    fi

    tar xf $SRCDIR/linux-$KV.tar.xz -C $LFS/usr/src
fi

if [ ! $CLEAN ] && [ ! -f $LFS/usr/src/linux-$KV/.config ] && [ -f $CURDIR/config-$KV-lfs ]; then
    cp $CURDIR/config-$KV-lfs $LFS/usr/src/linux-$KV/.config
fi

cat > $LFS/usr/local/bin/kernel-install << "EOF"
#!/bin/sh
set +h

KV="$1"
CLEAN=$2
URL="https://www.kernel.org/pub/linux/kernel/v5.x/linux-$KV.tar.xz"

if [ ! -d /usr/src/linux-$KV ]; then
    if [ ! -f /sources/linux-$KV.tar.xz ]; then
        echo "=======> Downloading '$URL'."
        wget --no-check-certificate --passive-ftp --tries=3 --waitretry=3 --output-document=/sources/linux-$KV.tar.xz $URL
    fi

    tar xf /sources/linux-$KV.tar.xz -C /usr/src
fi

cd /usr/src/linux-$KV

echo "=======> Building '$SRCDIR/linux-$KV.tar.xz'."

if [ $CLEAN ] || [ ! -f ./.config ]; then
    if [ -f ./.config ]; then
        rm ./.config
    fi

    make mrproper

    make defconfig
    make menuconfig
else
    yes "" | make oldconfig
fi

make
make modules_install

cp -iv arch/x86/boot/bzImage /boot/vmlinuz-$KV-lfs
cp -iv System.map /boot/System.map-$KV-lfs
cp -iv .config /boot/config-$KV-lfs

mkinitramfs $KV
mv initrd.img-* /boot/initrd.img-$KV-lfs
EOF

chmod +x $LFS/usr/local/bin/kernel-install

sh $CURDIR/chroot.sh --lfs $LFS /usr/local/bin/kernel-install $KV $CLEAN || die

exit 0
