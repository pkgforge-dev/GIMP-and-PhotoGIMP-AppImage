#!/bin/sh

set -eu

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export VERSION="$(pacman -Q gimp | awk 'NR==1 {print $2; exit}')"
echo "$VERSION" > ~/version
export STRACE_TIME=20
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
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

cp /usr/share/applications/gimp.desktop            ./
cp /usr/share/icons/hicolor/256x256/apps/gimp.png  ./
cp /usr/share/icons/hicolor/256x256/apps/gimp.png  ./.DirIcon

# Fix wrong window class in .desktop
sed -i 's|StartupWMClass=.*|StartupWMClass=Gimp|' ./gimp.desktop 

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
echo '#!/bin/sh
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
CONFIGDIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATADIR="${XDG_DATA_HOME:-$HOME/.local/share}"
ARGV0="${ARGV0:-$0}"

export GIMP3_DATADIR="$CURRENTDIR"/share/gimp/3.0
export GIMP3_SYSCONFDIR="$CURRENTDIR"/etc/gimp/3.0
export GIMP3_LOCALEDIR="$CURRENTDIR"/share/locale
export GIMP3_PLUGINDIR="$CURRENTDIR"/shared/lib/gimp/3.0

_install_photogimp() {
	if [ ! -d "$CONFIGDIR"/PhotoGIMP ]; then
		mkdir -p "$CONFIGDIR" "$DATADIR"/applications
		cp -rv "$CURRENTDIR"/PhotoGIMP/.config/GIMP    "$CONFIGDIR"/PhotoGIMP
		cp -rvn "$CURRENTDIR"/PhotoGIMP/.local/share/* "$DATADIR"
	fi
}

_remove_photogimp() {
	set -u
	to_remove="$(find "$DATADIR"/icons/hicolor "$DATADIR"/applications -type f \
		 \( -name "photogimp.*" -o -name "PhotoGIMP-AppImage.desktop" \))"

	if [ -z "$to_remove" ] && [ ! -d "$CONFIGDIR"/PhotoGIMP ]; then
		>&2 echo ""
		>&2 echo " PhotoGIMP is NOT installed!"
		>&2 echo ""
		exit 1
	fi
	echo ""
	[ -d "$CONFIGDIR"/PhotoGIMP ] && echo "$CONFIGDIR/PhotoGIMP <------ IMPORTANT"
	echo "$to_remove"
	echo "---------------------------------------------"
	printf "          Remove the above? (y/N) : "
	read -r yn
	if echo "$yn" | grep -qi "^y"; then
		rm -rf "$CONFIGDIR"/PhotoGIMP
		find "$DATADIR"/icons/hicolor "$DATADIR"/applications -type f \
		 \( -name "photogimp.png" -o -name "PhotoGIMP-AppImage.desktop" \) -delete
		echo ""
		echo " Removed PhotoGIMP."
		echo ""
		exit 0
	else
		>&2 echo ""
		>&2 echo " Aborting..."
		>&2 echo ""
		exit 1
	fi
}

if [ "$1" = "--photogimp" ]; then
	shift
	ENABLE_PHOTO_GIMP=1
elif [ "$1" = "--remove-photogimp" ]; then
	shift
	_remove_photogimp
elif basename "$ARGV0" | grep -qi "photogimp"; then
	ENABLE_PHOTO_GIMP=1
fi

if [ "$ENABLE_PHOTO_GIMP" = 1 ]; then
	_install_photogimp
	export GIMP3_DIRECTORY="$CONFIGDIR"/PhotoGIMP/3.0
	if [ -n "$APPIMAGE" ]; then
		sed -i -e "s|^TryExec=.*|TryExec=$APPIMAGE|g" \
			-e "s|^Exec=.*|Exec=env ENABLE_PHOTO_GIMP=1 $APPIMAGE %U|g" \
			"$DATADIR"/applications/PhotoGIMP-AppImage.desktop
	fi
fi

# needed for patched away hardcoded paths in gimp
# this way we dont need to change the current working dir
ln -sfn "$CURRENTDIR"/share /tmp/xdg69
ln -sfn "$CURRENTDIR"/lib   /tmp/o_0

exec "$CURRENTDIR"/bin/gimp "$@"' > ./AppRun
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
	echo 'StartupWMClass=Gimp' >> ./PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop
fi
if ! grep -q 'TryExec=' ./PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop; then
	echo 'TryExec=gimp' >> ./PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop
fi

sed -i -e 's|Exec=.*|Exec=env ENABLE_PHOTO_GIMP=1 gimp %U|g' \
	-e 's|StartupWMClass=.*|StartupWMClass=Gimp|g' \
	-e 's|TryExec=.*|TryExec=gimp|g' ./PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop

# MAKE APPIMAGE WITH URUNTIME
cd ..
wget "$URUNTIME" -O ./uruntime
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
	--categorize=hotness --hotness-list=gimp.dwfsprof \
	--compression zstd:level=22 -S25 -B8 \
	--header uruntime \
	-i ./AppDir -o ./GIMP-"$VERSION"-anylinux-"$ARCH".AppImage

wget -O ./pelf "https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH" 
chmod +x ./pelf
echo "Generating [dwfs]AppBundle...(Go runtime)"
./pelf --add-appdir ./AppDir \
	--appbundle-id="GIMP-$VERSION" \
	--compression "-C zstd:level=22 -S25 -B8" \
	--output-to GIMP-"$VERSION"-anylinux-"$ARCH".dwfs.AppBundle

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
zsyncmake *.AppBundle -u *.AppBundle

echo "All Done!"
