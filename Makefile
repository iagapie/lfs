LFS=/mnt/lfs
EFI=""
SWAP=""
ROOT=""
KV="5.3.8"

chroot:
	sh ./chroot --lfs ${LFS}

install-core:
	sh ./port-install --lfs ${LFS} core

install-kernel:
	sh ./kernel-install --lfs ${LFS} -v ${KV}

install-grub:
	sh ./grub-install --lfs ${LFS} --efi ${EFI} --swap ${SWAP} --root ${ROOT}

install-xorg:
	sh ./port-install --lfs ${LFS} xorg

install: install-core install-xorg

.PHONY: chroot install-core install-kernel install-grub install-xorg