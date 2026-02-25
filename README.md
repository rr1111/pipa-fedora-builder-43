# Fedora Linux 43 for Xiaomi Pad 6 (pipa)

### This is a fork of [pipa-fedora-builder](https://github.com/timoxa0/pipa-fedora-builder)

### Features:
- <strong>System fully updated to Fedora 43</strong>

- [Pocketblue](https://github.com/pocketblue) ```pocketblue``` & ```sm8250``` COPR repos and packages for more up to date packages

- Minimal Gnome Desktop with a few more packages installed by default, including: 
	- ```unzip``` for gnome extensions to work OOTB
	- ```plymouth``` & ```plymouth-theme-spinner``` for fedora boot & shutdown animations
	- ```fish``` for a better command line experience, default for ```user```
	- ```tuned``` & ```tuned-ppd``` for better performance and power profiles in Gnome and KDE
	- ```widevine-installer``` from Asahi Linux
	- ```gnome-shell-extension-appindicator``` & ```gnome-shell-extension-screen-autorotate``` for better Gnome experience
	- a few more Gnome default apps


#### [Installation guide](./INSTALL.md)
#### [Image building guide](./BUILD.md)

### User Notes

- The root password is **fedora**
- The user password is 147147

- Bluetooth works OOTB, but only with ```bluez-5.84-2.fc43``` which is therefore version locked. If this causes issues with upgrading using dnf, remove the versionlock ```dnf versionlock remove bluez``` and upgrade normally. 
Then downgrade bluez ```dnf install bluez-5.84-2.fc43``` and versionlock it again ```dnf versionlock add bluez``` to keep it at the working version.

### Tips and Tricks
- Configure Rotation Extension as manual Rotation toggle
- Install [GJS OSK extension](https://github.com/Vishram1123/gjs-osk) to make the Gnome OSK usable (if your enter key gets stuck aswell, remove it)
- Install [TouchUP extension](https://github.com/mityax/gnome-extension-touchup) to make the Gnome Shell more usable on a Touchscreen
- Run ```widevine-installer``` to install the Widevinde CDM for Firefox and Chromium based browsers to watch Netflix, Prime, Spotify etc, works for system packages only (The widevine CDM module is not altered in any way, nor ist preinstalled or in any way distributed by me)  

## Credits

- [Pocketblue](https://github.com/pocketblue) for COPR Repos, packages & their awesome work
- [pipa-fedora-builder](https://github.com/timoxa0/pipa-fedora-builder) original scripts this is froked from, by timoxa0 (thanks!!!)
- [nabu-fedora-builder](https://github.com/nik012003/nabu-fedora-builder) original original scripts
- [Kernel port](https://github.com/pipa-mainline/linux) by adomerle, V1p0ll, Lukapanio, domin746826 and others
- [Void templates](https://github.com/pipa-mainline/void-pipa) by adomerle
