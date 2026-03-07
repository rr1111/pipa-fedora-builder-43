# Fedora Linux 43 for Xiaomi Pad 6 (pipa)

### This is a fork of [pipa-fedora-builder](https://github.com/timoxa0/pipa-fedora-builder)

### Features:
- <strong>System fully updated to Fedora 43</strong>
- [Pocketblue](https://github.com/pocketblue) ```pocketblue``` & ```sm8250``` COPR repos and packages for more up to date pipa packages
- [pipa-packages](https://github.com/rr1111/pipa-fedora-packages) COPR repo for more up to date kernel

### Flavors:
- Minimal KDE Plasma (recommended) or KDE Plasma Mobile Desktops:
	- ```plasma-login-manager``` default display manager for most recent Plasma experience

- Minimal Gnome Desktop:
	- ```unzip``` for gnome extensions to work OOTB
	- ```gnome-shell-extension-appindicator``` & ```gnome-shell-extension-screen-autorotate``` for better Gnome experience
	
	
- Minimal Phosh Desktop
 
 
- Common Packages:
	- ```plymouth``` & ```plymouth-theme-spinner``` for fedora boot & shutdown animations
	- ```fish``` for a better command line experience, default for ```user```
	- ```tuned``` & ```tuned-ppd``` for better performance and power profiles in Gnome and KDE
	- ```widevine-installer``` from Asahi Linux

	- sensible default packages

#### [Installation guide](./INSTALL.md)
#### [Image building guide](./BUILD.md)

### User Notes:
- The root password is **fedora**
- The user password is 147147

- Kernel updates are handled by dnf. Updated boot image will be flashed to the active slot
- Bluetooth works OOTB with ```bluez-5.84-2.fc43``` which is therefore version locked. If this causes issues with upgrading using dnf, remove the versionlock, upgrade normally, then downgrade bluez again and readd the versionlock.

### Issues (all flavors):
- Front camera doesnt work and even though it never did for me, the back one has been reported to work (poorly) by others though
- Sensors may break after suspend 
- Sensors are disabled by default, to enable install ```pipa-sensors``` package and enable ```iio-sensor-proxy``` and ```hexagonrpcd-sdsp``` services
- Hall Sensor for flip case works and properly suspends and wakes the system

### Tips and Tricks:
- Run ```widevine-installer``` to install the Widevinde CDM for Firefox and Chromium based browsers to watch Netflix, Prime, Spotify etc, works for system packages only (The widevine CDM module is not altered in any way, nor ist preinstalled or in any way distributed by me)
- KDE Flavors: 
	- Apply the screen rotation to plasmalogin in Settings -> Login Screen -> Apply Plasma Settings...
- Gnome Flavor:
	- Configure Gnome Rotation Extension as manual Rotation toggle
	- Install [GJS OSK extension](https://github.com/Vishram1123/gjs-osk) to make the Gnome OSK usable (if your enter key gets stuck aswell, remove it)
	- Install [TouchUP extension](https://github.com/mityax/gnome-extension-touchup) to make the Gnome Shell more usable on a Touchscreen

## Credits:
- [Pocketblue](https://github.com/pocketblue) for COPR Repos, packages & their awesome work
- [pipa-fedora-builder](https://github.com/timoxa0/pipa-fedora-builder) original scripts this is forked from, by timoxa0 (thanks!!!)
- [nabu-fedora-builder](https://github.com/nik012003/nabu-fedora-builder) original original scripts
- [Kernel port](https://github.com/pipa-mainline/linux) by adomerle, V1p0ll, Lukapanio, domin746826 and others
- [Void templates](https://github.com/pipa-mainline/void-pipa) by adomerle
