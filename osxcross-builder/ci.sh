#!/bin/bash -e

cd -- "$(dirname $0)"
pip3 install -r requirements.txt
if [ -f .cred ]; then
  echo 'Importing keys...'
  source ./.cred
  rm -f ./.cred
fi

chmod a+x create_osxcross_toolchain.sh
export OC_SYSROOT='/opt/osxcross'
export XCODE_VER='10'
export SLIENT_RUNNING='1'
export TARGET_MAC_VER='10.14'
./create_osxcross_toolchain.sh
bash ./osxcross/install_rt.sh

# Tests
printf '\n\n\n\n\n\nTesting the toolchain...'
export PATH=$PATH:"${OC_SYSROOT}/bin/"
pushd osxcross/oclang/
AVAIL_ARCH=('x86_64' 'x86_64h')
for arch in ${AVAIL_ARCH[@]}
do
  OC_CXX="${arch}-apple-darwin18-clang++-libc++"
  OC_GCXX="${arch}-apple-darwin18-clang++-stdc++"
  OC_CC="${arch}-apple-darwin18-clang"
  echo "Compiling C program for ${arch}..."
  ${OC_CC} -Wall 'test.c' -o 'test'
  echo "Compiling C++ 0x program for ${arch}..."
  ${OC_CXX} -Wall 'test.cpp' -o 'test_cpp'
  echo "Compiling C++ 14 program for ${arch}..."
  ${OC_CXX} -Wall 'test_libcxx.cpp' -std=c++14 -o 'test_cxx'
done
