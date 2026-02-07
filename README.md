<div align="center">

# GIMP-and-PhotoGIMP-AppImage 🐧

[![GitHub Downloads](https://img.shields.io/github/downloads/pkgforge-dev/GIMP-and-PhotoGIMP-AppImage/total?logo=github&label=GitHub%20Downloads)](https://github.com/pkgforge-dev/GIMP-and-PhotoGIMP-AppImage/releases/latest)
[![CI Build Status](https://github.com//pkgforge-dev/GIMP-and-PhotoGIMP-AppImage/actions/workflows/appimage.yml/badge.svg)](https://github.com/pkgforge-dev/GIMP-and-PhotoGIMP-AppImage/releases/latest)
[![Latest Stable Release](https://img.shields.io/github/v/release/pkgforge-dev/GIMP-and-PhotoGIMP-AppImage)](https://github.com/pkgforge-dev/GIMP-and-PhotoGIMP-AppImage/releases/latest)

<p align="center">
  <img src="https://gitlab.gnome.org/GNOME/gimp-data/-/raw/main/icons/Legacy/128/gimp-wilber.png?ref_type=heads" width="128" />
  <img src="https://raw.githubusercontent.com/Diolinux/PhotoGIMP/refs/heads/master/.local/share/icons/hicolor/256x256/256x256.png" width="128" />
</p>

AppImage of GIMP that includes PhotoGIMP. 
| Latest Stable Release | Upstream URL |
| :---: | :---: |
| [Click here](https://github.com/pkgforge-dev/GIMP-and-PhotoGIMP-AppImage/releases/latest) | [Click here](https://github.com/pkgforge-dev/Anylinux-AppImages) |

</div>

---

To use PhotoGIMP **simply rename the AppImage to contain PhotoGIMP in the filename**:

* `PhotoGIMP.AppImage` and plain `photogimp`. Setting env var `ENABLE_PHOTO_GIMP=1` or passing the flag `--photogimp` also work.

* This will cause it to create a `$XDG_CONFIG_HOME/PhotoGIMP` directory and copy over the PhotoGIMP config files.

* It will also make a desktop entry in `$XDG_DATA_HOME/applications/PhotoGIMP-AppImage.desktop` and copy needed icons to `$XDG_DATA_HOME/icons`

Once done you will be able to keep using PhotoGIMP by launching the new desktop entry, you are also able to use both regular GIMP and PhotoGIMP both at the same time.

* **To uninstall** PhotoGIMP simply run it with the `--remove-photogimp` flag.

----------------------------------------

AppImage made using [sharun](https://github.com/VHSgunzo/sharun) and its wrapper [quick-sharun](https://github.com/pkgforge-dev/Anylinux-AppImages/blob/main/useful-tools/quick-sharun.sh), which makes it extremely easy to turn any binary into a portable package reliably without using containers or similar tricks. 

**This AppImage bundles everything and it should work on any Linux distro, including old and musl-based ones.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -e pkgforge-dev/GIMP-appimage gimp`

* [dbin](https://github.com/xplshn/dbin) `dbin install gimp.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install gimp`

This AppImage doesn't require FUSE to run at all, thanks to the [uruntime](https://github.com/VHSgunzo/uruntime).

This AppImage is also supplied with a self-updater by default, so any updates to this application won't be missed, you will be prompted for permission to check for updates and if agreed you will then be notified when a new update is available.

Self-updater is disabled by default if AppImage managers like [am](https://github.com/ivan-hc/AM), [soar](https://github.com/pkgforge/soar) or [dbin](https://github.com/xplshn/dbin) exist, which manage AppImage updates.

<details>
  <summary><b><i>raison d'être</i></b></summary>
    <img src="https://github.com/user-attachments/assets/d40067a6-37d2-4784-927c-2c7f7cc6104b" alt="Inspiration Image">
  </a>
</details>

---

More at: [AnyLinux-AppImages](https://pkgforge-dev.github.io/Anylinux-AppImages/)
