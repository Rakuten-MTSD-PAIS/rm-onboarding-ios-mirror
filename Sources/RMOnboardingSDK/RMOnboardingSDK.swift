//
//  RMOnboardingSDK.swift
//  RMOnboardingSDK
//
//  Created by Claude Code
//

import Foundation
import UIKit
import OneClick
import RakutenOneAuthCore

/// JPKI Configuration builder for method chaining
@MainActor
public class JPKIConfiguration {
    private weak var jpkiAdapter: JPKIIDSDKAdapter?

    internal init(jpkiAdapter: JPKIIDSDKAdapter?) {
        self.jpkiAdapter = jpkiAdapter
    }

    /// Start the IC Chip KYC flow with automatic RakutenAnalytics initialization
    ///
    /// - Parameters:
    ///   - parentController: The parent view controller to present the KYC flow
    ///   - minor: Whether the user is a minor
    ///   - idid: The identification ID
    ///   - redirectUri: The redirect URI after completion
    ///   - ratInitializers: Optional RAT analytics initializers
    ///   - supportedKycTypes: Supported KYC types (e.g., "IC")
    ///   - baseURL: Base URL for the KYC API
    ///   - enableSecurityCheck: Whether to enable security checks (default: true)
    ///   - completionHandler: Completion handler with success status and optional message
    ///
    /// - Throws: RMOnboardingError if the flow cannot be started
    public func startICChipKYC(
        parentController: UIViewController,
        minor: Bool,
        idid: String,
        redirectUri: String,
        ratInitializers: RatInitializers? = nil,
        supportedKycTypes: String,
        baseURL: String,
        enableSecurityCheck: Bool = true,
        completionHandler: @escaping (Bool, String?) -> Void
    ) async throws {
        // Set parent view controller for JPKI flow
        jpkiAdapter?.setParentViewController(parentController)

        // Delegate to OneClick SDK
        try await OneClickSdk.startICChipKYC(
            parentController: parentController,
            minor: minor,
            idid: idid,
            redirectUri: redirectUri,
            ratInitializers: ratInitializers,
            supportedKycTypes: supportedKycTypes,
            baseURL: baseURL,
            enableSecurityCheck: enableSecurityCheck,
            completionHandler: completionHandler
        )
    }

    /// Start the IC Chip KYC flow from a deep link or custom scheme URL
    ///
    /// - Parameters:
    ///   - parentController: The parent view controller to present the KYC flow
    ///   - url: Universal link or custom scheme URL
    ///   - ratInitializers: Optional RAT analytics initializers
    ///   - baseURL: Base URL for the KYC API
    ///   - enableSecurityCheck: Whether to enable security checks (default: true)
    ///   - completionHandler: Completion handler with success status and optional message
    ///
    /// - Throws: RMOnboardingError if the URL is invalid or the flow cannot be started
    public func startICChipKYC(
        parentController: UIViewController,
        url: URL,
        ratInitializers: RatInitializers? = nil,
        baseURL: String,
        enableSecurityCheck: Bool = true,
        completionHandler: @escaping (Bool, String?) -> Void
    ) async throws {
        // Set parent view controller for JPKI flow
        jpkiAdapter?.setParentViewController(parentController)

        // Delegate to RMOnboardingSDK's URL-based method
        try await RMOnboardingSDK.startICChipKYC(
            parentController: parentController,
            url: url,
            ratInitializers: ratInitializers,
            baseURL: baseURL,
            enableSecurityCheck: enableSecurityCheck,
            completionHandler: completionHandler
        )
    }
}

/// Main entry point for RMOnboardingSDK
/// Provides simplified initialization and wrapper methods for consuming apps
@MainActor
public enum RMOnboardingSDK {

    private static var isInitialized = false
    private static var jpkiAdapter: JPKIIDSDKAdapter?

    /// Internal initialization - automatically called when using RMOnboardingSDK methods
    private static func initializeIfNeeded() {
        guard !isInitialized else {
            return
        }

        // Create and inject the RakutenAnalytics adapter
        let ratAdapter = RatSdkRakutenAnalyticsAdapter()
        RatSdk.setSharedInstance(ratAdapter)

        // Create and inject the IDSDK JPKI adapter
        let adapter = JPKIIDSDKAdapter()
        JPKIHandler.setSharedInstance(adapter)
        jpkiAdapter = adapter

        isInitialized = true
        debugPrint("[RMOnboardingSDK] Successfully initialized with RakutenAnalytics and IDSDK adapters")
    }

