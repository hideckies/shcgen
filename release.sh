#!/usr/bin/env bash

version="$1"
dist_dir="dist"

# ----------------------------------------------
# Check the version specified
# ----------------------------------------------

if [ -z "$version" ]; then
    echo "[x] Specify the shcgen version."
    exit 1
fi

echo "[i] Releasing Shcgen v$version..."

# ----------------------------------------------
# Tagging
# ----------------------------------------------

echo "[i] Tagging..."
git tag v$version
if [ $? -ne 0 ]; then
    echo "[x] Failed to create git tag."
    exit 1
fi

# ----------------------------------------------
# Test before building
# ----------------------------------------------

echo "[i] Testing shcgen..."
zig build test
if [ $? -ne 0 ]; then
    echo "[x] Failed to test shcgen."
    exit 1
fi
echo "[+] OK"

# ----------------------------------------------
# Remove previous build and packages
# ----------------------------------------------

rm -rf ./zig-out
rm -rf ./$dist_dir/*

# ----------------------------------------------
# Build for each target
# ----------------------------------------------

echo "[i] Building..."
zig build \
    -Dtarget=x86_64-linux \
    -Dcpu=x86_64_v3 \
    -Doptimize=ReleaseSmall \
    -Dexe_name="shcgen" \
    -Dversion="$version"
pkg_linux_x64="shcgen-linux-x64-v$version"
mkdir -p $dist_dir/$pkg_linux_x64
cp zig-out/bin/shcgen $dist_dir/$pkg_linux_x64/
zip -r $dist_dir/$pkg_linux_x64.zip $dist_dir/$pkg_linux_x64

if [ $? -ne 0 ]; then
    echo "[x] Failed to package $pkg_linux_x64."
    exit 1
fi

zig build \
    -Dtarget=x86_64-windows \
    -Dcpu=x86_64_v3 \
    -Doptimize=ReleaseSmall \
    -Dexe_name="shcgen" \
    -Dversion="$version"
pkg_windows_x64="shcgen-windows-x64-v$version"
echo "[+] OK"
mkdir -p $dist_dir/$pkg_windows_x64
cp zig-out/bin/shcgen.exe $dist_dir/$pkg_windows_x64/
zip -r $dist_dir/$pkg_windows_x64.zip $dist_dir/$pkg_windows_x64

if [ $? -ne 0 ]; then
    echo "[x] Failed to package $pkg_linux_x64."
    exit 1
fi

# ----------------------------------------------
# Push to remote repository
# ----------------------------------------------

echo "[i] Push to remote repository..."
git add . && git commit -m "Release v$version" && git push origin tag v$version
if [ $? -ne 0 ]; then
    echo "[x] Failed to push to remote repository."
    exit 1
fi
echo "[+] OK"

echo "Done."

# ----------------------------------------------
# Additional message
# ----------------------------------------------

echo ""
echo "[!] Don't forget upload the release builds under the \"$dist_dir\" to the GitHub release page."