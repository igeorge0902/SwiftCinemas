//
//  ciphertext.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 30/12/15.
//  Copyright © 2015 George Gaspar. All rights reserved.
//

import Foundation

// cipherText - if not changing - should be stored for better performance
typealias cipher = String
let cipherText = cipher("")

extension String {
    func getCipherText(_ plaintext: String) -> String {
        let iterationCount = 1000
        let keySize = 128
        let plainText = plaintext
        let passPhrase = "SecretPassphrase"
        let iv = "F27D5C9927726BCEFE7510B1BDD3D137"
        let salt = "3FF2EC019C627B945225DEBAD71A01B6985FE84C95A70EB132882F88C0A59A55"

        let AES = CryptoJS.AES()

        let ciphertext = AES.encrypt_(keySize, iterationCount: iterationCount, salt: salt, iv: iv, passPhrase: passPhrase, plainText: plainText)

        return ciphertext
    }
}
