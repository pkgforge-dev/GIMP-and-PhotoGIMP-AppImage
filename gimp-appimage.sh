#!/bin/sh

set -eux

ARCH="$(uname -m)"
VERSION="$(cat ~/version)"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"
PHOTOGIMP="https://github.com/Diolinux/PhotoGIMP/releases/latest/download/PhotoGIMP-linux.zip"

export ADD_HOOKS="self-updater.bg.hook"
export STRACE_TIME=15
export DEPLOY_OPENGL=1
export DEPLOY_PYTHON=1
export PYTHON_PACKAGES=PyGObject
export DESKTOP=/usr/share/applications/gimp.desktop
export ICON=/usr/share/icons/hicolor/256x256/apps/gimp.png
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export OUTNAME=GIMP-"$VERSION"-anylinux-"$ARCH".AppImage
export OPTIMIZE_LAUNCH=1

# ADD LIBRARIES
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun \
	/usr/bin/gimp*               \
	/usr/bin/gjs*                \
	/usr/bin/gegl                \
	/usr/lib/libgimp*            \
	/usr/lib/gimp/*/modules/*    \
	/usr/lib/gtk-*/*/*/*         \
	/usr/lib/gvfs/*              \
	/usr/lib/libcfitsio.so*      \
	/usr/lib/libgthread-2.0.so*  \
	/usr/lib/libheif/*           \
	/usr/lib/libjbig2dec*        \
	/usr/lib/libgpm*             \
	/usr/lib/libgs.so*           \
	/usr/lib/libpaper*           \
	/usr/lib/libSDL*             \
	/usr/lib/libXpm.so*          \
	/usr/lib/libheif.so*         \
	/usr/lib/libwmf*             \
	/usr/lib/libudev.so*         \
	/usr/lib/libaa.so*           \
	/usr/lib/libmng.so*

cp -vr /usr/lib/locale     ./AppDir/shared/lib
cp -vr /usr/share/pixmaps  ./AppDir/share
cp -vr /etc/gimp           ./AppDir/etc
cp -vr /usr/share/vala     ./AppDir/share
cp -vr /usr/share/gir-1.0  ./AppDir/share
cp -rvn /usr/lib/gimp      ./AppDir/shared/lib

# sharun the gimp plugins
echo "Sharunning the gimp plugins..."
bins_to_find="$(find ./AppDir/lib/gimp -exec file {} \; | grep -i 'elf.*executable' | awk -F':' '{print $1}')"
for plugin in $bins_to_find; do
	mv -v "$plugin" ./AppDir/shared/bin && ln -f ./AppDir/sharun "$plugin"
	echo "Sharan $plugin"
done

# ADD PHOTOGIMP
wget --retry-connrefused --tries=30 "$PHOTOGIMP" -O ./PhotoGIMP.zip
unzip ./PhotoGIMP.zip
rm -f ./PhotoGIMP.zip
mv -v ./PhotoGIMP-linux ./AppDir/PhotoGIMP
mv -v ./AppDir/PhotoGIMP/.local/share/applications/org.gimp.GIMP.desktop \
	./AppDir/PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop

if ! grep -q 'StartupWMClass=' ./AppDir/PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop; then
	echo 'StartupWMClass=gimp' >> ./AppDir/PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop
fi
if ! grep -q 'TryExec=' ./AppDir/PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop; then
	echo 'TryExec=gimp' >> ./AppDir/PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop
fi

sed -i -e 's|Exec=.*|Exec=env ENABLE_PHOTO_GIMP=1 gimp %U|g' \
	-e 's|StartupWMClass=.*|StartupWMClass=gimp|g' \
	-e 's|TryExec=.*|TryExec=gimp|g' ./AppDir/PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop

# Fix wrong window class in .desktop
sed -i 's|StartupWMClass=.*|StartupWMClass=gimp|' ./AppDir/*.desktop

# MAKE APPIMAGE WITH URUNTIME
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage

UPINFO="$(echo "$UPINFO" | sed 's#.AppImage.zsync#*.AppBundle.zsync#g')"
wget -O ./pelf "https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH"
chmod +x ./pelf
echo "Generating [dwfs]AppBundle...(Go runtime)"
./pelf --add-appdir ./AppDir \
	--appbundle-id="org.gimp.GIMP#github.com/$GITHUB_REPOSITORY:$VERSION@$(date +%d_%m_%Y)" \
	--appimage-compat \
	--disable-use-random-workdir \
	--add-updinfo "$UPINFO" \
	--compression "-C zstd:level=22 -S26 -B8" \
	--output-to ./GIMP-"$VERSION"-anylinux-"$ARCH".dwfs.AppBundle

echo "Generating zsync file..."
zsyncmake ./*.AppBundle -u ./*.AppBundle

mkdir -p ./dist
mv -v ./*.AppImage*  ./dist
mv -v ./*.AppBundle* ./dist
mv -v ~/version      ./dist

echo "All Done!"
