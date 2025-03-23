#!/bin/sh

set -eu

PACKAGE=gimp
DESKTOP=gimp.desktop
ICON=gimp.png

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export VERSION="$(pacman -Q $PACKAGE | awk 'NR==1 {print $2; exit}')"
export STRACE_TIME=15

UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|continuous|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"

# Prepare AppDir
mkdir -p ./AppDir/shared/lib ./AppDir/share ./AppDir/etc
cd ./AppDir

cp -vr /usr/share/gimp      ./share
cp -vr /usr/share/locale    ./share
cp -vr /usr/lib/locale      ./shared/lib
cp -vr /usr/share/pixmaps   ./share
cp -vr /etc/gimp            ./etc

cp /usr/share/applications/"$DESKTOP"             ./
cp /usr/share/icons/hicolor/256x256/apps/"$ICON"  ./
ln -s ./"$ICON"    ./.DirIcon
ln -s ./           ./usr

# ADD LIBRARIES
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
./lib4bin -p -v -k -s \
	/usr/bin/gimp* \
	/usr/lib/libgimp* \
	/usr/lib/gimp/*/modules/* \
	/usr/lib/gdk-pixbuf-*/*/*/* \
	/usr/lib/gtk-*/*/*/* \
	/usr/lib/gio/*/* \
	/usr/lib/babl-*/* \
	/usr/lib/gegl-*/* \
	/usr/lib/gvfs/* \
	/usr/lib/libgthread-2.0.so* \
	/usr/lib/libheif/* \
	/usr/lib/libaa* \
	/usr/lib/libasound.so* \
	/usr/lib/libmng* \
	/usr/lib/libgs* \
	/usr/lib/libslang* \
	/usr/lib/libijs* \
	/usr/lib/libijs* \
	/usr/lib/libjbig2dec* \
	/usr/lib/libgpm* \
	/usr/lib/libidn* \
	/usr/lib/libpaper* \
	/usr/lib/libSDL* \
	/usr/lib/libXpm.so* \
	/usr/lib/libheif.so* \
	/usr/lib/libwmf* \
	/usr/lib/libudev.so* \
	/usr/lib/libdl.so.2

cp -vn /usr/lib/gegl-*/*.json ./shared/lib/gegl-*
cp -rvn /usr/lib/gimp         ./shared/lib

# sharun the gimp plugins
echo "Sharunning the gimp plugins..."
bins_to_find="$(find ./shared/lib/gimp/3.0 -exec file {} \; | grep -i 'elf.*executable' | awk -F':' '{print $1}')"
for plugin in $bins_to_find; do
	mv -v "$plugin" ./shared/bin && ln -sfr ./sharun "$plugin"
	echo "Sharan $plugin"
done

# FIXME we should avoid this because it results in a need to change the current workign dir
# For some reason setting BABL_PATH and GEGL_PATH causes a ton of errors to show up
# Lets use the good old binary patching
sed -i 's|/usr|././|' ./shared/lib/libbabl* ./shared/lib/libgegl*

# PREPARE SHARUN
echo 'SHARUN_WORKING_DIR=${SHARUN_DIR}
GIMP3_DATADIR=${SHARUN_DIR}/share/gimp/3.0
GIMP3_SYSCONFDIR=${SHARUN_DIR}/etc/gimp/3.0
GIMP3_LOCALEDIR=${SHARUN_DIR}/share/locale
GIMP3_PLUGINDIR=${SHARUN_DIR}/shared/lib/gimp/3.0
unset BABL_PATH
unset GEGL_PATH' > ./.env

ln ./sharun ./AppRun
./sharun -g

# MAKE APPIMAGE WITH URUNTIME
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

# Keep the mount point (speeds up launch time)
sed -i 's|URUNTIME_MOUNT=[0-9]|URUNTIME_MOUNT=0|' ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S23 -B32 \
	--header uruntime \
	-i ./AppDir -o "$PACKAGE"-"$VERSION"-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"
