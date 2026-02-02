# Release Guide for RMOnboardingSDK

This guide explains how to publish a new version of the RMOnboardingSDK SPM package.

## Prerequisites

- Access to the Rakuten git repository: https://git.rakuten-it.com/scm/ema/rm-onboarding-ios.git
- Latest OneClick.xcframework from the ICChipSDK project
- Git installed and configured

## Step-by-Step Release Process

### 1. Build the xcframework

From the ICChipSDK project:

```bash
cd /Users/ts-sairakesh.kota/Documents/ICChipSDK/OneClick

# Clean previous builds
rm -rf build/

# Build for iOS Device
xcodebuild archive \
  -scheme OneClick \
  -destination "generic/platform=iOS" \
  -archivePath "./build/ios.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build for iOS Simulator
xcodebuild archive \
  -scheme OneClick \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "./build/ios-simulator.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Create xcframework
xcodebuild -create-xcframework \
  -archive ./build/ios.xcarchive -framework OneClick.framework \
  -archive ./build/ios-simulator.xcarchive -framework OneClick.framework \
  -output ./build/OneClick.xcframework
```

### 2. Zip the xcframework

```bash
cd build
zip -r OneClick.xcframework.zip OneClick.xcframework

# Verify the zip
unzip -l OneClick.xcframework.zip
```

### 3. Replace the xcframework in SPM Repository

```bash
# Copy to RMOnboardingSDK repo
cp OneClick.xcframework.zip /Users/ts-sairakesh.kota/Documents/RMOnboardingSDK/

# Verify size (should be ~20MB)
ls -lh /Users/ts-sairakesh.kota/Documents/RMOnboardingSDK/OneClick.xcframework.zip
```

### 4. Commit and Tag the Release

```bash
cd /Users/ts-sairakesh.kota/Documents/RMOnboardingSDK

# Add the updated xcframework
git add OneClick.xcframework.zip

# Commit with version number
git commit -m "Release v2.600.0005: Update OneClick.xcframework"

# Create annotated tag
git tag -a v2.600.0005 -m "Release version 2.600.0005"

# Push to Rakuten repository
git push origin main
git push origin v2.600.0005
```

### 5. Verify the Release

Test in a consumer project:

```swift
// In Package.swift of test project
dependencies: [
    .package(url: "https://git.rakuten-it.com/scm/ema/rm-onboarding-ios.git", from: "2.600.0005")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://git.rakuten-it.com/scm/ema/rm-onboarding-ios.git`
3. Select version `2.600.0005`

---

## Versioning Guidelines

We follow semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR** (2): Breaking changes to public API
- **MINOR** (600): New features, backward compatible
- **PATCH** (0005): Bug fixes, backward compatible

Example versions:
- `2.600.0005` - Current release
- `2.600.0006` - Bug fix
- `2.601.0000` - New feature
- `3.0.0` - Breaking change

---

## Quick Reference Commands

### Build xcframework
```bash
cd /Users/ts-sairakesh.kota/Documents/ICChipSDK/OneClick
./scripts/build-xcframework.sh  # If you have a script
# OR use the xcodebuild commands above
```

### Update and Release
```bash
# From ICChipSDK
cd /Users/ts-sairakesh.kota/Documents/ICChipSDK/OneClick/build
zip -r OneClick.xcframework.zip OneClick.xcframework

# To RMOnboardingSDK
cp OneClick.xcframework.zip /Users/ts-sairakesh.kota/Documents/RMOnboardingSDK/

# Commit and tag
cd /Users/ts-sairakesh.kota/Documents/RMOnboardingSDK
git add OneClick.xcframework.zip
git commit -m "Release v2.600.0006"
git tag v2.600.0006
git push origin main --tags
```

---

## Troubleshooting

### Error: "Binary target not found"
**Cause:** OneClick.xcframework.zip not in repository
**Fix:** Ensure the zip file is committed and pushed

### Error: "Package resolution failed"
**Cause:** Git tag doesn't exist or not pushed
**Fix:** Verify tags with `git tag -l` and push with `git push origin --tags`

### Error: "Cannot resolve package dependencies"
**Cause:** Network issues or repository access
**Fix:** Verify access to https://git.rakuten-it.com/scm/ema/rm-onboarding-ios.git

### xcframework build fails
**Cause:** Xcode version mismatch or scheme issues
**Fix:**
- Clean build folder (⇧⌘K in Xcode)
- Verify scheme "OneClick" exists
- Check deployment target (iOS 14.0+)

---

## Checklist

Before releasing, ensure:

- [ ] OneClick.xcframework builds successfully without errors
- [ ] No RakutenAnalytics symbols in the xcframework
- [ ] xcframework.zip created and verified
- [ ] Zip file copied to RMOnboardingSDK repository
- [ ] Changes committed with proper version message
- [ ] Git tag created with version number
- [ ] Tag pushed to Rakuten repository
- [ ] Tested in a consumer project
- [ ] Documentation updated if needed

---

## File Locations

- **ICChipSDK Project**: `/Users/ts-sairakesh.kota/Documents/ICChipSDK`
- **Built xcframework**: `/Users/ts-sairakesh.kota/Documents/ICChipSDK/OneClick/build/OneClick.xcframework.zip`
- **SPM Package**: `/Users/ts-sairakesh.kota/Documents/RMOnboardingSDK`
- **Repository**: `https://git.rakuten-it.com/scm/ema/rm-onboarding-ios.git`

---

## Notes

- The xcframework.zip is stored directly in the git repository (not as a GitHub release)
- Package.swift uses `path: "OneClick.xcframework.zip"` for the binary target
- No checksum needed when using path-based binary targets
- Consumers get the framework automatically when they clone/pull the repository
- Typical zip size is ~20MB

---

**Questions?** Contact the Rakuten Mobile SDK team.
