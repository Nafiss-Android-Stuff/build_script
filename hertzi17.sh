#!/bin/bash

echo "=== Cleaning up previous manifests and conflicting directories ==="
rm -rf .repo/local_manifests
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

# Remove matching private key directories separately
rm -rf vendor/*-priv/keys

echo "=== Initializing Repo ==="
repo init --depth=1 -u https://github.com/HertzifyOS/android_manifest.git -b 17 --git-lfs

echo "=== Syncing Source Tree ==="
if [ -f /usr/bin/resync ]; then
    /usr/bin/resync
else
    /opt/crave/resync.sh
    /opt/crave/resync.sh
fi

echo "=== Applying Optional Soong Patches ==="
SOONG_DIR="build/soong"
SOONG_REMOTE="https://github.com/DarkKiller28/android_build_soong_crdroid.git"

SOONG_COMMITS=(
    4983b36b6c1528e41d75f07689dc909d5e1d16e3
)

if [ -d "$SOONG_DIR/.git" ]; then
    pushd "$SOONG_DIR" >/dev/null

    for commit in "${SOONG_COMMITS[@]}"; do
        if git merge-base --is-ancestor "$commit" HEAD 2>/dev/null; then
            echo "Already applied: $commit"
            continue
        fi

        if ! git fetch "$SOONG_REMOTE" "$commit"; then
            echo "Unable to fetch $commit. Skipping."
            continue
        fi

        if git cherry-pick "$commit"; then
            echo "Successfully applied: $commit"
        else
            echo "Cherry-pick failed or conflicted: $commit"
            echo "Aborting cherry-pick and skipping."
            git cherry-pick --abort || true
        fi
    done

    popd >/dev/null
else
    echo "Soong Git repository not found. Skipping optional patches."
fi

echo "=== Cloning Device  Trees ==="
git clone https://github.com/Nafiss-Android-Stuff/android_device_xiaomi_sm8250-common.git -b Hertzify-17 device/xiaomi/sm8250-common
git clone https://github.com/Nafiss-Android-Stuff/android_device_xiaomi_alioth.git -b Hertzify-17 device/xiaomi/alioth
git clone https://github.com/Nafiss-Android-Stuff/android_vendor_xiaomi_alioth.git -b lineage-23.2 vendor/xiaomi/alioth
git clone https://github.com/Nafiss-Android-Stuff/android_vendor_xiaomi_sm8250-common.git -b 17 vendor/xiaomi/sm8250-common
git clone https://github.com/Nafis905/hardware_xiaomi.git -b lineage-23.2 hardware/xiaomi
git clone --depth=1 https://github.com/TIMISONG-dev/kernel_xiaomi_sm8250.git -b magictime-new kernel/xiaomi/sm8250

echo "=== Cloning Extra Trees ==="
git clone https://github.com/Tsaritsa-Prjkt/android_hardware_dolby.git -b lineage-24.0 hardware/dolby
git clone https://github.com/PocoF3Releases/device_xiaomi_camera.git -b aosp-17 device/xiaomi/camera
git clone https://gitlab.com/johnmart19/vendor_xiaomi_camera.git -b aosp-17 vendor/xiaomi/camera
git clone https://github.com/Nafis905/packages_apps_GameBar.git -b 17  packages/apps/GameBar

echo "=== Setup Vendor Keys ==="
git clone https://github.com/Nafis905/keys.git vendor/hertzify-priv/keys
sed -i 's|vendor/lineage-priv/keys/testkey|vendor/hertzify-priv/keys/testkey|g' vendor/hertzify-priv/keys/keys.mk

echo "=== Applying Kernel Patch ==="
cd kernel/xiaomi/sm8250
git submodule init
git submodule update

KERNEL_FILE="arch/arm64/kernel/process.c"

if grep -qF 's64 teo_wfi_timeout_ns(void);' "$KERNEL_FILE"; then
    if sed -i 's/s64 teo_wfi_timeout_ns(void);/#ifdef CONFIG_CPU_IDLE_GOV_TEO\ns64 teo_wfi_timeout_ns(void);\n#else\nstatic inline s64 teo_wfi_timeout_ns(void) { return 0; }\n#endif/' "$KERNEL_FILE"; then
        echo "Kernel patch applied successfully."
    else
        echo "Kernel patch failed. Skipping."
    fi
else
    echo "TEO declaration not found. Skipping kernel patch."
fi
cd ../../../

echo "=== Setting up Build Environment ==="
. build/envsetup.sh
lunch hertzify_alioth-cp2a-user

echo "=== Cleaning Build Artifacts ==="
m installclean

echo "=== Starting Compilation ==="
mka bacon
