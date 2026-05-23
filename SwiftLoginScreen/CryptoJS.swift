// CryptoJS.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import JavaScriptCore

@MainActor
open class CryptoJS {
    // MARK: Open

    open class AES: CryptoJS {
        // MARK: Lifecycle

        override init() {
            super.init()

            // Retrieve the content of aes.js
            let cryptoJSpath = Bundle.main.path(forResource: "aes", ofType: "js")
            let cryptoJSpathPBKDF2 = Bundle.main.path(forResource: "pbkdf2", ofType: "js")

            if cryptoJSpath != nil, cryptoJSpathPBKDF2 != nil {
                // let cryptoJS = String(contentsOfFile: cryptoJSpath!, encoding:NSUTF8StringEncoding, error: nil)
                do {
                    let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)
                    let cryptoJSPBKDF2 = try String(contentsOfFile: cryptoJSpathPBKDF2!, encoding: String.Encoding.utf8)

                    print("Loaded aes.js")
                    print("Loaded pbkdf2.js")

                    // Evaluate .js
                    _ = cryptoJScontext?.evaluateScript(cryptoJS)
                    _ = cryptoJScontext?.evaluateScript(cryptoJSPBKDF2)

                    // Reference functions
                    encryptFunction = cryptoJScontext?.objectForKeyedSubscript("encrypt")
                    decryptFunction = cryptoJScontext?.objectForKeyedSubscript("decrypt")
                    encryptFunction_ = cryptoJScontext?.objectForKeyedSubscript("encrypt_")
                } catch {
                    print("Unable to load aes.js")
                }
            } else {
                print("Unable to find aes.js")
            }
        }

        // MARK: Open

        open func encrypt_(_ keySize: Int, iterationCount: Int, salt: String, iv: String, passPhrase: String, plainText: String) -> String {
            cryptoJScontext?.exceptionHandler = { _, exception in
                print("AES JS RunTime Error: \(exception!)")
            }

            return "\(encryptFunction_.call(withArguments: [keySize, iterationCount, salt, iv, passPhrase, plainText])!)"
        }

        open func encrypt(_ secretMessage: String, secretKey: String, options: AnyObject? = nil) -> String {
            if let unwrappedOptions: AnyObject = options {
                return "\(encryptFunction.call(withArguments: [secretMessage, secretKey, unwrappedOptions])!)"
            } else {
                return "\(encryptFunction.call(withArguments: [secretMessage, secretKey])!)"
            }
        }

        open func decrypt(_ encryptedMessage: String, secretKey: String, options: AnyObject? = nil) -> String {
            if let unwrappedOptions: AnyObject = options {
                return "\(decryptFunction.call(withArguments: [encryptedMessage, secretKey, unwrappedOptions])!)"
            } else {
                return "\(decryptFunction.call(withArguments: [encryptedMessage, secretKey])!)"
            }
        }

        // MARK: Fileprivate

