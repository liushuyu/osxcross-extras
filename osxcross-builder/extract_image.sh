#!/bin/bash -ex

if [[ "x${TARGET_MAC_VER}" == 'x' ]]; then
	export TARGET_MAC_VER='10.13'
fi

USEFUL_SUBPKG=('CLTools_Executables.pkg' "CLTools_SDK_macOS${TARGET_MAC_VER/./}.pkg")

function make_sdk_tbl() {
local THISDIR="$(dirname $0)"
local THISDIR="$(readlink -f $THISDIR)"
if ! which 7z > /dev/null 2>&1; then
	echo 'Please install p7zip!' && exit 1
fi

if [ "x$1" == 'x' ]; then
       echo "Usage: $0 <image.dmg>"
       exit 1
fi

if ! [ -f "$1" ]; then
	echo "File $1 not found!"
	exit 1
fi

unpack_archive "$1"
collect_sdk_files "$TMP/dist/" "$THISDIR"
rm -rf "$TMP"

unset TMP
}

# $1: path to the image
function unpack_archive() {
export TMP="$(mktemp -d -p .)"
pushd "$TMP"

echo "Decompressing image..."
7z x "$1"
find . -name "Command Line Tools*.pkg" -type f -exec cp {} ./target.pkg \;
7z x ./target.pkg > /dev/null
rm -f ./target.pkg
CPIO_FILE="$(mktemp --suffix '.cpio' -p "$PWD")"
echo "$CPIO_FILE"
for pkg in ${USEFUL_SUBPKG[@]}
do
	# remove end marker from previous cpio archive chunk
	# usually the end marker is the whole last line (ASCII cpio)
	# given the file is very large, we use `truncate` to speed up
	# sed or head is very slow in this case
	tail -n 1 "${CPIO_FILE}" | wc -c | xargs -I {} truncate "${CPIO_FILE}" -s -{}
	echo "Reconstructing image for package $pkg..."
	# cpio archives could be "accumulated" given that end marker is removed
	python3 ../unscramble.py "${pkg}/Payload" >> "${CPIO_FILE}"
done
mkdir dist && cd dist
echo 'Expanding archives...'
cpio -i < "${CPIO_FILE}"
cd ..
rm -f "${CPIO_FILE}"
popd
}

# $1: path to unpacked directory(-ies)
# $2: where to put the tarballs
function collect_sdk_files() {
# SDK folder usually appears in this location
SDK_LOCATION='Library/Developer/CommandLineTools/SDKs/'
LIBCXX='Library/Developer/CommandLineTools/usr/include/c++/v1/'
MANDIR='Library/Developer/CommandLineTools/usr/share/man/'
if ! [ -d "$1/${SDK_LOCATION}" ]; then
	echo -n 'Using heuristics to find SDK files... '
	SDK_LOCATION="$(find "$1" -name 'SDKs' -type d | head -n1)"
	if [ -z "${SDK_LOCATION}" ]; then
		echo 'Error: Unable to find SDK location'
		exit 1
	fi
	echo "${SDK_LOCATION}"
else
	SDK_LOCATION="$1/${SDK_LOCATION}"
fi

if ! [ -d "$1/${LIBCXX}" ]; then
	# LIBCXX headers are not vital, since there are stdc++ headers from GNU C++
	echo -n 'Using heuristics to find libc++ files... '
        LIBCXX="$(find "$1" -name 'v1' -type d | grep 'include/c++' | head -n1)"
	echo "$LIBCXX"
else
	LIBCXX="$1/${LIBCXX}"
fi

pushd "${SDK_LOCATION}"
SDKS=$(ls | grep "^MacOSX10.*" | grep -v "Patch")
popd

for i in $SDKS
do
	local TMPDIR="$(mktemp -d)"
	echo "Preparing SDK files for ${i/.sdk/} target..."
	cp -r "${SDK_LOCATION}/${i}/" "$TMPDIR"
	mkdir -p "$TMPDIR/$i/usr/include/c++"
	if ! [ -z "${LIBCXX}" ]; then
		cp -r "${LIBCXX}/" "$TMPDIR/$i/usr/include/c++"
	fi
	if [ -d "$1/$MANDIR" ]; then
		cp -r "$1/$MANDIR" "$TMPDIR/$i/usr/share/"
	fi

	echo "Compressing tarball for ${i/.sdk/} target..."
	pushd "$TMPDIR/"
	if which pixz > /dev/null 2>&1; then
		tar -Ipixz -cf "$2/$i.tar.xz" "$i/"
	else
		tar cJf "$2/$i.tar.xz" "$i/"
	fi
	popd

	rm -rf "TMPDIR"
done
}
