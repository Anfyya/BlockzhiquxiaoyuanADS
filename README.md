# BlockzhiquxiaoyuanADS

`BlockzhiquxiaoyuanADS` is a minimal Objective-C runtime plugin that blocks several ad entry points used by the target app and builds directly into an iOS `dylib`.

## Files

- `FuckAds.m`: the hook source.
- `build.sh`: local/macOS build script.
- `.github/workflows/build.yml`: GitHub Actions workflow that builds and uploads the `dylib` artifact.

## GitHub Actions build

After pushing this repository to GitHub, open the `Actions` tab and run or wait for the `Build BlockzhiquxiaoyuanADS.dylib` workflow. The compiled file is uploaded as the `BlockzhiquxiaoyuanADS.dylib` artifact.

## Build target

- SDK: `iphoneos`
- Architectures: `arm64`, `arm64e`
- Minimum iOS version: `13.0`
- Output: `BlockzhiquxiaoyuanADS.dylib`

## Notes

- The project does not depend on Theos.
- The workflow uses the Xcode toolchain that already exists on GitHub's macOS runner.
- Injection, packaging, and app-specific deployment are intentionally left outside this repository.
