#!/bin/bash
apt-get update
apt-get install -y build-essential clang wget python2.7 python3 python3-distutils cmake git p7zip-full bsdtar curl cpio xz-utils patch pixz llvm

curl -sS https://bootstrap.pypa.io/get-pip.py | python3
cd -- "$(dirname $0)"
source ci.sh
