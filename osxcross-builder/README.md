### Semi Automated OSXCross Tool-chain builder

#### Requirements
1. 5+ GB free disk space
2. Decent network connection
3. Decent powerful computer with recent Linux distribution installed
4. Install `sed wget git cmake llvm clang clang++ bsdtar xz python2 python3 bash cmake`
5. A valid Apple ID (for download macOS SDK)

#### Instructions / Usage
1. Make sure your Apple ID has enrolled in Apple Developer program. If not, go to https://developer.apple.com/download/ to apply for the program.
2. [Recommended] Create a new directory and put all the files under this folder into that directory
3. Run `pip3 install -r requirements.txt`, if your Linux distribution uses Python 3 as default Python interpreter, run `pip install -r requirements.txt`
4. Run `XCODE_USERNAME=<your Apple ID> XCODE_PASSWORD=<your password> ./create_osxcross_toolchain.sh`
5. [Optional] If you want to install toolchain to somewhere else, set `OC_SYSROOT` environment variable to your desired location
6. Wait for ~1 hour and your tool chain will be built.
7. Run the commands that you are told to run to install runtime libraries.
