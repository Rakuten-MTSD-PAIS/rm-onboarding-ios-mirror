# RMOnboardingSDK

Swift Package Manager distribution for the Rakuten Mobile Onboarding SDK (OneClick Framework) with integrated RakutenAnalytics.

## Overview

This SPM package provides:
- **OneClick Framework** - Core onboarding SDK (distributed as xcframework binary)
- **RakutenAnalytics Integration** - Automatic analytics tracking
- **Protocol-based Architecture** - Flexible and testable design

## Installation

### Swift Package Manager

Add this package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://git.rakuten-it.com/scm/ema/rm-onboarding-ios.git", from: "2.600.0005")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL: `https://git.rakuten-it.com/scm/ema/rm-onboarding-ios.git`
3. Select version/branch
4. Add to your target

## Usage

### 1. Import the SDK

**Single import includes everything you need:**
- `RMOnboardingSDK` - Main SDK wrapper with automatic analytics
- `RatIntializers` - Analytics configuration
- `RMOnboardingError` - Error handling (alias for OneClickSdkError)

```swift
import RMOnboardingSDK
```

### 2. Use the SDK

**No initialization required!** RakutenAnalytics tracking is automatically enabled when you call `startICChipKYC`.

```swift
// Start the onboarding flow
let ratConfig = RatIntializers(
    customerId: "your-customer-id",
    contractedPlan: "your-plan",
    accountId: 1316,
    applicationId: 1,
    ssc: "my-rakuten-mobile"
)

try await RMOnboardingSDK.startICChipKYC(
    parentController: self,
    minor: false,
    idid: "your-idid",
    redirectUri: "your-redirect-uri",
    ratIntializers: ratConfig,
    supportedKycTypes: "IC",
    baseURL: "https://your-api-url.com"
) { success, message in
    print("KYC completed: \(success)")
}
```

### Complete Example

```swift
import UIKit
import RMOnboardingSDK

class OnboardingViewController: UIViewController {

    func startOnboarding() async {
        let ratConfig = RatIntializers(
            customerId: "customer-123",
            contractedPlan: "premium",
            accountId: 1316,
            applicationId: 1,
            ssc: "my-rakuten-mobile"
        )

        do {
            try await RMOnboardingSDK.startICChipKYC(
                parentController: self,
                minor: false,
                idid: "your-idid",
                redirectUri: "your-redirect-uri",
                ratIntializers: ratConfig,
                supportedKycTypes: "IC",
                baseURL: "https://your-api-url.com"
            ) { success, message in
                if success {
                    print("✅ KYC completed successfully")
                } else {
                    print("❌ KYC failed: \(message ?? "Unknown error")")
                }
            }
        } catch let error as RMOnboardingError {
            print("RMOnboarding Error: \(error.localizedDescription)")
        } catch {
            print("Unexpected error: \(error)")
        }
    }
}
```

## Architecture

```
┌─────────────────────────────────────┐
│     Your App (Consumer)             │
│                                     │
│  import RMOnboardingSDK             │
│                                     │
│  RMOnboardingSDK.startICChipKYC()   │
│  ↓ Automatic initialization         │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│   RMOnboardingSDK Package           │
│                                     │
│  ┌────────────────────────────┐    │
│  │  RMOnboardingSDKWrapper    │    │
│  │  (Source Target)           │    │
│  │  - Auto-initialization     │    │
│  │  - RatSdk Adapter          │    │
│  │  - Wrapper methods         │    │
│  │  - RakutenAnalytics link   │◄──┼─── SPM Dependency
│  └──────────────┬─────────────┘    │
│                 │                   │
│                 ▼                   │
│  ┌────────────────────────────┐    │
│  │  OneClick.xcframework      │    │
│  │  (Binary Target)           │    │
│  │  - Core SDK                │    │
│  │  - Protocol-based          │    │
│  │  - No dependencies         │    │
│  └────────────────────────────┘    │
└─────────────────────────────────────┘
```

## Requirements

- iOS 14.0+
- Xcode 13.0+
- Swift 5.9+

## Dependencies

- [RakutenAnalytics](https://github.com/rakutenanalytics/ios-rakutenanalytics) (>= 10.6.0)

## Features

- ✅ **Zero-configuration setup** - Automatic RakutenAnalytics initialization
- ✅ **Single method call** - No manual adapter injection required
- ✅ **Automatic analytics tracking** - Page views and clicks tracked throughout the flow
- ✅ **Protocol-based architecture** - Testable and flexible design
- ✅ **Clean binary distribution** - Zero xcframework dependencies
- ✅ **Multi-architecture support** - Device and simulator compatible
- ✅ **Seamless integration** - Drop-in replacement for existing implementations

## Releases

### Publishing a New Release

1. **Update the xcframework**
   - Build the OneClick.xcframework from ICChipSDK
   - Zip it: `zip -r OneClick.xcframework.zip OneClick.xcframework`
   - Replace the `OneClick.xcframework.zip` in this repository

2. **Commit and Tag**
   ```bash
   git add OneClick.xcframework.zip
   git commit -m "Update xcframework for v2.600.0005"
   git tag v2.600.0005
   git push origin main --tags
   ```

3. **Consumers will automatically get the update** when they update their package dependencies

## Support

For issues or questions, please contact the Rakuten Mobile team.

## License

[Add your license information here]
