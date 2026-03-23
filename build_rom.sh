#!/bin/bash
# ==========================================================
# Automated Build Script for LineageOS 22.1 Custom ROM
# Target: Samsung Galaxy A26 5G (a26x)
# Maintainer: OpenSource Guy
# ==========================================================

set -e

# Define Color Codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}==========================================================${NC}"
echo -e "${GREEN} Starting LineageOS 22.1 Custom ROM Build for a26x${NC}"
echo -e "${GREEN} Maintainer: OpenSource Guy${NC}"
echo -e "${BLUE}==========================================================${NC}"

echo -e "${BLUE}[1/3] Setting up build environment...${NC}"
if [ ! -f "build/envsetup.sh" ]; then
    echo -e "${RED}[ERROR] build/envsetup.sh not found. Ensure you are running this from the root of your LineageOS tree.${NC}"
    exit 1
fi
source build/envsetup.sh

echo -e "${BLUE}[2/3] Lunching target lineage_a26x-userdebug...${NC}"
lunch lineage_a26x-userdebug

echo -e "${BLUE}[3/3] Starting compilation...${NC}"
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
