#!/bin/bash
apt-get update
apt-get install -y build-essential clang wget python2.7 python3 python3-pip python3-distutils libxml2-dev cmake git p7zip-full bsdtar curl cpio xz-utils patch pixz llvm

cd -- "$(dirname $0)"
source ci.sh