        fileprivate var encryptFunction: JSValue!
        fileprivate var decryptFunction: JSValue!
        fileprivate var encryptFunction_: JSValue!
    }

    open class MD5: CryptoJS {
        // MARK: Lifecycle

        override init() {
            super.init()

            // Retrieve the content of md5.js
            let cryptoJSpath = Bundle.main.path(forResource: "md5", ofType: "js")

            if cryptoJSpath != nil {
                do {
                    let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)

                    print("Loaded md5.js")

                    // Evaluate md5.js
                    _ = cryptoJScontext?.evaluateScript(cryptoJS)

                    // Reference functions
                    MD5 = cryptoJScontext?.objectForKeyedSubscript("MD5")
                } catch {
                    print("Unable to load md5.js")
                }

            } else {
                print("Unable to find md5.js")
            }
        }

        // MARK: Open

        open func hash(_ string: String) -> String {
            return "\(MD5.call(withArguments: [string])!)"
        }

        // MARK: Fileprivate

        fileprivate var MD5: JSValue!
    }

    open class SHA1: CryptoJS {
        // MARK: Lifecycle

        override init() {
            super.init()

            // Retrieve the content of sha1.js
            let cryptoJSpath = Bundle.main.path(forResource: "sha1", ofType: "js")

            if cryptoJSpath != nil {
                do {
                    let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)

                    print("Loaded sha1.js")

                    // Evaluate sha1.js
                    _ = cryptoJScontext?.evaluateScript(cryptoJS)

                    // Reference functions
                    SHA1 = cryptoJScontext?.objectForKeyedSubscript("SHA1")
                } catch {
                    print("Unable to load sha1.js")
                }

            } else {
                print("Unable to find sha1.js")
            }
        }

        // MARK: Open

        open func hash(_ string: String) -> String {
            return "\(SHA1.call(withArguments: [string])!)"
        }

        // MARK: Fileprivate

        fileprivate var SHA1: JSValue!
    }

    open class SHA224: CryptoJS {
        // MARK: Lifecycle

        override init() {
            super.init()

            // Retrieve the content of sha224.js
            let cryptoJSpath = Bundle.main.path(forResource: "sha224", ofType: "js")

            if cryptoJSpath != nil {
                do {
                    let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)

                    print("Loaded sha224.js")

                    // Evaluate sha224.js
                    _ = cryptoJScontext?.evaluateScript(cryptoJS)

                    // Reference functions
                    SHA224 = cryptoJScontext?.objectForKeyedSubscript("SHA224")
                } catch {
                    print("Unable to load sha224.js")
                }

            } else {
                print("Unable to find sha224.js")
            }
        }

        // MARK: Open

        open func hash(_ string: String) -> String {
            return "\(SHA224.call(withArguments: [string])!)"
        }

        // MARK: Fileprivate

        fileprivate var SHA224: JSValue!
    }

    open class SHA256: CryptoJS {
        // MARK: Lifecycle

        override init() {
            super.init()

            // Retrieve the content of sha256.js
            let cryptoJSpath = Bundle.main.path(forResource: "sha256", ofType: "js")

            if cryptoJSpath != nil {
                do {
                    let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)

                    print("Loaded sha256.js")

                    // Evaluate sha256.js
                    _ = cryptoJScontext?.evaluateScript(cryptoJS)

                    // Reference functions
                    SHA256 = cryptoJScontext?.objectForKeyedSubscript("SHA256")
                } catch {
                    print("Unable to load sha256.js")
                }

            } else {
                print("Unable to find sha256.js")
            }
        }

        // MARK: Open

        open func hash(_ string: String) -> String {
            return "\(SHA256.call(withArguments: [string])!)"
        }

        // MARK: Fileprivate

        fileprivate var SHA256: JSValue!
    }

    open class SHA384: CryptoJS {
        // MARK: Lifecycle

        override init() {
            super.init()

            // Retrieve the content of sha384.js
            let cryptoJSpath = Bundle.main.path(forResource: "sha384", ofType: "js")

            if cryptoJSpath != nil {
                do {
                    let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)

                    print("Loaded sha384.js")

                    // Evaluate sha384.js
                    _ = cryptoJScontext?.evaluateScript(cryptoJS)

                    // Reference functions
                    SHA384 = cryptoJScontext?.objectForKeyedSubscript("SHA384")
                } catch {
                    print("Unable to load sha384.js")
                }

            } else {
                print("Unable to find sha384.js")
            }
        }

        // MARK: Open

        open func hash(_ string: String) -> String {
            return "\(SHA384.call(withArguments: [string])!)"
        }

        // MARK: Fileprivate

        fileprivate var SHA384: JSValue!
    }

    open class SHA512: CryptoJS {
        // MARK: Lifecycle

        override init() {
            super.init()

            // Retrieve the content of sha512.js
            let cryptoJSpath = Bundle.main.path(forResource: "sha512", ofType: "js")

            if cryptoJSpath != nil {
                do {
                    let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)

                    print("Loaded sha512.js")

                    // Evaluate sha512.js
                    _ = cryptoJScontext?.evaluateScript(cryptoJS)

                    // Reference functions
                    SHA512 = cryptoJScontext?.objectForKeyedSubscript("SHA512")
                } catch {
                    print("Unable to load sha512.js")
                }

            } else {
                print("Unable to find sha512.js")
            }
        }

        // MARK: Open

        open func hash(_ string: String) -> String {
            return "\(SHA512.call(withArguments: [string])!)"
        }

        // MARK: Fileprivate

        fileprivate var SHA512: JSValue!
    }

    open class SHA3: CryptoJS {
        // MARK: Lifecycle

        override init() {
            super.init()

            // Retrieve the content of sha3.js
            let cryptoJSpath = Bundle.main.path(forResource: "sha3", ofType: "js")

            if cryptoJSpath != nil {
                do {
                    let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)

                    print("Loaded sha3.js")

                    // Evaluate sha3.js
                    _ = cryptoJScontext?.evaluateScript(cryptoJS)

                    // Reference functions
                    SHA3 = cryptoJScontext?.objectForKeyedSubscript("SHA3")
                } catch {
                    print("Unable to load sha3.js")
                }
            }
        }

        // MARK: Open

        open func hash(_ string: String, outputLength: Int? = nil) -> String {
            if let unwrappedOutputLength = outputLength {
                return "\(SHA3.call(withArguments: [string, unwrappedOutputLength])!)"
            } else {
                return "\(SHA3.call(withArguments: [string])!)"
            }
        }

        // MARK: Fileprivate

        fileprivate var SHA3: JSValue!
    }

    open class hmacSHA512: CryptoJS {
        // MARK: Lifecycle

        override init() {
            super.init()

            // Retrieve the content of hmac-sha512.js
            let cryptoJSpath = Bundle.main.path(forResource: "hmac-sha512", ofType: "js")

            if cryptoJSpath != nil {
                do {
                    let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)

                    print("Loaded hmac-sha512.js")

                    // Evaluate hmac-sha512.js
                    _ = cryptoJScontext?.evaluateScript(cryptoJS)

                    // Reference functions
                    hmacSHA512 = cryptoJScontext?.objectForKeyedSubscript("HmacSHA512")
                    hmacSHA512_ = cryptoJScontext?.objectForKeyedSubscript("HmacSHA512_")
                } catch {
                    print("Unable to load hmac-sha512.js")
                }
            }
        }

        // MARK: Open

        open func hmac(_ string: String, secret: String) -> String {
            cryptoJScontext?.exceptionHandler = { _, exception in
                print("hmacSHA512 JS RunTime Error: \(exception!)")
            }

            return "\(hmacSHA512.call(withArguments: [string, secret])!)"
        }

        open func hmac_(_ string: String, secret: String) -> String {
            cryptoJScontext?.exceptionHandler = { _, exception in
                print("hmacSHA512_ JS RunTime Error: \(exception!)")
            }

            return "\(hmacSHA512_.call(withArguments: [string, secret])!)"
        }

        // MARK: Fileprivate

        fileprivate var hmacSHA512: JSValue!
        fileprivate var hmacSHA512_: JSValue!
    }

    open class RIPEMD160: CryptoJS {
        // MARK: Lifecycle

        override init() {
            super.init()

            // Retrieve the content of ripemd160.js
            let cryptoJSpath = Bundle.main.path(forResource: "ripemd160", ofType: "js")

            if cryptoJSpath != nil {
                do {
                    let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)

                    print("Loaded ripemd160.js")

                    // Evaluate ripemd160.js
                    _ = cryptoJScontext?.evaluateScript(cryptoJS)

                    // Reference functions
                    RIPEMD160 = cryptoJScontext?.objectForKeyedSubscript("RIPEMD160")
                } catch {
                    print("Unable to load ripemd160.js")
                }
            }
        }

        // MARK: Open

        open func hash(_ string: String, outputLength: Int? = nil) -> String {
            if let unwrappedOutputLength = outputLength {
                return "\(RIPEMD160.call(withArguments: [string, unwrappedOutputLength])!)"
            } else {
                return "\(RIPEMD160.call(withArguments: [string])!)"
            }
        }

        // MARK: Fileprivate

        fileprivate var RIPEMD160: JSValue!
    }

    open class mode: CryptoJS {
        // MARK: Open

        open class CFB: CryptoJS {
            override init() {
                super.init()
                // Retrieve the content of the script
                let cryptoJSpath = Bundle.main.path(forResource: "mode-\(CryptoJS.mode().CFB.lowercased())", ofType: "js")

                if cryptoJSpath != nil {
                    do {
                        let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)
                        print("Loaded mode-\(CryptoJS.mode().CFB).js")
                        // Evaluate script
                        _ = cryptoJScontext?.evaluateScript(cryptoJS)
                    } catch {
                        print("Unable to load mode-\(CryptoJS.mode().CFB).js")
                    }
                }
            }
        }

        open class CTR: CryptoJS {
            override init() {
                super.init()
                // Retrieve the content of the script
                let cryptoJSpath = Bundle.main.path(forResource: "mode-\(CryptoJS.mode().CTR.lowercased())", ofType: "js")

                if cryptoJSpath != nil {
                    do {
                        let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)
                        print("Loaded mode-\(CryptoJS.mode().CTR).js")
                        // Evaluate script
                        _ = cryptoJScontext?.evaluateScript(cryptoJS)
                    } catch {
                        print("Unable to load mode-\(CryptoJS.mode().CTR).js")
                    }
                }
            }
        }

        open class OFB: CryptoJS {
            override init() {
                super.init()
                // Retrieve the content of the script
                let cryptoJSpath = Bundle.main.path(forResource: "mode-\(CryptoJS.mode().OFB.lowercased())", ofType: "js")

                if cryptoJSpath != nil {
                    do {
                        let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)
                        print("Loaded mode-\(CryptoJS.mode().OFB).js")
                        // Evaluate script
                        _ = cryptoJScontext?.evaluateScript(cryptoJS)
                    } catch {
                        print("Unable to load mode-\(CryptoJS.mode().OFB).js")
                    }
                }
            }
        }

        open class ECB: CryptoJS {
            override init() {
                super.init()
                // Retrieve the content of the script
                let cryptoJSpath = Bundle.main.path(forResource: "mode-\(CryptoJS.mode().ECB.lowercased())", ofType: "js")

                if cryptoJSpath != nil {
                    do {
                        let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)
                        print("Loaded mode-\(CryptoJS.mode().ECB).js")
                        // Evaluate script
                        _ = cryptoJScontext?.evaluateScript(cryptoJS)
                    } catch {
                        print("Unable to load mode-\(CryptoJS.mode().ECB).js")
                    }
                }
            }
        }

        // MARK: Internal

        var CFB: String = "CFB"
        var CTR: String = "CTR"
        var OFB: String = "OFB"
        var ECB: String = "ECB"
    }

    open class pad: CryptoJS {
        // MARK: Open

        open class AnsiX923: CryptoJS {
            override init() {
                super.init()
                // Retrieve the content of the script
                let cryptoJSpath = Bundle.main.path(forResource: "pad-\(CryptoJS.pad().AnsiX923.lowercased())", ofType: "js")

                if cryptoJSpath != nil {
                    do {
                        let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)
                        print("Loaded pad-\(CryptoJS.pad().AnsiX923).js")
                        // Evaluate script
                        _ = cryptoJScontext?.evaluateScript(cryptoJS)
                    } catch {
                        print("Unable to load pad-\(CryptoJS.pad().AnsiX923).js")
                    }
                }
            }
        }

        open class Iso97971: CryptoJS {
            override init() {
                super.init()

                // Load dependencies
                _ = CryptoJS.pad.ZeroPadding()

                // Retrieve the content of the script
                let cryptoJSpath = Bundle.main.path(forResource: "pad-\(CryptoJS.pad().Iso97971.lowercased())", ofType: "js")

                if cryptoJSpath != nil {
                    do {
                        let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)
                        print("Loaded pad-\(CryptoJS.pad().Iso97971).js")
                        // Evaluate script
                        _ = cryptoJScontext?.evaluateScript(cryptoJS)
                    } catch {
                        print("Unable to load pad-\(CryptoJS.pad().Iso97971).js")
                    }
                }
            }
        }

        open class Iso10126: CryptoJS {
            override init() {
                super.init()
                // Retrieve the content of the script
                let cryptoJSpath = Bundle.main.path(forResource: "pad-\(CryptoJS.pad().Iso10126.lowercased())", ofType: "js")

                if cryptoJSpath != nil {
                    do {
                        let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)
                        print("Loaded pad-\(CryptoJS.pad().Iso10126).js")
                        // Evaluate script
                        _ = cryptoJScontext?.evaluateScript(cryptoJS)
                    } catch {
                        print("Unable to load pad-\(CryptoJS.pad().Iso10126).js")
                    }
                }
            }
        }

        open class ZeroPadding: CryptoJS {
            override init() {
                super.init()
                // Retrieve the content of the script
                let cryptoJSpath = Bundle.main.path(forResource: "pad-\(CryptoJS.pad().ZeroPadding.lowercased())", ofType: "js")

                if cryptoJSpath != nil {
                    do {
                        let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)
                        print("Loaded pad-\(CryptoJS.pad().ZeroPadding).js")
                        // Evaluate script
                        _ = cryptoJScontext?.evaluateScript(cryptoJS)
                    } catch {
                        print("Unable to load pad-\(CryptoJS.pad().ZeroPadding).js")
                    }
                }
            }
        }

        open class NoPadding: CryptoJS {
            override init() {
                super.init()
                // Retrieve the content of the script
                let cryptoJSpath = Bundle.main.path(forResource: "pad-\(CryptoJS.pad().NoPadding.lowercased())", ofType: "js")

                if cryptoJSpath != nil {
                    do {
                        let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)
                        print("Loaded pad-\(CryptoJS.pad().NoPadding).js")
                        // Evaluate script
                        _ = cryptoJScontext?.evaluateScript(cryptoJS)
                    } catch {
                        print("Unable to load pad-\(CryptoJS.pad().NoPadding).js")
                    }
                }
            }
        }

        // MARK: Internal

        var AnsiX923: String = "AnsiX923"
        var Iso97971: String = "Iso97971"
        var Iso10126: String = "Iso10126"
        var ZeroPadding: String = "ZeroPadding"
        var NoPadding: String = "NoPadding"
    }

    // MARK: Internal

    let cryptoJScontext = JSContext()
}
