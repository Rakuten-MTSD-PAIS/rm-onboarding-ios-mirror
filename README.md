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

```swift
import RMOnboardingSDK
import RMOnboardingSDKWrapper
```

### 2. Initialize Analytics Adapter

**Important:** You must inject the RakutenAnalytics adapter before using the SDK.

```swift
// In your AppDelegate or app initialization
let analyticsAdapter = RatSdkRakutenAnalyticsAdapter()
RatSdk.setSharedInstance(analyticsAdapter)
```

### 3. Use the SDK

```swift
// Start the onboarding flow
let ratConfig = RatIntializers(
    customerId: "your-customer-id",
    contractedPlan: "your-plan",
    accountId: 1316,
    applicationId: 1,
    ssc: "my-rakuten-mobile"
)

let viewController = OneClickSdk.startICChipKYC(
    ratConfig: ratConfig,
    sessionProvider: yourSessionProvider,
    delegate: yourDelegate
)

present(viewController, animated: true)
```

### Complete Example

```swift
import UIKit
import RMOnboardingSDK
import RMOnboardingSDKWrapper

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // 1. Initialize RakutenAnalytics adapter
        let analyticsAdapter = RatSdkRakutenAnalyticsAdapter()
        RatSdk.setSharedInstance(analyticsAdapter)

        // 2. SDK is now ready to use
        return true
    }
}

class OnboardingViewController: UIViewController {

    func startOnboarding() {
        let ratConfig = RatIntializers(
            customerId: "customer-123",
            contractedPlan: "premium",
            accountId: 1316,
            applicationId: 1,
            ssc: "my-rakuten-mobile"
        )

        let vc = OneClickSdk.startICChipKYC(
            ratConfig: ratConfig,
            sessionProvider: mySessionProvider,
            delegate: self
        )

        present(vc, animated: true)
    }
}
```

## Architecture

```
┌─────────────────────────────────────┐
│     Your App (Consumer)             │
│                                     │
│  import RMOnboardingSDK             │
│  import RMOnboardingSDKWrapper      │
│                                     │
│  RatSdk.setSharedInstance(adapter)  │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│   RMOnboardingSDK Package           │
│                                     │
│  ┌────────────────────────────┐    │
│  │  OneClick.xcframework      │    │
│  │  (Binary Target)           │    │
│  │  - Core SDK                │    │
│  │  - Protocol-based          │    │
│  │  - No dependencies         │    │
│  └────────────────────────────┘    │
│                                     │
│  ┌────────────────────────────┐    │
│  │  RMOnboardingSDKWrapper    │    │
│  │  (Source Target)           │    │
│  │  - RatSdk Adapter          │    │
│  │  - RakutenAnalytics link   │◄──┼─── SPM Dependency
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

- ✅ Zero xcframework dependencies - Clean, portable binary
- ✅ Automatic analytics tracking throughout the onboarding flow
- ✅ Protocol-based design for testability
- ✅ Support for both device and simulator architectures
- ✅ Seamless integration with existing apps

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
