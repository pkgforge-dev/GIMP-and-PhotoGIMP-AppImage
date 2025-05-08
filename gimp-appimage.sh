#!/bin/sh

set -eu

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export VERSION="$(pacman -Q gimp | awk 'NR==1 {print $2; exit}')"
echo "$VERSION" > ~/version
export STRACE_TIME=20
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|continuous|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"

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

# backport fix from interstellar
echo '#!/bin/sh
# xdg-open and gio-launch-desktop wrapper for sharun
# unsets env variables that cause issues to child processes
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
APPDIR="${APPDIR:-${SHARUN_DIR:-$(dirname "$CURRENTDIR")}}"
PATH="$(echo "$PATH" | sed "s|$CURRENTDIR||g")"
export PATH

problematic_vars="BABL_PATH GBM_BACKENDS_PATH GCONV_PATH GDK_PIXBUF_MODULEDIR \
	GDK_PIXBUF_MODULE_FILE GEGL_PATH GIO_MODULE_DIR GI_TYPELIB_PATH \
	GSETTINGS_SCHEMA_DIR GST_PLUGIN_PATH GST_PLUGIN_SCANNER GST_PLUGIN_SYSTEM_PATH \
	GST_PLUGIN_SYSTEM_PATH_1_0 GTK_DATA_PREFIX GTK_EXE_PREFIX GTK_IM_MODULE_FILE \
	GTK_PATH LIBDECOR_PLUGIN_DIR LIBGL_DRIVERS_PATH PERLLIB PIPEWIRE_MODULE_DIR \
	QT_PLUGIN_PATH SPA_PLUGIN_DIR TCL_LIBRARY TK_LIBRARY XTABLES_LIBDIR"
for var in $problematic_vars; do
	checkvar="$(printenv "$var" 2>/dev/null)"
	if [ -n "$checkvar" ] && echo "$checkvar" | grep -q "$APPDIR"; then
		unset "$var"
		>&2 echo "unset $var to prevent issues"
	fi
done

if [ "$(basename "$0")" = "gio-launch-desktop" ]; then
	export GIO_LAUNCHED_DESKTOP_FILE_PID=$$
	exec "$@"
else
	exec xdg-open "$@"
fi' > ./bin/xdg-open
ln -s ./xdg-open ./bin/gio-launch-desktop
chmod +x ./bin/xdg-open

#remove fullpath from gio libs
sed -i 's|/usr/lib/gio-launch-desktop|/kek/lib/gio-launch-desktop|g' ./shared/lib/libgio-*.so*

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
export GIMP3_DATADIR="$CURRENTDIR"/share/gimp/3.0
export GIMP3_SYSCONFDIR="$CURRENTDIR"/etc/gimp/3.0
export GIMP3_LOCALEDIR="$CURRENTDIR"/share/locale
export GIMP3_PLUGINDIR="$CURRENTDIR"/shared/lib/gimp/3.0

ln -sfn "$CURRENTDIR"/share /tmp/xdg69
ln -sfn "$CURRENTDIR"/lib   /tmp/o_0

exec "$CURRENTDIR"/bin/gimp "$@"' > ./AppRun
chmod +x ./AppRun
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
	--categorize=hotness --hotness-list=gimp.dwfsprof \
	--compression zstd:level=22 -S25 -B8 \
	--header uruntime \
	-i ./AppDir -o ./GIMP-"$VERSION"-anylinux-"$ARCH".AppImage

wget -qO ./pelf "https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH" 
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
