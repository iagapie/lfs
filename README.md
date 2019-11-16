# LFS

## GRUB

### [LFS Efi Boot](http://www.linuxfromscratch.org/hints/downloads/files/lfs-uefi.txt)

---

## wpa_supplicant

```bash
wpa_passphrase SSID SECRET_PASSWORD > /etc/wpa_supplicant/wpa_supplicant-wlp11s0.conf

systemctl start wpa_supplicant@wlp11s0
systemctl enable wpa_supplicant@wlp11s0

```

## dhcpcd

```bash
systemctl start dhcpcd@wlp11s0
systemctl enable dhcpcd@wlp11s0
```

After install Xorg:

```bash
ldconfig
```

```bash
useradd -m -s /bin/bash lfs
usermod -a -G wheel,netdev,audio,video,usb,mail,cdrom lfs
passwd lfs
cat > /home/lfs/.xinitrc << "EOF"
dbus-launch --exit-with-session /usr/bin/startplasma-x11
EOF
chown lfs:lfs /home/lfs/.xinitrc
```
