# LineageOS-a26

Device and vendor trees for **Samsung Galaxy A26 5G** (`SM-A266B`, codename `a26x`) on LineageOS 23.2 (Android 16).

## Quick Build on Crave CI

**LineageOS:**
```bash
crave run --no-patch -- "curl -s -L https://raw.githubusercontent.com/os-guy-original/LineageOS-a26/refs/heads/lineage-23.2/build_rom.sh -o build_rom.sh && bash build_rom.sh"
```

**AxionOS:**
```bash
crave run --no-patch -- "curl -s -L https://raw.githubusercontent.com/os-guy-original/LineageOS-a26/refs/heads/lineage-23.2/build_axion.sh -o build_axion.sh && bash build_axion.sh"
```

## Repositories

| Repository | Purpose |
|------------|---------|
| [android_device_samsung_a26x](https://github.com/os-guy-original/android_device_samsung_a26x) | Device tree, sepolicy, configs |
| [android_vendor_samsung_a26x](https://github.com/os-guy-original/android_vendor_samsung_a26x) | Proprietary blobs |
| [android_kernel_samsung_a26x](https://github.com/os-guy-original/android_kernel_samsung_a26x) | Prebuilt kernel |

## Maintainer

[OpenSource Guy](https://github.com/os-guy-original)
