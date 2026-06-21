// ciphertext.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import UIKit

// cipherText - if not changing - should be stored for better performance
typealias cipher = String
let cipherText = cipher("")

@MainActor
func currentDeviceId() -> String {
    UIDevice.current.identifierForVendor?.uuidString ?? ""
}

extension String {
    func getCipherText(_ plaintext: String) -> String {
        let iterationCount = 1000
        let keySize = 128
        let plainText = plaintext
        let passPhrase = "SecretPassphrase"
        let iv = "F27D5C9927726BCEFE7510B1BDD3D137"
        let salt = "3FF2EC019C627B945225DEBAD71A01B6985FE84C95A70EB132882F88C0A59A55"

        do {
            return try NativeCrypto.encryptLegacyAES(
                keySizeBits: keySize,
                iterationCount: iterationCount,
                saltHex: salt,
                ivHex: iv,
                passPhrase: passPhrase,
                plainText: plainText
            )
        } catch {
            NSLog("[Crypto] ciphertext generation failed: %@", String(describing: error))
            return ""
        }
    }
}
