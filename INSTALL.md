# Installation guide

<details>
  <summary><strong>Notes</strong></summary>

- Kernel updates are handled by dnf. Updated boot image will be flashed to the active slot
- Sensors may break after suspend, everything else should work as expected
- Sensors are disabled by default, to enable install ```pipa-sensors``` package and enable ```iio-sensor-proxy``` and ```hexagonrpcd-sdsp``` services

</details>

<details>
  <summary><strong>Singleboot installation</strong></summary>

#### Reboot your tablet into bootloader mode by holding ```Volume Down``` and ```Power``` buttons

#### Flash boot image
```bash
fastboot flash boot_ab boot.img
```

#### Flash rootfs image
```bash
fastboot flash userdata root.img
```

#### Clear dtbo partition
```bash
fastboot erase dtbo
```

#### Exit bootloader mode
```bash
fastboot reboot
```

</details>

<details>
  <summary><strong>Dualboot installation (untested)</strong></summary>

### Dualboot notes
#### <strong>WARNING:</strong> 
These instructions are taken 1:1 from the Fedora 42 installation instructions and untested by me! If you have successfully set up a dualboot environment with them, please open a PR removing this warning. 

---
- Repartition required
- Recommended slots configuration: 
    - Slot A: Android
    - Slot B: Fedora linux
- To switch slot from linux use ```sudo qbootctl -s [a|b]```
- To switch slot from android use [Boot Control](https://github.com/capntrips/BootControl) app
- Disable Android OTA updates in settings. Otherwise it will override Fedora installation in the other slot

#### Reboot your tablet into bootloader mode by holding ```Volume Down``` and ```Power``` buttons

#### Flash boot image to slot b
```bash
fastboot flash boot_b boot.img
```

#### Flash rootfs image
```bash
fastboot flash fedora_partition_name_here root.img
```

#### Clear dtbo partition in slot b
```bash
fastboot erase dtbo_b
```

#### Exit bootloader mode
```bash
fastboot reboot
```
</details>
