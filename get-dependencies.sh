#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	aalib            \
	alsa-lib         \
	cfitsio          \
	ffmpeg           \
	ghostscript      \
	gimp             \
	gimp-plugin-gmic \
	git              \
	gjs              \
	gvfs             \
	libheif          \
	libmng           \
	librsvg          \
	unzip

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano ffmpeg-mini x265-mini

# set version
pacman -Q gimp | awk '{print $2; exit}' > ~/version
