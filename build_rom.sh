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

# Use Crave's fast sync if available, otherwise fallback to repo sync
if [ -x "/opt/crave/resync.sh" ]; then
    /opt/crave/resync.sh
else
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
fi

echo -e "${BLUE}[2/4] Setting up build environment...${NC}"
if [ ! -f "build/envsetup.sh" ]; then
    echo -e "${RED}[ERROR] build/envsetup.sh not found. Ensure you are running this from the root of your LineageOS tree.${NC}"
    exit 1
fi
source build/envsetup.sh

echo -e "${BLUE}[3/4] Lunching target lineage_a26x-ap4a-userdebug...${NC}"
lunch lineage_a26x-ap4a-userdebug

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
