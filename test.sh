echo "=== Initializing Repo ==="

rm -rf .repo/local_manifests

repo init -u https://github.com/Project-Mist-OS/manifest.git -b 17.0 --git-lfs --depth=1
git clone https://github.com/Nafiss-Android-Stuff/local_manifest.git -b main --depth=1 .repo/local_manifests

echo "=== Syncing Tree ==="
repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)

echo "=== Setup Keys ==="
git clone https://github.com/Nafis905/keys.git vendor/mist-priv/keys
sed -i 's|vendor/lineage-priv/keys/testkey|vendor/mist-priv/keys/testkey|g' vendor/mist-priv/keys/keys.mk

echo "=== Camera Cherry-pick ==="

cd device/xiaomi/camera

git fetch https://github.com/Sanjis-Android-Playground/device_xiaomi_camera.git 75f90801f72392e867fb0e0002112d34627e4647

git cherry-pick 75f90801f72392e867fb0e0002112d34627e4647 || {
    git cherry-pick --abort 2>/dev/null || true
    echo "Cherry-pick failed, skipping..."
}

cd ../../../

cd kernel/xiaomi/sm8250
git submodule init
git submodule update

cd ../../../


echo "=== Starting Compilation ==="
. build/envsetup.sh
mistify alioth userdebug
mist b
