EFI=""
SWAP=""
ROOT=""
KV="5.4.8"

chroot:
	sh ./chroot

install-core:
	sh ./port-install core

install-kernel:
	sh ./kernel-install -v ${KV}

install-grub:
	sh ./grub-install --efi ${EFI} --swap ${SWAP} --root ${ROOT}

install-xorg:
	sh ./port-install xorg

install: install-core install-xorg

.PHONY: chroot install-core install-kernel install-grub install-xorg