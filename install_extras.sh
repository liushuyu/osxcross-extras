#!/bin/bash -e
BUILDDIR="$(mktemp -d)"
SRCDIR="$(readlink -f "$(dirname $0)")"

if [ -z "${OSXCROSS_HOST}" ]; then
  echo '[!] Environmental variable not initialized.'
  if ! which osxcross-conf; then
    echo '[!] osxcross-conf not found in $PATH. Please include the toolchain in $PATH!'
    exit 1
  fi
  echo '[-] Sourcing osxcross-conf...'
  eval "$(osxcross-conf)"
  CLANG_PATH=$(find "${OSXCROSS_CCTOOLS_PATH}/" -name 'x86_64-*clang')
  OSXCROSS_HOST="$(basename ${CLANG_PATH/-clang/})"
  export OSXCROSS_HOST="${OSXCROSS_HOST}"
  echo "[+] OSXCROSS_HOST set to ${OSXCROSS_HOST}"
fi

pushd "${BUILDDIR}"
for i in 'macdeployqt' 'macdylibbundler'; do
  rm -rf *
  echo "Building $i..."
  cmake "${SRCDIR}/$i/"
  cmake --build . -- -j$(nproc)
  # I guess you do not need macchangeqt...
  echo "$i -> /usr/bin/$i"
  cp "$i" '/usr/bin/'
done

rm -rf "${BUILDDIR}"
