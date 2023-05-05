# digital-signage-playout

This repository contains the scripts and instructions to build a lightweight and minimal playout server.

## Background

To display trailers or other information the [OSCAR Student Cinema](https://www.asta-hsrm.de/freizeit/kino/kino-team/) needed a playout simple and cheap server to feed two sub-1080p projectors. To keep things simple I opted for a used Dell Wyse 3040 Thinclient with ubuntu server installed. When a USB stick is inserted it is automatically mounted in `/media/`. When a volume with the label `PLAYOUT` is detected it a script automatically plays back the video files on the USB-stick

## Usage

To use the finished playout server just insert a USB stick formatted in exfat and named `PLAYOUT`. Depending on how many Displays should be fed, corresponding folders should be created on the volume named `SCREEN1`, `SCREEN2`, and so on. If a special background should be displayed when no video files are in a folder for a screen, this image can be dropped in the root directory with the name and extension `background.png`.

The videos in the folders will be played back alphabetically, starting again from the beginning when the last ended. When the USB stick is pulled while the device is on, the background image should be displayed. The playback should automatically start again when the USB is reconnected.

## ToDo

There are still problems I haven't fixed yet:
- [ ] [Analog Front Audio doesn't work](https://www.reddit.com/r/linuxquestions/comments/dfq5ar/looking_for_audio_driver_for_realtek_rt5672/)
- [x] Screen tearing when playing back video

## Installation

### Wyse BIOS Lock

If the BIOS password was not modified the BIOS can be unlocked with the default password `Fireport`. In the BIOS the ubuntu server USB stick can be selected to start the installation.

### Ubuntu Server 22.04 LTS

As only 8GB of flash memory is included in a Wyse 3040 ThinClient I opted for a minimalized ubuntu install. The Network interface can be set to a specific IP (For example `192.168.10.1/24`) to ease modification in the field because the system will not be connected to a network by default.

#### Storage Setup

As space is limited I manually reformated the 8GB flash and added a gpt partition in the ext4 format. This automatically creates a 500 MB boot partition that I shrunk to 250 MB. The main partition can be resized to the maximum after shrinking the boot partition.

#### OpenSSH

To aid in setting up the playout server I recommend installing OpenSSH.

#### User setup

The script and the instructions expect the main username to be `sysadmin`, so please use that as the username.

### Updates and Installations

To update the system and install the necessary software use these commands:

```
sudo apt update && sudo apt upgrade -y
```

```
sudo apt install intel-gpu-tools mpv htop nano dialog xorg feh xterm openbox alsa-utils
```

### USB Automount

To automatically mount USB drives I followed this guide: [https://serverfault.com/questions/766506/automount-usb-drives-with-systemd](https://serverfault.com/questions/766506/automount-usb-drives-with-systemd)

#### Script

First the mount script needs to be created:

```
sudo nano /usr/local/bin/usb-mount.sh
```

The content can be found in the repository. To make the script executable using this command:

```
sudo chmod +x /usr/local/bin/usb-mount.sh
```

#### Service

Secondly, the automount service needs to be created:

```
sudo nano /etc/systemd/system/usb-mount@.service
```

The content of this file should be the following:

```
[Unit]
Description=Mount USB Drive on %i

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/usr/local/bin/usb-mount.sh add %i
ExecStop=/usr/local/bin/usb-mount.sh remove %i
```

#### udev Rule

To automatically run the script when a USB drive is inserted a udev rule needs to be created:

```
sudo nano /etc/udev/rules.d/99-local.rules
```

Inside this file this needs to be pasted:

```
KERNEL=="sd[a-z][0-9]", SUBSYSTEMS=="usb", ACTION=="add", RUN+="/bin/systemctl start usb-mount@%k.service"

KERNEL=="sd[a-z][0-9]", SUBSYSTEMS=="usb", ACTION=="remove", RUN+="/bin/systemctl stop usb-mount@%k.service"
```

#### Activate Changes

To Restart the services use these commands:

```
sudo udevadm control --reload-rules
```

```
sudo systemctl daemon-reload
```

### Main Script

Past or copy the script from the repository in `/home/sysadmin` and name it `script.sh`

To make the script executable run:

```
chmod +x script.sh
```

### Autostart Script

To automatically start the script at boot, a service needs to be created:

```
sudo nano /etc/systemd/system/playout_script.service
```

```
[Unit]
Description=Playout Script

[Service]
ExecStart=/home/sysadmin/script.sh
User=root
Group=root

[Install]
WantedBy=multi-user.target
```

After the Service is created, the service can be enabled (so it starts on boot) and started:

```
sudo systemctl daemon-reload
```

```
sudo systemctl enable playout_script.service
```

```
sudo systemctl start playout_script.service
```

If you want to check for problems, use this command:

```
sudo systemctl status playout_script.service
```

### [Disable Wait-for-Network](https://askubuntu.com/questions/972215/a-start-job-is-running-for-wait-for-network-to-be-configured-ubuntu-server-17-1)

```
sudo systemctl disable systemd-networkd-wait-online.service
```

```
sudo systemctl mask systemd-networkd-wait-online.service
```

### [Fix Screen Tearing](https://wiki.archlinux.org/title/intel_graphics)

```
sudo nano /etc/X11/xorg.conf.d/20-intel.conf
```

```
Section "Device"
  Identifier "Intel Graphics"
  Driver "intel"
  Option "TearFree" "true"
EndSection
```

## Security

The playout server defined in this repository doesn't always follow best practices in terms of security with the root user. As a result, the server is not intended to be used with a permanent network connection and should not hold any sensitive information.