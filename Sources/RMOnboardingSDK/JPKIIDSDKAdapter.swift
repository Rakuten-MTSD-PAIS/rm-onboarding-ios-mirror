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

/// Adapter that bridges OneClick's JPKIProtocol with RakutenOneAuth (ID SDK) implementation
public class JPKIIDSDKAdapter: JPKIProtocol {

    private var sessionProvider: SessionProvider?
    private weak var parentViewController: UIViewController?

    // Hardcoded eKYC configuration URLs
    private let jpkiUrl = "https://stg-jpki.id.rakuten.co.jp"
    private let languageUrl = "https://stg-qa.static.id.rakuten.co.jp/static/ekyc/ja/generic.json"

    public init() {}

    /// Configure the adapter with SessionProvider from the app
    /// This should be called once during SDK initialization
    /// - Parameter sessionProvider: SessionProvider from RakutenOneAuth
    public func configure(sessionProvider: SessionProvider) {
        self.sessionProvider = sessionProvider
    }

    /// Set the parent view controller for the current flow
    /// This is called internally by RMOnboardingSDK.startICChipKYC
    /// - Parameter viewController: The parent view controller
    internal func setParentViewController(_ viewController: UIViewController) {
        self.parentViewController = viewController
    }

    public func triggerJPKI(completion: @escaping (Result<(easyId: String, exchangeToken: String), Error>) -> Void) {
        debugPrint("========================================")
        debugPrint("[JPKIIDSDKAdapter] triggerJPKI called")
        debugPrint("========================================")

        // Validate SessionProvider
        guard let sessionProvider = sessionProvider else {
            let error = NSError(
                domain: "JPKIIDSDKAdapter",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "SessionProvider not configured. Call configure(sessionProvider:) first."]
            )
            debugPrint("[JPKIIDSDKAdapter] ❌ Error: SessionProvider not configured")
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

        // Build EKyc configuration
        let ekycConfig: EKycOptions
        do {
            ekycConfig = try EKycOptionsBuilder()
                .set(callingNavigationController: navigationController)
                .set(jpkiUrl: jpkiUrl)
                .set(languageUrl: languageUrl)
                .build()
        } catch {
            debugPrint("[JPKIIDSDKAdapter] ❌ Error building EKyc configuration: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        debugPrint("[JPKIIDSDKAdapter] Starting RakutenOneAuth eKYC flow...")
        debugPrint("[JPKIIDSDKAdapter] JPKI URL: \(jpkiUrl)")
        debugPrint("[JPKIIDSDKAdapter] Language URL: \(languageUrl)")

        // Call RakutenOneAuth eKYC
        sessionProvider.eKYC(configuration: ekycConfig) { result in
            switch result {
            case .success(let token):
                debugPrint("[JPKIIDSDKAdapter] ✅ eKYC Success")
                debugPrint("[JPKIIDSDKAdapter] Access Token (exchangeToken): \(token.value)")
                debugPrint("[JPKIIDSDKAdapter] Token valid until: \(Date(timeIntervalSince1970: token.validUntil))")

                // Return accessToken as exchangeToken, easyId is empty for now
                completion(.success((easyId: "", exchangeToken: token.value)))

            case .failure(let error):
                debugPrint("[JPKIIDSDKAdapter] ❌ eKYC Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        debugPrint("========================================")
    }
}
