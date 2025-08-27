#!/bin/sh

set -ex
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	aalib            \
	alsa-lib         \
	base-devel       \
	cfitsio          \
	curl             \
	ffmpeg           \
	ghostscript      \
	gimp             \
	git              \
	gjs              \
	gtk3             \
	gvfs             \
	libheif          \
	libmng           \
	librsvg          \
	patchelf         \
	strace           \
	unzip            \
	wget             \
	xorg-server-xvfb \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-opengl gtk3-mini opus-mini ffmpeg-mini libxml2-mini llvm-nano
