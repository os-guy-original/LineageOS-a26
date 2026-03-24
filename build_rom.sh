#!/bin/bash
# ==========================================================
# Automated Build Script for LineageOS 23.2 Custom ROM
# Target: Samsung Galaxy A26 5G (a26x)
# Maintainer: OpenSource Guy
#
# INSTRUCTIONS FOR CRAVE:
# Run the following command in a fresh workspace to automatically
# initialize, sync, and build the full ROM from scratch:
#   crave run --no-patch -- "curl -s -L https://raw.githubusercontent.com/os-guy-original/LineageOS-a26/refs/heads/lineage-23.2/build_rom.sh -o build_rom.sh && bash build_rom.sh"
# ==========================================================

set -e

# Define Color Codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}==========================================================${NC}"
echo -e "${GREEN} Starting LineageOS 23.2 Custom ROM Build for a26x${NC}"
echo -e "${GREEN} Maintainer: OpenSource Guy${NC}"
echo -e "${BLUE}==========================================================${NC}"

echo -e "${BLUE}[1/4] Initializing and Syncing Repositories...${NC}"
if [ ! -d ".repo" ]; then
    echo -e "${BLUE}[INFO] .repo not found, performing full initialization...${NC}"
    repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs
    
    # We clone the manifest here so repo sync will pull the device trees
    echo -e "${BLUE}[INFO] Cloning a26x local manifests...${NC}"
    mkdir -p .repo/local_manifests
    curl -o .repo/local_manifests/a26x.xml https://raw.githubusercontent.com/os-guy-original/LineageOS-a26/refs/heads/lineage-23.2/a26x.xml
fi

# Always use full repo sync to ensure vendor/lineage and all core repos are synced
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

echo -e "${BLUE}[2/4] Setting up build environment...${NC}"
if [ ! -f "build/envsetup.sh" ]; then
    echo -e "${RED}[ERROR] build/envsetup.sh not found. Ensure you are running this from the root of your LineageOS tree.${NC}"
    exit 1
fi

# Explicitly use bash to source
source build/envsetup.sh || { echo -e "${RED}[ERROR] Failed to source build/envsetup.sh${NC}"; exit 1; }

echo -e "${BLUE}[3/4] Initializing device configuration...${NC}"

# Check if device tree exists
if [ ! -d "device/samsung/a26x" ]; then
    echo -e "${RED}[ERROR] device/samsung/a26x not found! Manifest sync might have failed.${NC}"
    echo -e "${BLUE}[INFO] Current device/ directory contents:${NC}"
    ls -R device/ | grep ":$" || echo "device/ is empty"
    exit 1
fi

# Verify AndroidProducts.mk exists
if [ ! -f "device/samsung/a26x/AndroidProducts.mk" ]; then
    echo -e "${RED}[ERROR] device/samsung/a26x/AndroidProducts.mk not found!${NC}"
    exit 1
fi

# Check if Lineage-specific commands exist
if ! type breakfast >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] 'breakfast' command not found even after sourcing envsetup.sh.${NC}"
    echo -e "${BLUE}[INFO] Falling back to manual lunch...${NC}"
    lunch lineage_a26x-userdebug || { echo -e "${RED}[ERROR] lunch failed as well.${NC}"; exit 1; }
else
    echo -e "${BLUE}[INFO] 'breakfast' found, initializing a26x...${NC}"
    breakfast a26x
fi

echo -e "${BLUE}[4/4] Starting compilation...${NC}"
# Prevent historical broken vendor symlinks from crashing the build
if [ -d "out/target/product/a26x/system/vendor" ] && [ ! -L "out/target/product/a26x/system/vendor" ]; then
    echo -e "${BLUE}[INFO] Removing stale system/vendor directory to prevent symlink errors...${NC}"
    rm -rf out/target/product/a26x/system/vendor
fi

# By default, we build bacon (the flashable ROM zip)
# But users can pass arguments like 'target-files-package' or 'bootimage' to override
TARGET="${1:-bacon}"
mka installclean
mka "$TARGET"

echo -e "${BLUE}==========================================================${NC}"
echo -e "${GREEN} Build for $TARGET Completed Successfully!${NC}"
echo -e "${BLUE}==========================================================${NC}"
