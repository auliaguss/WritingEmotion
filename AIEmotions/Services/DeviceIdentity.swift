//
//  DeviceIdentity.swift
//  AIEmotions
//
//  Provides a stable per-device identifier.
//  identifierForVendor can change if the app is deleted and reinstalled,
//  so we cache the first value we see in the Keychain (which survives
//  reinstalls) and keep reusing that.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Security

enum DeviceIdentity {

    private static let service = "com.aiemotions.deviceID"
    private static let account = "primary"

    /// The stable device identifier for this install. Reads from Keychain
    /// first; falls back to `identifierForVendor`, then a fresh UUID.
    static var current: String {
        if let existing = readFromKeychain() {
            return existing
        }
        let fresh = freshIdentifier()
        saveToKeychain(fresh)
        return fresh
    }

    private static func freshIdentifier() -> String {
        #if canImport(UIKit)
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        return UUID().uuidString
        #endif
    }

    private static func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private static func saveToKeychain(_ value: String) -> Bool {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        // Clear any stale entry first, then add fresh — simpler than update.
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }
}
