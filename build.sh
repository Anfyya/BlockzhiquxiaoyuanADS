#!/usr/bin/env bash
set -euo pipefail

OUTPUT="BlockzhiquxiaoyuanADS.dylib"
SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"

echo "Using SDK: ${SDK_PATH}"

xcrun -sdk iphoneos clang \
  -arch arm64 \
  -arch arm64e \
  -dynamiclib \
  -isysroot "${SDK_PATH}" \
  -miphoneos-version-min=13.0 \
  -fobjc-arc \
  -fblocks \
  -O2 \
  -framework Foundation \
  -framework UIKit \
  -Wl,-install_name,@rpath/${OUTPUT} \
  -o "${OUTPUT}" \
  FuckAds.m

codesign -f -s - "${OUTPUT}"

echo "Build output:"
file "${OUTPUT}"
ls -lh "${OUTPUT}"
