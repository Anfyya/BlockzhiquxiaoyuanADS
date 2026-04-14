# BlockzhiquxiaoyuanADS

`BlockzhiquxiaoyuanADS` is a minimal Objective-C runtime plugin that blocks several ad entry points used by the target app and builds directly into an iOS `dylib`.

In addition to killing the splash / interstitial ad entry points, the dylib also disables the gyroscope / accelerometer / device-motion pipeline at runtime so that "shake to jump" ad pages can never read motion data and therefore cannot launch third-party apps or the App Store. The block covers:

- `CMMotionManager` — all `start*Updates` variants become no-ops, every `is*Available` / `is*Active` property returns `NO`, and the `gyroData` / `deviceMotion` / `accelerometerData` / `magnetometerData` readers return `nil`.
- `UIAccelerometer` — the deprecated delegate path used by older ad SDKs is also neutralised.
- `UIResponder` — the `motionBegan:/motionEnded:/motionCancelled:` shake events are swallowed as a safety net.

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
