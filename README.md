# GIMP-and-PhotoGIMP-AppImage

Unofficial AppImage of GIMP that includes PhotoGIMP, in order to use PhotoGIMP simply run the AppImage once this way: 

```
ENABLE_PHOTO_GIMP=1 ./GIMP-3.0.2-3-anylinux-x86_64.AppImage
```

* This will cause it to create a `$XDG_CONFIG_HOME/PhotoGIMP` directory and copy over the PhotoGIMP config files.

* It will also make a desktop entry in `$XDG_DATA_HOME/applications/PhotoGIMP-AppImage.desktop` and copy needed icons to `$XDG_DATA_HOME/icons`

Once done you will be able to keep using PhotoGIMP by launching the new desktop entry, you will also be able to keep using regular GIMP both at the same time.  

----------------------------------------

AppImage made using [sharun](https://github.com/VHSgunzo/sharun), which makes it extremely easy to turn any binary into a portable package without using containers or anything like that.

**This AppImage bundles everything and should work on any linux distro, even on musl based ones.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -e pkgforge-dev/GIMP-appimage gimp`

* [dbin](https://github.com/xplshn/dbin) `dbin install gimp.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install gimp`

This appimage works without fuse2 as it can use fuse3 instead, it can also work without fuse at all thanks to the [uruntime](https://github.com/VHSgunzo/uruntime)

<details>
  <summary><b><i>raison d'être</i></b></summary>
    <img src="https://github.com/user-attachments/assets/d40067a6-37d2-4784-927c-2c7f7cc6104b" alt="Inspiration Image">
  </a>
</details>
