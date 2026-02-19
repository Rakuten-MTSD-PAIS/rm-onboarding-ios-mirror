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
- `JPKIEnvironment` - Environment configuration for JPKI

```swift
import RMOnboardingSDK
import RakutenOneAuthCore  // For SessionProvider
```

### 2. Configure JPKI (Required for IC Chip KYC)

**JPKI configuration must be done before starting the IC Chip KYC flow.** You need to provide:
- `SessionProvider` from RakutenOneAuth (after user authentication)
- `clientID` - Your application's client ID
- `environment` - Environment configuration (staging, production, or custom)

#### Environment Options

**Staging (Default):**
```swift
RMOnboardingSDK.configureJPKI(
    sessionProvider: sessionProvider,
    clientID: "rmn_app_ios",
    environment: .staging
)
```

**Production:**
```swift
RMOnboardingSDK.configureJPKI(
    sessionProvider: sessionProvider,
    clientID: "rmn_app_ios",
    environment: .production
)
```

**Custom URLs:**
```swift
RMOnboardingSDK.configureJPKI(
    sessionProvider: sessionProvider,
    clientID: "rmn_app_ios",
    environment: .custom(
        jpkiUrl: "https://your-custom-jpki.example.com",
        languageUrl: "https://your-custom.example.com/language.json"
    )
)
```

### 3. Start IC Chip KYC

#### Option A: Method Chaining (Recommended)

Configure JPKI and start KYC in a single chain:

```swift
let ratConfig = RatIntializers(
    customerId: "your-customer-id",
    contractedPlan: "your-plan",
    accountId: 1316,
    applicationId: 1,
    ssc: "my-rakuten-mobile"
)

try await RMOnboardingSDK
    .configureJPKI(
        sessionProvider: sessionProvider,
        clientID: "rmn_app_ios",
        environment: .staging
    )
    .startICChipKYC(
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

#### Option B: Configure Once, Use Multiple Times

Configure JPKI once (e.g., after login), then use SDK normally:

```swift
// After user authentication
if let sessionProvider = OneClickAuthManager.shared.getSessionProvider() {
    RMOnboardingSDK.configureJPKI(
        sessionProvider: sessionProvider,
        clientID: "rmn_app_ios",
        environment: .staging
    )
}

// Later, start KYC flow
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
import RakutenOneAuthCore

class OnboardingViewController: UIViewController {

    // Assume you have a SessionProvider from RakutenOneAuth after user authentication
    var sessionProvider: SessionProvider?

    func startOnboarding() async {
        guard let sessionProvider = sessionProvider else {
            print("❌ SessionProvider not available. User needs to authenticate first.")
            return
        }

        let ratConfig = RatIntializers(
            customerId: "customer-123",
            contractedPlan: "premium",
            accountId: 1316,
            applicationId: 1,
            ssc: "my-rakuten-mobile"
        )

        do {
            // Method chaining approach: configure JPKI and start KYC in one call
            try await RMOnboardingSDK
                .configureJPKI(
                    sessionProvider: sessionProvider,
                    clientID: "rmn_app_ios",
                    environment: .staging  // or .production or .custom(...)
                )
                .startICChipKYC(
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

### Deep Link Support

You can also start the KYC flow from a URL:

```swift
func handleDeepLink(url: URL) async {
    guard let sessionProvider = sessionProvider else {
        print("❌ SessionProvider not available")
        return
    }

    let ratConfig = RatIntializers(
        customerId: "customer-123",
        contractedPlan: "premium",
        accountId: 1316,
        applicationId: 1,
        ssc: "my-rakuten-mobile"
    )

    do {
        try await RMOnboardingSDK
            .configureJPKI(
                sessionProvider: sessionProvider,
                clientID: "rmn_app_ios",
                environment: .staging
            )
            .startICChipKYC(
                parentController: self,
                url: url,  // URL format: https://example.com/ekyc/ic?idid=...&minor=false
                ratIntializers: ratConfig,
                baseURL: "https://your-api-url.com"
            ) { success, message in
                print("KYC completed: \(success)")
            }
    } catch {
        print("Error: \(error)")
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
- ✅ **JPKI Integration** - Built-in support for RakutenOneAuth eKYC with JPKI
- ✅ **Method Chaining** - Fluent API for configuring and starting KYC flows
- ✅ **Environment Configuration** - Easy switching between staging, production, and custom environments
- ✅ **Automatic analytics tracking** - Page views and clicks tracked throughout the flow
- ✅ **Protocol-based architecture** - Testable and flexible design
- ✅ **Clean binary distribution** - Zero xcframework dependencies
- ✅ **Multi-architecture support** - Device and simulator compatible
- ✅ **Deep Link Support** - Start KYC flows from universal links or custom URLs
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
