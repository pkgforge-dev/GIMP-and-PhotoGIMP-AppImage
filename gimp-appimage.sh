#!/bin/sh

set -eu

PACKAGE=gimp
DESKTOP=gimp.desktop
ICON=gimp.png

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export VERSION=$(pacman -Q $PACKAGE | awk 'NR==1 {print $2; exit}')

APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|continuous|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"

# Prepare AppDir
mkdir -p ./"$PACKAGE"/AppDir/shared/lib \
	./"$PACKAGE"/AppDir/usr/share/applications \
	./"$PACKAGE"/AppDir/etc
cd ./"$PACKAGE"/AppDir

cp -r /usr/share/gimp      ./usr/share
cp -r /usr/share/locale    ./usr/share
cp -r /usr/share/pixmaps   ./usr/share
cp -r /etc/gimp            ./etc

cp /usr/share/applications/$DESKTOP              ./usr/share/applications
cp /usr/share/applications/$DESKTOP              ./
cp /usr/share/icons/hicolor/256x256/apps/"$ICON" ./

ln -s ./usr/share  ./share
ln -s ./shared/lib ./lib

# ADD LIBRARIES
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
./lib4bin -p -v -r -s /usr/bin/gimp*
rm -f ./lib4bin

cp -nv /usr/lib/libgimp*      ./shared/lib
cp -nv /usr/lib/libaa*        ./shared/lib
cp -nv /usr/lib/libmng*       ./shared/lib
cp -nv /usr/lib/libgs*        ./shared/lib
cp -nv /usr/lib/libslang*     ./shared/lib
cp -nv /usr/lib/libijs*       ./shared/lib
cp -nv /usr/lib/libijs*       ./shared/lib
cp -nv /usr/lib/libjbig2dec*  ./shared/lib
cp -nv /usr/lib/libgpm*       ./shared/lib
cp -nv /usr/lib/libidn*       ./shared/lib
cp -nv /usr/lib/libpaper*     ./shared/lib

# CREATE APPRUN
echo '#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "${0}")")"

# We patched a relative path to the interpreter for the gimp plugins
# so we need to cd here for this to work
cd "$CURRENTDIR" || exit 1

# this can be improved to avoid setting this variable
export LD_LIBRARY_PATH="$CURRENTDIR/shared/lib:$LD_LIBRARY_PATH"

# set gimp variables
export GIMP2_DATADIR="$CURRENTDIR"/share/gimp/2.0
export GIMP2_SYSCONFDIR="$CURRENTDIR"/etc/gimp/2.0
export GIMP2_LOCALEDIR="$CURRENTDIR"/share/locale
export GIMP2_PLUGINDIR="$CURRENTDIR"/shared/lib/gimp/2.0

"$CURRENTDIR"/bin/gimp "$@"' > ./AppRun
chmod +x ./AppRun

# DEPLOY GIMP PLUGINS DEPENDENCIES
echo "Deploying gimp plugins..."
cp -rv /usr/lib/gimp     ./shared/lib
find ./shared/lib/gimp -type f -exec ldd {} \; \
	| awk -F"[> ]" '{print $4}' | xargs -I {} cp -vn {} ./shared/lib || true

# patch a relative interpreter path for the gimp plugins
# hopefully this can be avoided in the future
echo "Patching gimp plugins..."
patchelf --set-interpreter "./shared/lib/ld-linux-x86-64.so.2" \
	./shared/lib/gimp/2.0/plug-ins/*/*

# DEPLOY GDK
echo "Deploying gdk..."
GDK_PATH="$(find /usr/lib -type d -regex ".*/gdk-pixbuf-2.0" -print -quit)"
cp -rv "$GDK_PATH" ./shared/lib

echo "Deploying gdk deps..."
find ./shared/lib/gdk-pixbuf-2.0 -type f -name '*.so*' -exec ldd {} \; \
	| awk -F"[> ]" '{print $4}' | xargs -I {} cp -vn {} ./shared/lib || true

find ./shared/lib -type f -regex '.*gdk.*loaders.cache' \
	-exec sed -i 's|/.*lib.*/gdk-pixbuf.*/.*/loaders/||g' {} \;

# DEPLOY GTK
echo "Deploying gtk..."
cp -rv /usr/lib/gtk* ./shared/lib

echo "Deploying gdk deps..."
find ./shared/lib/gtk* -type f -name '*.so*' -exec ldd {} \; \
	| awk -F"[> ]" '{print $4}' | xargs -I {} cp -vn {} ./shared/lib || true

find ./shared/lib -type f -regex '.*gdk.*immodules.cache' \
	-exec sed -i 's|/.*lib.*/gtk.*/.*/3.0.0/||g' {} \;

# DEPLOY WHATEVER THESE ARE
echo "Deploying the rest of stuff..."
cp -rv /usr/lib/gio      ./shared/lib
cp -rv /usr/lib/babl-0.1 ./shared/lib
cp -rv /usr/lib/gegl-0.4 ./shared/lib
find ./shared/lib/*/* -type f -name '*.so*' -exec ldd {} \; \
	| awk -F"[> ]" '{print $4}' | xargs -I {} cp -vn {} ./shared/lib || true

./sharun -g

# MAKE APPIAMGE WITH FUSE3 COMPATIBLE APPIMAGETOOL
cd ..
wget -q "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool

./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n -u "$UPINFO" "$PWD"/AppDir "$PWD"/"$PACKAGE"-"$VERSION"-"$ARCH".AppImage

mv ./*.AppImage* ../
cd ..
rm -rf ./"$PACKAGE"
echo "All Done!"
