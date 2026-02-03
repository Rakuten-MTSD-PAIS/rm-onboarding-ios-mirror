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
    /// - Throws: RMOnboardingError if the flow cannot be started
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

    /// Start the IC Chip KYC flow from a deep link or custom scheme URL
    ///
    /// This convenience method parses the URL to extract KYC parameters and automatically
    /// calls the main startICChipKYC method. Supports both universal links and custom URL schemes.
    ///
    /// - Parameters:
    ///   - parentController: The parent view controller to present the KYC flow
    ///   - url: Universal link (e.g., "https://example.com/ekyc/ic?idid=...&minor=true")
    ///          or custom scheme URL (e.g., "app://ekyc/ic?idid=...&minor=true")
    ///   - ratIntializers: Optional RAT analytics initializers
    ///   - baseURL: Base URL for the KYC API
    ///   - enableSecurityCheck: Whether to enable security checks (default: true)
    ///   - completionHandler: Completion handler with success status and optional message
    ///
    /// - Throws: RMOnboardingError if the URL is invalid, missing required parameters, or the flow cannot be started
    ///
    /// Example:
    /// ```swift
    /// import RMOnboardingSDK
    ///
    /// let deepLinkURL = URL(string: "https://example.com/ekyc/ic?idid=123&minor=false&redirect_uri=app://callback&suppurted_kyc_types=IC")!
    ///
    /// try await RMOnboardingSDK.startICChipKYC(
    ///     parentController: self,
    ///     url: deepLinkURL,
    ///     ratIntializers: ratConfig,
    ///     baseURL: "https://your-api-url.com"
    /// ) { success, message in
    ///     print("KYC completed: \(success)")
    /// }
    /// ```
    public static func startICChipKYC(
        parentController: UIViewController,
        url: URL,
        ratIntializers: RatIntializers? = nil,
        baseURL: String,
        enableSecurityCheck: Bool = true,
        completionHandler: @escaping (Bool, String?) -> Void
    ) async throws {
        // Validate URL path - supports both universal links and custom schemes
        let isValidPath: Bool
        let scheme = url.scheme?.lowercased() ?? ""
        let host = url.host ?? ""
        let path = url.path

        if scheme == "http" || scheme == "https" {
            // Universal link format: https://example.com/ekyc/ic
            isValidPath = path == "/ekyc/ic"
        } else if !host.isEmpty {
            // Custom scheme format: app://ekyc/ic
            let fullPath = "/\(host)\(path)"
            isValidPath = fullPath == "/ekyc/ic"
        } else {
            isValidPath = false
        }

        guard isValidPath else {
            throw OneClickSdkError.invalidURL("Invalid eKYC URL path. Expected '/ekyc/ic' but got '\(url.absoluteString)'")
        }

        // Parse query parameters
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // Extract parameters with empty string defaults (matching sample app behavior)
        let idid = queryItems?.first(where: { $0.name == "idid" })?.value ?? ""
        let redirectUri = queryItems?.first(where: { $0.name == "redirect_uri" })?.value ?? ""
        let supportedKycTypes = queryItems?.first(where: { $0.name == "suppurted_kyc_types" })?.value ?? ""

        // Parse minor parameter (defaults to false if not present or invalid)
        let minorString = queryItems?.first(where: { $0.name == "minor" })?.value
        let minor = minorString == "true"

        // Call the main startICChipKYC method with parsed parameters
        try await startICChipKYC(
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
