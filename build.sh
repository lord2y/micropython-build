#!/bin/bash
set -e

export PATH="$PATH:/root/.espressif/tools/xtensa-esp-elf/esp-14.2.0_20241119/xtensa-esp-elf/bin"

echo "========================================="
echo " Starting MicroPython 1.28 Build Loop   "
echo "========================================="

# 1. Fetch source code repositories securely
echo "--> Cloning MicroPython v1.28.0..."
if [ ! -d "src-micropython/.git" ]; then
  git clone -b v1.28.0 https://github.com/micropython/micropython.git src-micropython
fi

echo "--> Cloning ST7789 C Module Repository..."
#git clone -b micropython_v1.28.0 https://github.com/lord2y/st7789_mpy.git src-st7789
if [ ! -d "src-st7789/.git" ]; then
  git clone https://github.com/russhughes/st7789_mpy.git src-st7789
fi

# 2. Extract single target submodules shallowly to save memory/time
cd src-micropython
echo "--> Fetching essential core compiler dependencies..."
#git submodule update --init --depth 1 lib/utils lib/mp-readline
#git submodule update --init --recursive
git submodule update --init --recursive --depth 1 --jobs 8


echo "--> Fetching manual Berkeley DB mirror repository..."
rm -rf lib/berkeley-db-1.xx lib/berkeley-db
git clone https://github.com/pfalcon/berkeley-db-1.xx -b embedded lib/berkeley-db-1.xx

# 6. Initialize ESP-IDF Environment and Compile the Target ESP32 Firmware
echo "--> Exporting ESP-IDF toolchain variables..."
. /opt/esp/esp-idf/export.sh

# 4. Compile the target tool cross-compiler
echo "--> Compiling mpy-cross tool..."
cd /builds/src-micropython/mpy-cross
make -j$(nproc)

echo "--> compile ESP32 submodules"
cd /builds/src-micropython/ports/esp32
make BOARD=ESP32_GENERIC submodules

echo "--> Compiling physical ESP32 custom firmware for target: ${BOARD}..."
cd /builds/src-micropython/ports/esp32

if [ -d "/builds/src-micropython/ports/esp32/build-${BOARD}" ];then
  rm -fr "/builds/src-micropython/ports/esp32/build-${BOARD}"
fi
# Clean out old structural configs and compile using the variable flag
make clean
make -j$(nproc) BOARD=${BOARD} USER_C_MODULES=/builds/src-st7789/st7789/micropython.cmake

# Copy the specific output file (the output folder matches the board name)

#echo "--> Compiling physical ESP32 custom firmware..."
#cd /builds/src-micropython/ports/esp32
#make -j$(nproc) USER_C_MODULES=/builds/src-st7789/st7789/micropython.cmake

# 7. Collect output binaries into mounting shared workspace volume folder
echo "--> Copying completed builds to your local export window folder..."
mkdir -p /builds/output/esp32
#cp build-ESP32_GENERIC/firmware.bin /builds/output/esp32/firmware.bin
cp build-${BOARD}/firmware.bin /builds/output/esp32/firmware-${BOARD}.bin
xtensa-esp-elf-nm build-${BOARD}/micropython.elf | grep -i st7789

echo "========================================="
echo " SUCCESS: Binaries generated successfully! "
echo "========================================="

