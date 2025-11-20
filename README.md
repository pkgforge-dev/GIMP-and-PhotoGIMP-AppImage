# GIMP-and-PhotoGIMP-AppImage 🐧

[![GitHub Downloads](https://img.shields.io/github/downloads/pkgforge-dev/GIMP-and-PhotoGIMP-AppImage/total?logo=github&label=GitHub%20Downloads)](https://github.com/pkgforge-dev/GIMP-and-PhotoGIMP-AppImage/releases/latest)
[![CI Build Status](https://github.com//pkgforge-dev/GIMP-and-PhotoGIMP-AppImage/actions/workflows/appimage.yml/badge.svg)](https://github.com/pkgforge-dev/GIMP-and-PhotoGIMP-AppImage/releases/latest)

* [Latest Stable Release](https://github.com/pkgforge-dev/GIMP-and-PhotoGIMP-AppImage/releases/latest)

---

Unofficial AppImage of GIMP that includes PhotoGIMP. 

To use PhotoGIMP **simply rename the AppImage to contain PhotoGIMP in the filename**:

* `PhotoGIMP.AppImage` and plain `photogimp`. Setting env var `ENABLE_PHOTO_GIMP=1` or passing the flag `--photogimp` also work.

* This will cause it to create a `$XDG_CONFIG_HOME/PhotoGIMP` directory and copy over the PhotoGIMP config files.

* It will also make a desktop entry in `$XDG_DATA_HOME/applications/PhotoGIMP-AppImage.desktop` and copy needed icons to `$XDG_DATA_HOME/icons`

Once done you will be able to keep using PhotoGIMP by launching the new desktop entry, you are also able to use both regular GIMP and PhotoGIMP both at the same time.

* **To uninstall** PhotoGIMP simply run it with the `--remove-photogimp` flag.

----------------------------------------

AppImage made using [sharun](https://github.com/VHSgunzo/sharun), which makes it extremely easy to turn any binary into a portable package without using containers or anything like that.

**This AppImage bundles everything and should work on any linux distro, even on musl based ones.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -e pkgforge-dev/GIMP-appimage gimp`

* [dbin](https://github.com/xplshn/dbin) `dbin install gimp.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install gimp`

This AppImage can work **without FUSE** at all thanks to the [uruntime](https://github.com/VHSgunzo/uruntime)

<details>
  <summary><b><i>raison d'être</i></b></summary>
    <img src="https://github.com/user-attachments/assets/d40067a6-37d2-4784-927c-2c7f7cc6104b" alt="Inspiration Image">
  </a>
</details>

---

More at: [AnyLinux-AppImages](https://pkgforge-dev.github.io/Anylinux-AppImages/) 
