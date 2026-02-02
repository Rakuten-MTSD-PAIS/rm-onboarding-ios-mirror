//
//  RatSdkRakutenAnalyticsAdapter.swift
//  RMOnboardingSDK
//
//  Created by Claude Code
//

import Foundation
import OneClick
import RakutenAnalytics

/// Concrete implementation of RatSdkProtocol using RakutenAnalytics
/// This adapter bridges the OneClick framework with RakutenAnalytics SDK
public final class RatSdkRakutenAnalyticsAdapter: RatSdkProtocol {

    private var customerId: String?
    private var contractedPlan: String?
    private var accountId: Int?
    private var applicationId: Int?
    private var ssc: String?

    private let allowedBundleIdentifier = "com.yourcompany.yourapp"

    private var isTrackingAllowed: Bool {
        return true
        //return Bundle.main.bundleIdentifier == allowedBundleIdentifier
    }

    public init() {}

    // MARK: - RatSdkProtocol Implementation

    public func initialize(
        customerId: String?,
        contractedPlan: String?,
        accountId: Int,
        applicationId: Int,
        ssc: String
    ) {
        self.customerId = customerId
        self.contractedPlan = contractedPlan
        self.accountId = accountId
        self.applicationId = applicationId
        self.ssc = ssc
        debugPrint("RatSdkRakutenAnalyticsAdapter initialized with customerId: \(String(describing: customerId)), contractedPlan: \(String(describing: contractedPlan))")
    }

    public func trackPageViewEvent(pageName: String, customParams: [String: Any]) {
        let payload = pageViewData(pageName: pageName, customParams: customParams)
        debugPrint("Tracking Page View Event for page: \(pageName)")
        debugPrint("Payload: \(payload)")
        trackEvent(eventName: EventType.pageView.rawValue, payload: payload)
    }

    public func trackClickEvent(pageName: String, targetElement: String, customParams: [String: Any]) {
        let payload = clickData(pageName: pageName, targetElement: targetElement, customParams: customParams)
        debugPrint("Tracking Click Event on page: \(pageName), element: \(targetElement)")
        debugPrint("Payload: \(payload)")
        trackEvent(eventName: EventType.click.rawValue, payload: payload)
    }

    // MARK: - Private Helper Methods

    private func pageViewData(pageName: String, customParams: [String: Any]) -> [String: Any] {
        guard let accountId = accountId,
              let applicationId = applicationId,
              let ssc = ssc else {
            return [:]
        }
        var params: [String: Any] = [
            "acc": accountId,
            "aid": applicationId,
            "ssc": ssc,
            "pgn": pageName,
            "genre": RATConstants.flavour,
            "etype": EventType.pageView.rawValue,
            "customerid" : customerId ?? "",
            "cp": [
                "contracted_plan": contractedPlan ?? ""
            ]
        ]
        params.merge(customParams) { _, new in new }
        return params
    }

    private func clickData(pageName: String, targetElement: String, customParams: [String: Any]) -> [String: Any] {
        guard let accountId = accountId,
              let applicationId = applicationId,
              let ssc = ssc else {
            return [:]
        }
        var params: [String: Any] = [
            "acc": accountId,
            "aid": applicationId,
            "ssc": ssc,
            "pgn": pageName,
            "genre": RATConstants.flavour,
            "etype": EventType.click.rawValue,
            "customerid" : customerId ?? "",
            "cp": [
                "contracted_plan": contractedPlan ?? ""
            ],
            "target_ele": targetElement
        ]
        params.merge(customParams) { _, new in new }
        return params
    }

    private func trackEvent(eventName: String, payload: [String: Any]) {
        guard isTrackingAllowed else {
            debugPrint("Tracking not allowed due to bundle ID restriction.")
            return
        }
        debugPrint("Sending event '\(eventName)' to RakutenAnalytics")

        let tracker = RAnalyticsRATTracker.shared()
        tracker.event(withEventType: eventName, parameters: payload).track()
    }
}
