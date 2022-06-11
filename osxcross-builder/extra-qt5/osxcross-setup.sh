#!/usr/bin/bash -e

SDL2_REPACK='https://liushuyu.b-cdn.net/SDL2-2.0.22.macos.tar.xz'
QT_SDK_REPO='https://download.qt.io/online/qtsdkrepository/mac_x64/desktop'

# navigate to the URL above to find out the following parameters
QT_RELEASE='5.15.2'
QT_RL='0' # usually zero
QT_BUILD='202011130601'
QT_COMPONENTS=('qtbase' 'qtimageformats' 'qtmacextras' 'qtmultimedia' 'qttools')

mkdir -p osxcross
pushd osxcross

export PATH="/opt/osxcross/bin/:$PATH"

# sdl2 and osxcross
echo 'Downloading SDL2 binary...'
wget -q "${SDL2_REPACK}"

# Qt
QT_VERSION="${QT_RELEASE//./}"
for i in "${QT_COMPONENTS[@]}"; do
  echo "Downloading Qt prebuilt binary (${i})..."
  wget -q "${QT_SDK_REPO}/qt5_${QT_VERSION}/qt.qt5.${QT_VERSION}.clang_64/${QT_RELEASE}-${QT_RL}-${QT_BUILD}${i}-MacOS-MacOS_10_13-Clang-MacOS-MacOS_10_13-X86_64.7z"
done

mkdir -p qt5 && cd qt5
for i in ../*.7z; do
  echo "Extracting ${i}..."
  7z x "${i}"
done
mkdir -p '/opt/osxcross/macports/pkgs/opt/local/'
cp -r "${QT_RELEASE}/clang_64"/* '/opt/osxcross/macports/pkgs/opt/local/'
cd ..

# extract the files
SDL2_REPACK="$(basename ${SDL2_REPACK})"

echo 'Extracting SDL2 binary...'
tar xf "${SDL2_REPACK}"

echo 'Copying SDL2 binaries...'
cp -rv 'SDL2/SDL2.framework' '/opt/osxcross/macports/pkgs/opt/local/lib/'
# for some reasons, cmake is very confused if you don't put framework in :/System/Library/
# even from debug messages, cmake searched :/opt/loca/lib/ but it just don't feel like
# to use that
ln -sv '/opt/osxcross/macports/pkgs/opt/local/lib/SDL2.framework' /opt/osxcross/SDK/MacOSX*.sdk/System/Library/Frameworks/

echo "Building dependency resolvers..."

git clone --depth=1 'https://github.com/liushuyu/osxcross-extras'
pushd 'osxcross-extras'
./install_extras.sh
popd

rm -rf '/opt/osxcross/macports/pkgs/opt/local/bin/'*

echo 'Replacing Qt Tools with native binaries...'
for i in 'moc' 'qdbuscpp2xml' 'qdbusxml2cpp' 'qlalr' 'qmake' 'rcc' 'uic' 'lconvert' 'lrelease' 'lupdate'; do
  ln -sv "$(which $i)" '/opt/osxcross/macports/pkgs/opt/local/bin/'
done

popd
rm -rf osxcross

# suicide
rm -f "$0"
