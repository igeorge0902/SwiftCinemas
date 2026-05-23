// LoginVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Security
import UIKit

@MainActor
let deviceId = UIDevice.current.identifierForVendor!.uuidString
nonisolated(unsafe) var kKeychainItemName: String?
final class LoginVC: UIViewController, UITextFieldDelegate, HasAppServices {
    // MARK: Lifecycle

    deinit {
        print(#function, "\(self)")
    }

    // MARK: Internal

    enum KeychainError: Error {
        case noPassword
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
    }

    var appServices: AppServices!

    var username: NSString?
    var password: NSString?

    var imageView: UIImageView = .init()
    var backgroundDict: [String: String] = Dictionary()

    @IBOutlet var txtUsername: UITextField!
    @IBOutlet var txtPassword: UITextField!

    override func viewWillAppear(_: Bool) {
        let prefs = UserDefaults.standard
        let isLoggedIn: Int = prefs.integer(forKey: "ISLOGGEDIN") as Int

        if isLoggedIn == 1 {
            dismiss(animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        injectAppServicesIfNeeded()

        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        print(paths[0])
        print(paths)

        // Do any additional setup after loading the view.
        backgroundDict = ["Login": "login"]

        let view = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))

        self.view.addSubview(view)
        self.view.sendSubviewToBack(view)
        let backgroundImage: UIImage? = UIImage(named: backgroundDict["Login"]!)
        imageView = UIImageView(frame: view.frame)
        imageView.image = backgroundImage
        view.addSubview(imageView)
        hideKeyboardWhenTappedAround()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func signinTapped(_: UIButton) {
        // let deviceId = UIDevice.currentDevice().identifierForVendor!.UUIDString
        NSLog("deviceId ==> %@", deviceId)
        username = txtUsername.text! as NSString
        txtUsername.textContentType = .username

        password = txtPassword.text! as NSString
        txtPassword.textContentType = .newPassword

        let systemVersion = UIDevice.current.systemVersion

        let SHA3 = CryptoJS.SHA3()

        let hash: String = SHA3.hash(password! as String, outputLength: 512)

        if username!.isEqual(to: "") || password!.isEqual(to: "") {
            presentAlert(withTitle: "Warning", message: ErrorHandler.message(for: AppError.decodingFailed))

        } else {
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    try await AuthDataManager.shared.signIn(
                        username: self.username! as String,
                        passwordHash: hash,
                        deviceId: deviceId,
                        systemVersion: systemVersion
                    )
                    self.dismiss(animated: true, completion: nil)
                } catch let err as AppError {
                    let title: String
                    switch err {
                    case .decodingFailed:
                        title = "Error!"
                    default:
                        title = "Sign in Failed!"
                    }
                    self.presentAlert(withTitle: title, message: ErrorHandler.message(for: err))
                } catch {
                    self.presentAlert(
                        withTitle: "Sign in Failed!",
                        message: ErrorHandler.message(for: AppError.networkFailure(underlying: error))
                    )
                }
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
