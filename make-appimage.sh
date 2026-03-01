#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export ADD_HOOKS="self-updater.bg.hook"
export OUTPATH=./dist
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export STRACE_TIME=10
export DEPLOY_OPENGL=1
export DEPLOY_SYS_PYTHON=1
export DEPLOY_LOCALE=1
export DEPLOY_SDL=1
export DEPLOY_LIBHEIF=1
export DESKTOP=/usr/share/applications/gimp.desktop
export ICON=/usr/share/icons/hicolor/256x256/apps/gimp.png
export APPNAME=GIMP
export OPTIMIZE_LAUNCH=1

# Deploy dependencies
quick-sharun \
	/usr/bin/gimp*               \
	/usr/lib/gimp                \
	/usr/bin/gjs*                \
	/usr/lib/libgimp*            \
	/usr/lib/libcfitsio.so*      \
	/usr/lib/libgthread-2.0.so*  \
	/usr/lib/libjbig2dec*        \
	/usr/lib/libXmu.so*          \
	/usr/lib/libwebpdemux.so*    \
	/usr/lib/libgs.so*           \
	/usr/lib/libgpm*             \
	/usr/lib/libpaper*           \
	/usr/lib/libXpm.so*          \
	/usr/lib/libwmf*             \
	/usr/lib/libaa.so*           \
	/usr/lib/libmng.so*          \
	/usr/share/pixmaps           \
	/etc/gimp                    \
	/usr/share/gir-1.0

# ADD PHOTOGIMP
PHOTOGIMP="https://github.com/Diolinux/PhotoGIMP/releases/latest/download/PhotoGIMP-linux.zip"
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

sed -i \
	-e 's|Exec=.*|Exec=env ENABLE_PHOTO_GIMP=1 gimp %U|g' \
	-e 's|StartupWMClass=.*|StartupWMClass=gimp|g'        \
	-e 's|TryExec=.*|TryExec=gimp|g'                      \
	./AppDir/PhotoGIMP/.local/share/applications/PhotoGIMP-AppImage.desktop

# Fix wrong window class in .desktop
sed -i 's|StartupWMClass=.*|StartupWMClass=gimp|' ./AppDir/*.desktop

# Turn AppDir into AppImage
quick-sharun --make-appimage
