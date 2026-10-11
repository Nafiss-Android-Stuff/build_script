#!/bin/bash

echo "=== Cleaning up previous manifests and conflicting directories ==="
rm -rf .repo/local_manifests
rm -rf prebuilts/clang/host/linux-x86
rm -rf build

# Target directories to clear before cloning custom trees
DIRS_TO_REMOVE=(
    device/xiaomi/sm8250-common
    device/xiaomi/alioth
    vendor/xiaomi/alioth
    vendor/xiaomi/sm8250-common
    hardware/xiaomi
    kernel/xiaomi/sm8250
    hardware/dolby
    device/xiaomi/camera
    vendor/xiaomi/camera
    packages/apps/GameBar
)

for dir in "${DIRS_TO_REMOVE[@]}"; do
    rm -rf "$dir"
done

echo "=== Initializing Repo ==="
repo init --depth=1 -u https://github.com/HertzifyOS/android_manifest.git -b 17 --git-lfs

echo "=== Syncing Source Tree ==="
if [ -f /usr/bin/resync ]; then
    /usr/bin/resync
else
    /opt/crave/resync.sh
    /opt/crave/resync.sh
fi

echo "=== Cloning Device  Trees ==="
git clone https://github.com/Nafiss-Android-Stuff/android_device_xiaomi_sm8250-common.git -b Hertzify-17 device/xiaomi/sm8250-common
git clone https://github.com/Nafiss-Android-Stuff/android_device_xiaomi_alioth.git -b Hertzify-17 device/xiaomi/alioth
git clone https://github.com/Nafiss-Android-Stuff/android_vendor_xiaomi_alioth.git -b lineage-23.2 vendor/xiaomi/alioth
git clone https://github.com/Nafiss-Android-Stuff/android_vendor_xiaomi_sm8250-common.git -b 17 vendor/xiaomi/sm8250-common
git clone https://github.com/Nafis905/hardware_xiaomi.git -b lineage-23.2 hardware/xiaomi
git clone https://github.com/PocoF3Releases/kernel_xiaomi_sm8250.git -b aosp-17 --depth=1 kernel/xiaomi/sm825

echo "=== Cloning Extra Trees ==="
git clone https://github.com/Tsaritsa-Prjkt/android_hardware_dolby.git -b lineage-23.2 hardware/dolby
git clone https://github.com/PocoF3Releases/device_xiaomi_camera.git -b aosp-17 device/xiaomi/camera
git clone https://gitlab.com/johnmart19/vendor_xiaomi_camera.git -b aosp-17 vendor/xiaomi/camera
git clone https://github.com/Nafis905/packages_apps_GameBar.git -b 17  packages/apps/GameBar

echo "=== Setup Vendor Keys ==="
git clone https://github.com/Nafis905/keys.git vendor/hertzify-priv/keys
sed -i 's|vendor/lineage-priv/keys/testkey|vendor/hertzify-priv/keys/testkey|g' vendor/hertzify-priv/keys/keys.mk

echo "=== Setting up Build Environment ==="
. build/envsetup.sh
lunch hertzify_alioth-cp2a-user

echo "=== Cleaning Build Artifacts ==="
m installclean

echo "=== Starting Compilation ==="
mka bacon
