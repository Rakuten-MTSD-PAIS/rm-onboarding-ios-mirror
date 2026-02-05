//
//  RMOnboardingSDKExports.swift
//  RMOnboardingSDK
//
//  Created by Claude Code
//

import Foundation

// Re-export OneClick module types so consumers only need to import RMOnboardingSDK
@_exported import OneClick

// Re-export RakutenOneAuthCore for SessionProvider access
@_exported import RakutenOneAuthCore

// MARK: - Type Aliases for Better API

/// Error type for RMOnboardingSDK operations
/// This is an alias for OneClickSdkError to provide clearer error handling
public typealias RMOnboardingError = OneClickSdkError
