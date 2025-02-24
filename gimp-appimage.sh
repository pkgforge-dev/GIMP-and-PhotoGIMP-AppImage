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
URUNTIME=$(wget -q https://api.github.com/repos/VHSgunzo/uruntime/releases -O - \
	| sed 's/[()",{} ]/\n/g' | grep -oi "https.*appimage.*dwarfs.*$ARCH$" | head -1)

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

ln -s ./           ./usr
ln -s ./shared/lib ./lib
ln -s ./"$ICON"    ./.DirIcon

# ADD LIBRARIES
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -s -k \
	/usr/bin/gimp* \
	/usr/lib/libgimp* \
	/usr/lib/gdk-pixbuf-*/*/*/* \
	/usr/lib/gtk-*/*/*/* \
	/usr/lib/gio/*/* \
	/usr/lib/babl-*/* \
	/usr/lib/gegl-*/* \
	/usr/lib/libaa* \
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

cp -vn /usr/lib/gegl-*/* ./shared/lib/gegl-*
cp -rvn /usr/lib/gimp    ./shared/lib

# sharun the gimp plugins
echo "Sharunning the gimp plugins..."
mkdir -p ./shared/lib/gimp/2.0/shared/bin
cp ./sharun ./shared/lib/gimp/2.0
( cd ./shared/lib/gimp/2.0
	for plugin in ./plug-ins/*/*; do
		if file "$plugin" | grep -i 'elf.*executable'; then
			mv "$plugin" ./shared/bin && ln -s ../../sharun "$plugin"
			echo "Sharan $plugin"
		else
			echo "$plugin is not a binary, skipping..."
		fi
	done
)
ln -s ../../../ ./shared/lib/gimp/2.0/shared/lib

# PREPARE SHARUN
echo 'GIMP2_DATADIR=${SHARUN_DIR}/share/gimp/2.0
GIMP2_SYSCONFDIR=${SHARUN_DIR}/etc/gimp/2.0
GIMP2_LOCALEDIR=${SHARUN_DIR}/share/locale
GIMP2_PLUGINDIR=${SHARUN_DIR}/shared/lib/gimp/2.0' > ./.env

ln ./sharun ./AppRun
./sharun -g

# MAKE APPIMAGE WITH URUNTIME
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
printf "$UPINFO" > data.upd_info
llvm-objcopy --update-section=.upd_info=data.upd_info \
	--set-section-flags=.upd_info=noload,readonly ./uruntime
printf 'AI\x02' | dd of=./uruntime bs=1 count=3 seek=8 conv=notrunc

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S25 -B16 \
	--header uruntime \
	-i ./AppDir -o "$PACKAGE"-"$VERSION"-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"
