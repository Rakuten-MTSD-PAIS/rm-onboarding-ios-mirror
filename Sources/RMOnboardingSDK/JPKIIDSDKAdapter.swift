//
//  JPKIIDSDKAdapter.swift
//  RMOnboardingSDK
//
//  Created by Claude Code
//

import Foundation
import OneClick
import UIKit
import RakutenOneAuthEkyc
import RakutenOneAuthCore

/// Environment configuration for JPKI
public enum JPKIEnvironment {
    case staging
    case production
    case custom(jpkiUrl: String, languageUrl: String, exchangeTokenAudience: String = "jpki")

    var jpkiUrl: String {
        switch self {
        case .staging:
            return "https://stg-jpki.id.rakuten.co.jp"
        case .production:
            return "https://jpki.id.rakuten.co.jp"
        case .custom(let jpkiUrl, _, _):
            return jpkiUrl
        }
    }

    var languageUrl: String {
        switch self {
        case .staging:
            return "https://stg-qa.static.id.rakuten.co.jp/static/ekyc/ja/generic.json"
        case .production:
            return "https://static.id.rakuten.co.jp/static/ekyc/jpn/generic.json"
        case .custom(_, let languageUrl, _):
            return languageUrl
        }
    }

    var exchangeTokenAudience: String {
        switch self {
        case .staging, .production:
            return "jpki"
        case .custom(_, _, let audience):
            return audience
        }
    }
}

/// Adapter that bridges OneClick's JPKIProtocol with RakutenOneAuth (ID SDK) implementation
@MainActor
public class JPKIIDSDKAdapter: JPKIProtocol {

    private var sessionProvider: SessionProvider?
    private weak var parentViewController: UIViewController?
    private var clientID: String?
    private var environment: JPKIEnvironment = .staging

    public init() {}

    /// Configure the adapter with SessionProvider from the app
    /// This should be called once during SDK initialization
    /// - Parameters:
    ///   - sessionProvider: SessionProvider from RakutenOneAuth
    ///   - clientID: Client ID for the redeemer (provided by the host app)
    ///   - environment: Environment configuration (staging, production, or custom). Defaults to staging.
    /// - Returns: Self for method chaining
    @discardableResult
    public func configure(
        sessionProvider: SessionProvider,
        clientID: String,
        environment: JPKIEnvironment = .staging
    ) -> JPKIIDSDKAdapter {
        self.sessionProvider = sessionProvider
        self.clientID = clientID
        self.environment = environment
        return self
    }

    /// Set the parent view controller for the current flow
    /// This is called internally by RMOnboardingSDK.startICChipKYC
    /// - Parameter viewController: The parent view controller
    internal func setParentViewController(_ viewController: UIViewController) {
        self.parentViewController = viewController
    }

    public func triggerJPKI(completion: @escaping (Result<(easyId: String, exchangeToken: String, clientID: String), Error>) -> Void) {
        debugPrint("========================================")
        debugPrint("[JPKIIDSDKAdapter] triggerJPKI called")
        debugPrint("========================================")

        // Validate SessionProvider
        guard let sessionProvider = sessionProvider else {
            let error = NSError(
                domain: "JPKIIDSDKAdapter",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "SessionProvider not configured. Call configure(sessionProvider:clientID:) first."]
            )
            debugPrint("[JPKIIDSDKAdapter] ❌ Error: SessionProvider not configured")
            completion(.failure(error))
            return
        }

        // Validate clientID
        guard let clientID = clientID, !clientID.isEmpty else {
            let error = NSError(
                domain: "JPKIIDSDKAdapter",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Client ID not configured. Call configure(sessionProvider:clientID:) first."]
            )
            debugPrint("[JPKIIDSDKAdapter] ❌ Error: Client ID not configured")
            completion(.failure(error))
            return
        }

        // Get navigation controller from parent view controller
        guard let parentVC = parentViewController,
              let navigationController = parentVC.navigationController else {
            let error = NSError(
                domain: "JPKIIDSDKAdapter",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Parent view controller or navigation controller not available."]
            )
            debugPrint("[JPKIIDSDKAdapter] ❌ Error: Navigation controller not available")
            completion(.failure(error))
            return
        }

        // STEP 1: Get session (which contains ID Token with easyId)
        // Build mediation options to show login UI if needed
        let mediationOptions: SessionMediationOptions = SessionMediationOptionsBuilder()
            .set(mediation: .wheneverRequired)
            .set(presentationAnchorProvider: { navigationController.view.window! })
            .build()

