#!/bin/sh

set -eux

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export VERSION="$(cat ~/version)"
export STRACE_TIME=20
export OUTNAME=GIMP-"$VERSION"-anylinux-"$ARCH".AppImage
export DESKTOP=/usr/share/applications/gimp.desktop  
export ICON=/usr/share/icons/hicolor/256x256/apps/gimp.png
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"

LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"
PHOTOGIMP="https://github.com/Diolinux/PhotoGIMP/releases/latest/download/PhotoGIMP-linux.zip"

# Prepare AppDir
mkdir -p ./AppDir/etc ./AppDir/share/icons
cd ./AppDir

# ADD LIBRARIES
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -k -s -e -y \
	--python-pkg PyGObject \
	/usr/bin/gimp* \
	/usr/bin/gjs* \
	/usr/bin/gegl \
	/usr/lib/libgimp* \
	/usr/lib/gimp/*/modules/* \
	/usr/lib/gdk-pixbuf-*/*/*/* \
	/usr/lib/gtk-*/*/*/* \
	/usr/lib/gio/*/* \
	/usr/lib/babl-*/* \
	/usr/lib/gegl-*/* \
	/usr/lib/gvfs/* \
	/usr/lib/libcfitsio.so* \
	/usr/lib/libgthread-2.0.so* \
	/usr/lib/libheif/* \
	/usr/lib/libjbig2dec* \
	/usr/lib/libgpm* \
	/usr/lib/libpaper* \
	/usr/lib/libSDL* \
	/usr/lib/libXpm.so* \
	/usr/lib/libheif.so* \
	/usr/lib/libwmf* \
	/usr/lib/libudev.so* \
	/usr/lib/libaa.so* \
	/usr/lib/libmng.so*

cp -vr /usr/share/gimp           ./share
cp -vr /usr/share/locale         ./share
find ./share/locale -type f ! -name '*glib*' ! -name '*gimp*' ! -name '*gegl*' -delete
cp -vr /usr/lib/locale           ./shared/lib
cp -vr /usr/share/pixmaps        ./share
cp -vr /usr/share/icons/hicolor  ./share/icons
cp -vr /etc/gimp                 ./etc
cp -vr /usr/share/vala           ./share
cp -vr /usr/share/gir-1.0        ./share
cp -vn /usr/lib/gegl-*/*.json    ./shared/lib/gegl-*
cp -rvn /usr/lib/gimp            ./shared/lib


# sharun the gimp plugins
echo "Sharunning the gimp plugins..."
bins_to_find="$(find ./lib/gimp -exec file {} \; | grep -i 'elf.*executable' | awk -F':' '{print $1}')"
for plugin in $bins_to_find; do
	mv -v "$plugin" ./shared/bin && ln ./sharun "$plugin"
	echo "Sharan $plugin"
done

# HACK
find ./lib -type f -name 'libgimpwidgets*' -exec sed -i 's|/usr/share|/tmp/xdg69|g' {} \;

# HACK2
find ./lib -type f -name 'libgegl*' -exec sed -i 's|/usr/lib|/tmp/o_0|g' {} \;
echo 'unset GEGL_PATH' > ./.env

# PREPARE SHARUN
chmod +x ./AppRun
./sharun -g

# ADD PHOTOGIMP
wget "$PHOTOGIMP" -O ./PhotoGIMP.zip
unzip ./PhotoGIMP.zip
rm -f ./PhotoGIMP.zip
mv -v ./PhotoGIMP-linux ./PhotoGIMP
mv -v ./PhotoGIMP/.local/share/applications/org.gimp.GIMP.desktop \
	./PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop

if ! grep -q 'StartupWMClass=' ./PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop; then
	echo 'StartupWMClass=gimp' >> ./PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop
fi
if ! grep -q 'TryExec=' ./PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop; then
	echo 'TryExec=gimp' >> ./PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop
fi

sed -i -e 's|Exec=.*|Exec=env ENABLE_PHOTO_GIMP=1 gimp %U|g' \
	-e 's|StartupWMClass=.*|StartupWMClass=gimp|g' \
	-e 's|TryExec=.*|TryExec=gimp|g' ./PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop

# Fix wrong window class in .desktop
sed -i 's|StartupWMClass=.*|StartupWMClass=gimp|' "$DESKTOP"

# TODO remove me once we migrate to quick-sharun
cp -v "$DESPTOP" ./
cp -v "$ICON"    ./
cp -v "$ICON"    ./.DirIcon

# MAKE APPIMAGE WITH URUNTIME
cd ..
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
	--compression "-C zstd:level=22 -S25 -B8" \
	--output-to GIMP-"$VERSION"-anylinux-"$ARCH".dwfs.AppBundle

echo "Generating zsync file..."
zsyncmake *.AppBundle -u *.AppBundle

mkdir -p ./dist
mv -v ./*.AppImage*  ./dist
mv -v ./*.AppBundle* ./dist
mv -v ~/version      ./dist

echo "All Done!"
