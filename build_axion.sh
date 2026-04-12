#!/bin/bash
# ==========================================================
# Automated Build Script for AxionOS Custom ROM
# Target: Samsung Galaxy A26 5G (a26x)
# Maintainer: OpenSource Guy
#
# Based on LineageOS 23.2 with AxionOS performance enhancements
# ==========================================================

set -e

# Define Color Codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# AxionOS-specific variables
DEVICE="a26x"
VARIANT="va"  # Default to vanilla
THREADS=$(nproc --all)

echo -e "${BLUE}==========================================================${NC}"
echo -e "${GREEN} Starting AxionOS Build for a26x${NC}"
echo -e "${GREEN} Based on LineageOS 23.2 (Android 16)${NC}"
echo -e "${GREEN} Maintainer: OpenSource Guy${NC}"
echo -e "${BLUE}==========================================================${NC}"

# Parse variant argument if provided
if [ -n "$1" ]; then
    VARIANT="$1"
fi

echo -e "${BLUE}[1/4] Initializing and Syncing Repositories...${NC}"

# Remove old local manifests to avoid conflicts
rm -rf .repo/local_manifests

# Initialize AxionOS repository
echo -e "${BLUE}[INFO] Initializing AxionOS repository...${NC}"
repo init -u https://github.com/AxionAOSP/android.git -b lineage-23.2 --git-lfs

# Clone fresh local manifests for device trees
echo -e "${BLUE}[INFO] Cloning a26x local manifests...${NC}"
git clone https://github.com/os-guy-original/LineageOS-a26 --depth 1 -b lineage-23.2 .repo/local_manifests

# Force full repo sync
echo -e "${BLUE}[INFO] Syncing all repositories (this may take a while)...${NC}"
repo sync -c -j${THREADS} --force-sync --no-clone-bundle --no-tags

echo -e "${BLUE}[2/4] Setting up build environment...${NC}"
if [ ! -f "build/envsetup.sh" ]; then
    echo -e "${RED}[ERROR] build/envsetup.sh not found. Ensure you are running this from the root of your AxionOS tree.${NC}"
    exit 1
fi

# Source build environment
source build/envsetup.sh || { echo -e "${RED}[ERROR] Failed to source build/envsetup.sh${NC}"; exit 1; }

# Verify vendor/lineage exists (AxionOS is based on LineageOS)
if [ ! -d "vendor/lineage" ]; then
    echo -e "${RED}[ERROR] vendor/lineage not found! LineageOS core is missing.${NC}"
    echo -e "${BLUE}[INFO] This usually means repo sync didn't complete properly.${NC}"
    exit 1
fi

# Generate signing keys if they don't exist
if [ ! -f "~/.android-certs/releasekey.pk8" ]; then
    echo -e "${BLUE}[INFO] Generating signing keys...${NC}"
    gk -s || { echo -e "${YELLOW}[WARN] gk -s failed. You may need to generate keys manually.${NC}"; }
fi

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

# Use AxionOS-specific axion command for device setup
echo -e "${BLUE}[INFO] Running axion ${DEVICE} ${VARIANT}...${NC}"
axion ${DEVICE} ${VARIANT} || { 
    echo -e "${YELLOW}[WARN] axion command failed. Falling back to breakfast...${NC}"
    breakfast ${DEVICE} userdebug || { echo -e "${RED}[ERROR] breakfast failed.${NC}"; exit 1; }
}

# Add AxionOS-specific properties to device configuration
echo -e "${BLUE}[INFO] Configuring AxionOS device properties...${NC}"

# Check if we need to add AxionOS properties to the device makefile
DEVICE_MAKEFILE="device/samsung/a26x/lineage_a26x.mk"
if [ -f "$DEVICE_MAKEFILE" ]; then
    # Add AxionOS inheritance if not already present
    if ! grep -q "vendor/axion/config" "$DEVICE_MAKEFILE" 2>/dev/null && \
       ! grep -q "vendor/lineage/config" "$DEVICE_MAKEFILE" 2>/dev/null; then
        echo "Adding AxionOS product inheritance..."
        cat >> "$DEVICE_MAKEFILE" << 'EOF'

# AxionOS configuration
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# AxionOS device properties (optional - customize as needed)
# AXION_CAMERA_REAR_INFO := 50,48
# AXION_CAMERA_FRONT_INFO := 42
# AXION_MAINTAINER := OpenSource_Guy
# AXION_PROCESSOR := Exynos_S5E8835

# AxionOS firmware configurations
# BYPASS_CHARGE_SUPPORTED ?= false
# PERF_GOV_SUPPORTED := false
# HBM_SUPPORTED := false
# TARGET_NEEDS_DOZE_FIX := false
# TARGET_IS_LOW_RAM ?= false
# TARGET_SUPPORTED_REFRESH_RATES := 60,90,120

# Prebuilt LineageOS apps
# TARGET_INCLUDES_LOS_PREBUILTS := true
EOF
    fi
fi

echo -e "${BLUE}[4/4] Starting compilation...${NC}"

# Prevent historical broken vendor symlinks from crashing the build
if [ -d "out/target/product/${DEVICE}/system/vendor" ] && [ ! -L "out/target/product/${DEVICE}/system/vendor" ]; then
    echo -e "${BLUE}[INFO] Removing stale system/vendor directory to prevent symlink errors...${NC}"
    rm -rf out/target/product/${DEVICE}/system/vendor
fi

# Clean previous build artifacts
make installclean 2>/dev/null || true

# Build using AxionOS ax command
echo -e "${BLUE}[INFO] Building AxionOS for ${DEVICE} with ${THREADS} threads...${NC}"
ax -br -j${THREADS} || { 
    echo -e "${YELLOW}[WARN] ax command failed. Falling back to mka bacon...${NC}"
    mka bacon -j${THREADS} || { echo -e "${RED}[ERROR] Build failed!${NC}"; exit 1; }
}

echo -e "${BLUE}==========================================================${NC}"
echo -e "${GREEN} AxionOS Build for ${DEVICE} (${VARIANT}) Completed Successfully!${NC}"
echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}Output: out/target/product/${DEVICE}/AxionOS-*.zip${NC}"