        // Get session
        sessionProvider.session(mediation: mediationOptions) { [weak self] result in
            switch result {
            case .success(let session):
                debugPrint("[JPKIIDSDKAdapter] ✅ Session retrieved successfully")
                // Now proceed with eKYC
                self?.proceedWithEKYC(session: session, sessionProvider: sessionProvider, navigationController: navigationController, clientID: clientID, completion: completion)

            case .failure(let error):
                debugPrint("[JPKIIDSDKAdapter] ❌ Failed to retrieve session: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        debugPrint("========================================")
    }

    /// Helper method to proceed with eKYC flow after session is available
    private func proceedWithEKYC(
        session: Session,
        sessionProvider: SessionProvider,
        navigationController: UINavigationController,
        clientID: String,
        completion: @escaping (Result<(easyId: String, exchangeToken: String, clientID: String), Error>) -> Void
    ) {
        // STEP 2: Extract easyId from idToken using StandardClaim.subject
        guard let easyId: String = session.idToken[StandardClaim.subject], !easyId.isEmpty else {
            let error = NSError(
                domain: "JPKIIDSDKAdapter",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve easyId from session. User may need to re-authenticate."]
            )
            debugPrint("[JPKIIDSDKAdapter] ❌ Error: easyId not found in idToken")
            completion(.failure(error))
            return
        }

        debugPrint("[JPKIIDSDKAdapter] ✅ Found easyId: \(easyId)")

        // Build EKyc configuration
        let ekycConfig: EKycOptions
        do {
            ekycConfig = try EKycOptionsBuilder()
                .set(callingNavigationController: navigationController)
                .set(jpkiUrl: environment.jpkiUrl)
                .set(languageUrl: environment.languageUrl)
                .set(redeemerClientId: clientID)
                .build()
        } catch {
            debugPrint("[JPKIIDSDKAdapter] ❌ Error building EKyc configuration: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        debugPrint("[JPKIIDSDKAdapter] Starting RakutenOneAuth eKYC flow...")
        debugPrint("[JPKIIDSDKAdapter] Environment: \(environment)")
        debugPrint("[JPKIIDSDKAdapter] JPKI URL: \(environment.jpkiUrl)")
        debugPrint("[JPKIIDSDKAdapter] Language URL: \(environment.languageUrl)")
        debugPrint("[JPKIIDSDKAdapter] Exchange Token Audience: \(environment.exchangeTokenAudience)")

        // STEP 3: Call RakutenOneAuth eKYC to get ekyc_access_key
        sessionProvider.eKYC(configuration: ekycConfig) { [weak self] result in
            switch result {
            case .success(let ekycAccessToken):
                debugPrint("[JPKIIDSDKAdapter] ✅ eKYC Success")
                debugPrint("[JPKIIDSDKAdapter] eKYC Access Key: \(ekycAccessToken.value)")
                debugPrint("[JPKIIDSDKAdapter] Token valid until: \(Date(timeIntervalSince1970: ekycAccessToken.validUntil))")

                // STEP 4: Get Exchange Token using ekyc_access_key
                self?.getExchangeToken(
                    sessionProvider: sessionProvider,
                    navigationController: navigationController,
                    ekycAccessKey: ekycAccessToken.value,
                    clientID: clientID,
                    easyId: easyId,
                    completion: completion
                )

            case .failure(let error):
                debugPrint("[JPKIIDSDKAdapter] ❌ eKYC Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    /// Get Exchange Token from ID SDK using ekyc_access_key
    /// This matches the Android implementation in IdSdkJpkiManager.performJPKIVerification
    private func getExchangeToken(
        sessionProvider: SessionProvider,
        navigationController: UINavigationController,
        ekycAccessKey: String,
        clientID: String,
        easyId: String,
        completion: @escaping (Result<(easyId: String, exchangeToken: String, clientID: String), Error>) -> Void
    ) {
        debugPrint("[JPKIIDSDKAdapter] Creating exchange token provider with ekyc_access_key...")

        // Create exchange token provider with replay parameters including ekyc_access_key
        // This matches Android: replay = buildJsonObject { put("redeemer", redeemerClientId); put("ekyc_access_key", ekycAccessToken.value) }

        // Build configuration dictionary with audience, scope, and replay
        var configuration: [String: Any] = [
            "audience": self.environment.exchangeTokenAudience,
            "scope": []// Empty scope array as not required for JPKI
        ]

        // Add replay parameters with redeemer and ekyc_access_key
        configuration["replay"] = [
            "redeemer": clientID,
            "ekyc_access_key": ekycAccessKey
        ]

        // Create ArtifactSpecification
        let artifactSpec = ArtifactSpecification(
            identifier: "tokens::exchange",
            configuration: configuration,
            allowSiblings: true
        )

        // Get exchange token provider
        let exchangeTokenProvider = sessionProvider.artifacts.exchangeToken(configuration: artifactSpec).provider()

        // Build mediation options
        let mediationOptions: SessionMediationOptions = SessionMediationOptionsBuilder()
            .set(mediation: .wheneverRequired)
            .set(presentationAnchorProvider: { navigationController.view.window! })
            .build()

        debugPrint("[JPKIIDSDKAdapter] Requesting exchange token from ID SDK...")

        // Get the exchange token
        exchangeTokenProvider.token(mediation:mediationOptions ) { result in
            switch result {
            case .success(let exchangeToken):
                debugPrint("[JPKIIDSDKAdapter] ✅ Exchange Token retrieved successfully")
                debugPrint("[JPKIIDSDKAdapter] Exchange Token: \(exchangeToken.value)")
                debugPrint("[JPKIIDSDKAdapter] Easy ID: \(easyId)")
                debugPrint("[JPKIIDSDKAdapter] Client ID: \(clientID)")
                debugPrint("[JPKIIDSDKAdapter] Token valid until: \(Date(timeIntervalSince1970: exchangeToken.validUntil))")

                // Return easyId, exchangeToken (NOT ekycAccessToken), and clientID
                completion(.success((easyId: easyId, exchangeToken: exchangeToken.value, clientID: clientID)))

            case .failure(let error):
                debugPrint("[JPKIIDSDKAdapter] ❌ Failed to retrieve exchange token: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}
