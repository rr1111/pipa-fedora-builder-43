# Fedora Linux 44 for the Xiaomi Pad 6 (pipa)

### This is a fork of [pipa-fedora-builder](https://github.com/timoxa0/pipa-fedora-builder)

### Flavors:
- Minimal KDE Plasma (recommended) or KDE Plasma Mobile Desktops

- Minimal Gnome Desktop

- TTY with essentials
  - No WM or DE preinstalled
  - run ```./niri-install``` to install & set up Niri or Hyprland with DankMaterialShell and get started quickly (Keyboard & Internet connection required) 
	
- Common Packages:
	- ```fish``` for a better command line experience, default for ```user```
	- ```tuned``` & ```tuned-ppd``` for better performance and power profiles in Gnome and KDE
	- ```widevine-installer``` from Asahi Linux

#### [Installation guide](./INSTALL.md)
#### [Image building guide](./BUILD.md)

### Kernel Status:
| Sleep | Speakers | Mic | WLAN | Bluetooth | (Fast) Charging | Battery Status | Hall | Display | Brightness | Touch | GPU | USB (Host/Client) | DP alt mode | UFS | Back Camera | Front Camera | Sensors | Xiaomi Keyboard | Pen | Hall Sensor
| ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
| ✅️ | ✅️ | ✅️ | ✅️ | ✅️ | ✅️ (~10w) | ✅️ | ✅️ | ✅️ | ✅️ | ✅️ | ✅️ | ✅️ | ✅️ | ✅️ | ⚠️ (sometimes) | ❌️ | ⚠️ (flaky) | ✅️ | ✅️ | ✅ |

### User Notes:
- The root password is ```fedora```
- The user password is ```147147```

- Kernel updates are handled by dnf. The updated boot image will be flashed to the active slot

### Issues (all flavors):
- Front camera doesnt work, back camera might
- Sensors may break after suspend, so they are disabled by default. To enable them install ```pipa-sensors``` and enable the ```iio-sensor-proxy``` & ```hexagonrpcd-sdsp``` services
- To automatically restart the services and fix the sensors, install ```pipa-sensor-restart```. It takes ~10-15s after waking for the sensors to come back online (might not always work)

### Tips and Tricks:
- Run ```widevine-installer``` to install the Widevinde CDM for Firefox and Chromium based browsers, works for system packages only. **(The widevine CDM module is not altered in any way, nor is it preinstalled or distributed by me)**
- KDE Flavors: 
	- Apply the screen rotation to plasmalogin in Settings -> Login Screen -> Apply Plasma Settings...
- Gnome Flavor:
	- Configure the preinstalled Gnome Rotation Extension as manual Rotation toggle
	- Install the [GJS OSK extension](https://github.com/Vishram1123/gjs-osk) to make the Gnome OSK usable (if your enter key gets stuck, remove it)
	- Install the [TouchUP extension](https://github.com/mityax/gnome-extension-touchup) to make the Gnome Shell more usable on a Touchscreen

## Related projects:
- [postmarketOS](https://wiki.postmarketos.org/wiki/Xiaomi_Pad_6_(xiaomi-pipa)) - pmOS for pipa
- [void-pipa](https://github.com/pipa-mainline/void-pipa) - Void Linux for pipa (EOL?)
- [void-linux-pipa](https://github.com/userg0d/void-linux-pipa) - Another Void Linux for pipa
- [pipa-alarm](https://t.me/pipa_mainline/32978) - alarm (Arch Linux ARM) for pipa
- [armtix-xiaomi-pipa](https://github.com/Neo10e/armtix-xiaomi-pipa) - ARMtix (Artix Linux ARM) for pipa

## Credits:
- [Pocketblue](https://github.com/pocketblue) for COPR Repos, packages & their awesome work
- [pipa-fedora-builder](https://github.com/timoxa0/pipa-fedora-builder) original scripts this is forked from, by timoxa0 (thanks!!!)
- [nabu-fedora-builder](https://github.com/nik012003/nabu-fedora-builder) original original scripts
- [Kernel port](https://github.com/pipa-mainline/linux) by adomerle, V1p0ll, Lukapanio, domin746826 and others
- [Void templates](https://github.com/pipa-mainline/void-pipa) by adomerle
- [Fedora Linux](https://www.fedoraproject.org)

This project is not associated with Fedora Linux or RedHat!