    /// Start the IC Chip KYC flow with automatic RakutenAnalytics initialization
    ///
    /// - Parameters:
    ///   - parentController: The parent view controller to present the KYC flow
    ///   - minor: Whether the user is a minor
    ///   - idid: The identification ID
    ///   - redirectUri: The redirect URI after completion
    ///   - ratInitializers: Optional RAT analytics initializers
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
    /// let ratConfig = RatInitializers(
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
    ///     ratInitializers: ratConfig,
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
        ratInitializers: RatInitializers? = nil,
        supportedKycTypes: String,
        baseURL: String,
        enableSecurityCheck: Bool = true,
        completionHandler: @escaping (Bool, String?) -> Void
    ) async throws {
        // Automatically initialize RakutenAnalytics adapter if not already done
        initializeIfNeeded()

        // Set parent view controller for JPKI flow
        jpkiAdapter?.setParentViewController(parentController)

        // Delegate to OneClick SDK
        try await OneClickSdk.startICChipKYC(
            parentController: parentController,
            minor: minor,
            idid: idid,
            redirectUri: redirectUri,
            ratInitializers: ratInitializers,
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
    ///   - ratInitializers: Optional RAT analytics initializers
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
    /// let deepLinkURL = URL(string: "https://example.com/ekyc/ic?idid=123&minor=false&redirect_uri=app://callback&supported_kyc_types=IC")!
    ///
    /// try await RMOnboardingSDK.startICChipKYC(
    ///     parentController: self,
    ///     url: deepLinkURL,
    ///     ratInitializers: ratConfig,
    ///     baseURL: "https://your-api-url.com"
    /// ) { success, message in
    ///     print("KYC completed: \(success)")
    /// }
    /// ```
    public static func startICChipKYC(
        parentController: UIViewController,
        url: URL,
        ratInitializers: RatInitializers? = nil,
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
        let decodedRedirectUri = redirectUri.removingPercentEncoding ?? redirectUri
        let supportedKycTypes = queryItems?.first(where: { $0.name == "supported_kyc_types" })?.value ?? ""

        // Parse minor parameter (defaults to false if not present or invalid)
        let minorString = queryItems?.first(where: { $0.name == "minor" })?.value
        let minor = minorString == "true"

        // Call the main startICChipKYC method with parsed parameters
        try await startICChipKYC(
            parentController: parentController,
            minor: minor,
            idid: idid,
            redirectUri: decodedRedirectUri,
            ratInitializers: ratInitializers,
            supportedKycTypes: supportedKycTypes,
            baseURL: baseURL,
            enableSecurityCheck: enableSecurityCheck,
            completionHandler: completionHandler
        )
    }

    /// Configure JPKI with SessionProvider from RakutenOneAuth
    /// This should be called by the app after authentication
    /// Returns a JPKIConfiguration object that can be used to chain startICChipKYC calls
    /// - Parameters:
    ///   - sessionProvider: SessionProvider from RakutenOneAuth
    ///   - clientID: Client ID for the redeemer (provided by the host app)
    ///   - environment: Environment configuration (staging, production, or custom). Defaults to staging.
    /// - Returns: JPKIConfiguration object for method chaining
    @discardableResult
    public static func configureJPKI(
        sessionProvider: SessionProvider,
        clientID: String,
        environment: JPKIEnvironment = .staging
    ) -> JPKIConfiguration {
        // Ensure SDK is initialized first
        initializeIfNeeded()

        // Configure the JPKI adapter with session provider, client ID, and environment
        jpkiAdapter?.configure(sessionProvider: sessionProvider, clientID: clientID, environment: environment)
        debugPrint("[RMOnboardingSDK] JPKI configured with SessionProvider, clientID: \(clientID), environment: \(environment)")

        return JPKIConfiguration(jpkiAdapter: jpkiAdapter)
    }

    public static func startOneClickWebview(
        parentController: UIViewController,
        sourceApplication: String,
        portUrl: String,
        accessToken: String,
        locale: String,
        ratInitializers: RatInitializers? = nil,
        baseURLForIC: String
    ){
        // Automatically initialize RakutenAnalytics adapter if not already done
        initializeIfNeeded()
        let config = OneClickSdkConfig(sourceApplication:  sourceApplication)
        let oneClick = OneClickSdk(config: config, parent: parentController)
        oneClick.startWebView(url: portUrl, token: accessToken, localId: locale, ratConfig: ratInitializers, baseUrl: baseURLForIC)
    }
    
    /// Check if the SDK has been initialized
    public static var initialized: Bool {
        return isInitialized
    }
}
