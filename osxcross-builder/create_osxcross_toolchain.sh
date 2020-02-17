#!/bin/bash -e

# $1: file name
function reconstruct_xcode_img() {
  source ./extract_image.sh
  make_sdk_tbl "$1"
}

function guess_targets() {
export OSX_VERSION_MIN='10.6';
case $1 in
  8*) TARGET=darwin17; GSTDCXX=1; ;;
  9*) TARGET=darwin17; GSTDCXX=1; ;;
  10*) TARGET=darwin18; GSTDCXX=0; export OSX_VERSION_MIN='10.9' ;;
  11*) TARGET=darwin19; GSTDCXX=0; export OSX_VERSION_MIN='10.9' ;;
*) echo "Unknown target $1" && exit 1; ;;
esac
}

if [[ "x$SLIENT_RUNNING" != 'x' ]]; then
  STDOUT="$(readlink -f osxcross_build.log)"
  echo "Running in less verbose mode. Detailed log: ${STDOUT}"
else
  STDOUT='/dev/stdout'
fi

if [[ "x$XCODE_VER" == 'x' ]]; then
  export XCODE_VER='9.2'
  echo "Xcode version not specified, using version $XCODE_VER"
fi

guess_targets "${XCODE_VER}"

echo 'Locating Xcode package...'
python3 fetch-xcode.py

echo "Downloading Xcode image file..."
bash download_xcode$XCODE_VER.sh >> "${STDOUT}" 2>&1

echo 'Making SDK tarball...'
reconstruct_xcode_img "$(readlink -f Command_Line_Tools*for_Xcode_${XCODE_VER}.dmg)"

echo 'Cloning osxcross repository...'
if [[ -d osxcross ]]; then
  rm -rf osxcross
fi

git clone --depth=50 https://github.com/tpoechtrager/osxcross/
cd osxcross

for i in ../*.patch; do
    echo "Applying $(basename "${i}")..."
    patch -Np1 -i "${i}"
done

mv ../MacOSX10.*.sdk.tar.* ./tarballs/

if [[ "x${OC_SYSROOT}" == 'x' ]]; then
  OC_SYSROOT="$(readlink -f ./target)"
fi

echo "Toolchain will be installed to ${OC_SYSROOT}"

export TARGET_DIR="${OC_SYSROOT}"
export OSXCROSS_OSX_VERSION_MIN="${OSX_VERSION_MIN}"
echo 'Building base toolchain...'
if ! UNATTENDED=1 ./build.sh >> "${STDOUT}"; then
  echo "Build failed."
  exit 1
fi

echo "Building extra tools..."

echo 'Building LLVM dsymutil...'
./build_llvm_dsymutil.sh >> "${STDOUT}"

if [[ "x${XCODE_NORT}" != 'x' ]]; then
  echo "Skipped building compiler runtime."
  exit
fi

RT_BUILD_LOG="$(mktemp --suffix='.log' -p .)"
echo 'Building LLVM compiler runtime...'
if [[ "${STDOUT}" == '/dev/stdout' ]]; then
  ./build_compiler_rt.sh | tee "${RT_BUILD_LOG}"
else
  ./build_compiler_rt.sh > "${RT_BUILD_LOG}"
  cat "${RT_BUILD_LOG}" >> "${STDOUT}"
fi

echo "Done. Your toolchain is built at ${OC_SYSROOT}"

set +e
if which perl; then
  perl -0777 -ne '/hand to install compiler-rt:\n(.*)/sg && print $1' < "${RT_BUILD_LOG}" > install_rt.sh
  echo 'Please run install_rt.sh as root manually to install LLVM runtime. This operation may corrupt your LLVM installation.'
  exit 0
fi
echo 'Please run the commands above as root to complete the installation'
