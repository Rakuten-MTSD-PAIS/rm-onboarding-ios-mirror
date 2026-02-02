//
//  RMOnboardingSDK.swift
//  RMOnboardingSDK
//
//  Created by Claude Code
//

import Foundation
import UIKit
import OneClick

/// Main entry point for RMOnboardingSDK
/// Provides simplified initialization and wrapper methods for consuming apps
public enum RMOnboardingSDK {

    private static var isInitialized = false

    /// Internal initialization - automatically called when using RMOnboardingSDK methods
    private static func initializeIfNeeded() {
        guard !isInitialized else {
            return
        }

        // Create and inject the RakutenAnalytics adapter
        let adapter = RatSdkRakutenAnalyticsAdapter()
        RatSdk.setSharedInstance(adapter)

        isInitialized = true
        debugPrint("[RMOnboardingSDK] Successfully initialized with RakutenAnalytics adapter")
    }

    /// Start the IC Chip KYC flow with automatic RakutenAnalytics initialization
    ///
    /// - Parameters:
    ///   - parentController: The parent view controller to present the KYC flow
    ///   - minor: Whether the user is a minor
    ///   - idid: The identification ID
    ///   - redirectUri: The redirect URI after completion
    ///   - ratIntializers: Optional RAT analytics initializers
    ///   - supportedKycTypes: Supported KYC types (e.g., "IC")
    ///   - baseURL: Base URL for the KYC API
    ///   - enableSecurityCheck: Whether to enable security checks (default: true)
    ///   - completionHandler: Completion handler with success status and optional message
    ///
    /// - Throws: OneClickSdkError if the flow cannot be started
    ///
    /// Example:
    /// ```swift
    /// import RMOnboardingSDK
    ///
    /// let ratConfig = RatIntializers(
    ///     customerId: nil,
    ///     contractedPlan: nil,
    ///     accountId: 1316,
    ///     applicationId: 1,
    ///     ssc: "my-rakuten-mobile"
    /// )
    ///
    /// try await RMOnboardingSDK.startICChipKYC(
    ///     parentController: self,
    ///     minor: false,
    ///     idid: "your-idid",
    ///     redirectUri: "your-redirect-uri",
    ///     ratIntializers: ratConfig,
    ///     supportedKycTypes: "IC",
    ///     baseURL: "https://your-api-url.com"
    /// ) { success, message in
    ///     print("KYC completed: \(success)")
    /// }
    /// ```
    public static func startICChipKYC(
        parentController: UIViewController,
        minor: Bool,
        idid: String,
        redirectUri: String,
        ratIntializers: RatIntializers? = nil,
        supportedKycTypes: String,
        baseURL: String,
        enableSecurityCheck: Bool = true,
        completionHandler: @escaping (Bool, String?) -> Void
    ) async throws {
        // Automatically initialize RakutenAnalytics adapter if not already done
        initializeIfNeeded()

        // Delegate to OneClick SDK
        try await OneClickSdk.startICChipKYC(
            parentController: parentController,
            minor: minor,
            idid: idid,
            redirectUri: redirectUri,
            ratIntializers: ratIntializers,
            supportedKycTypes: supportedKycTypes,
            baseURL: baseURL,
            enableSecurityCheck: enableSecurityCheck,
            completionHandler: completionHandler
        )
    }

    /// Check if the SDK has been initialized
    public static var initialized: Bool {
        return isInitialized
    }
}
