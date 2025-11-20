#!/bin/sh

set -eu

echo "Installing dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	aalib       \
	alsa-lib    \
	cfitsio     \
	ffmpeg      \
	ghostscript \
	gimp        \
	git         \
	gjs         \
	gvfs        \
	libheif     \
	libmng      \
	librsvg     \
	unzip

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs.sh --add-common --prefer-nano

# set version
pacman -Q gimp | awk '{print $2; exit}' > ~/version
