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
	gvfs             \
	libheif          \
	libmng           \
	librsvg          \
	strace           \
	unzip            \
	wget             \
	xorg-server-xvfb \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-common --prefer-nano

# set version
pacman -Q gimp | awk '{print $2; exit}' > ~/version
