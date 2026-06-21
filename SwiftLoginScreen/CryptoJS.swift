//
//  CryptoJS.swift
//
//  Created by Emartin on 2015-08-25.
//  Copyright (c) 2015 Emartin. All rights reserved.
//

import CryptoSwift
import Foundation


/// Native crypto primitives that preserve the existing wire-contract outputs.
enum NativeCrypto {
    /// CryptoJS.SHA3 actually uses Keccak padding (legacy behavior), not NIST SHA3.
    /// We intentionally use Keccak variants for wire/db compatibility.
    static func sha3Hex(_ input: String, outputLength: Int = 512) throws -> String {
        let variant: SHA3.Variant
        switch outputLength {
        case 224: variant = .keccak224
        case 256: variant = .keccak256
        case 384: variant = .keccak384
        default: variant = .keccak512
        }
        return try input.bytes.sha3(variant).toHexString()
    }

    static func hmacSHA512Base64(message: String, secret: String) throws -> String {
        let authenticator = try HMAC(key: secret.bytes, variant: .sha2(.sha512))
        let digest = try authenticator.authenticate(message.bytes)
        return digest.toBase64()
    }

    /// Matches legacy CryptoJS `encrypt_` behavior:
    /// - PBKDF2 with SHA1
    /// - AES-CBC with PKCS7 padding
    /// - Base64 output of raw ciphertext bytes
    static func encryptLegacyAES(
        keySizeBits: Int,
        iterationCount: Int,
        saltHex: String,
        ivHex: String,
        passPhrase: String,
        plainText: String
    ) throws -> String {
        let keyLength = max(16, keySizeBits / 8)
        let keyDerivation = try PKCS5.PBKDF2(
            password: passPhrase.bytes,
            salt: Array<UInt8>(hex: saltHex),
            iterations: iterationCount,
            keyLength: keyLength,
            variant: .sha1
        )
        let key = try keyDerivation.calculate()
        let aes = try AES(
            key: key,
            blockMode: CBC(iv: Array<UInt8>(hex: ivHex)),
            padding: .pkcs7
        )
        let encrypted = try aes.encrypt(plainText.bytes)
        return encrypted.toBase64()
    }

    static func loginHMAC(postPathAndBody: String, username: String, passwordHash: String) throws -> String {
        let hmacSecret = try hmacSHA512Base64(message: username, secret: passwordHash)
        return try hmacSHA512Base64(message: postPathAndBody, secret: hmacSecret)
    }
}


