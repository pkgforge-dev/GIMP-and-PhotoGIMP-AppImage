#!/bin/sh

set -eu

PACKAGE=gimp
DESKTOP=gimp.desktop
ICON=gimp.png

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export VERSION=$(pacman -Q $PACKAGE | awk 'NR==1 {print $2; exit}')

APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|GIMP-AppImage|continuous|*$ARCH.AppImage.zsync"
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
cp -nv /usr/lib/libgimp* ./shared/lib
rm -f ./lib4bin

# CREATE APPRUN
echo '#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "${0}")")"

export BABL_PATH=$CURRENTDIR/shared/lib/babl-0.1
export GEGL_PATH=$CURRENTDIR/shared/lib/gegl-0.4
export GIMP2_DATADIR="$CURRENTDIR"/share/gimp/2.0
export GIMP2_SYSCONFDIR="$CURRENTDIR"/etc/gimp/2.0
export GIMP2_PLUGINDIR="$CURRENTDIR"/shared/lib/gimp/2.0

# This is needed somehow?
export LD_LIBRARY_PATH="$CURRENTDIR/shared/lib:$LD_LIBRARY_PATH"

"$CURRENTDIR"/bin/gimp "$@"' > ./AppRun
chmod +x ./AppRun

# DEPLOY GIMP PLUGINS DEPENDENCIES
find ./shared/lib/gimp -type f -exec ldd {} \; \
	| awk -F"[> ]" '{print $4}' | xargs -I {} cp -vn {} ./shared/lib

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
cp -rv /usr/lib/gio      ./shared/lib
cp -rv /usr/lib/gimp     ./shared/lib
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
