//
//  SignupVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 27/03/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import UIKit

class SignupVC: UIViewController {
    var imageView: UIImageView = .init()
    var backgroundDict: [String: String] = Dictionary()

    deinit {
        print(#function, "\(self)")
    }

    @IBOutlet var txtVoucher: UITextField!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var txtUsername: UITextField!
    @IBOutlet var txtPassword: UITextField!
    @IBOutlet var txtConfirmPassword: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundDict = ["Signup": "signup"]

        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        view.addSubview(contentView)
        view.sendSubviewToBack(contentView)

        let backgroundImage: UIImage? = UIImage(named: backgroundDict["Signup"]!)
        imageView = UIImageView(frame: contentView.frame)
        imageView.image = backgroundImage
        contentView.addSubview(imageView)

        hideKeyboardWhenTappedAround()
    }

    @IBAction func gotoLogin(_: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func signupTapped(_: UIButton) {
        NSLog("deviceId ==> %@", deviceId)

        let username = txtUsername.text ?? ""
        let password = txtPassword.text ?? ""
        let confirmPassword = txtConfirmPassword.text ?? ""
        let voucher = txtVoucher.text ?? ""
        let email = txtEmail.text ?? ""
        let systemVersion = UIDevice.current.systemVersion

        var missingFields = [String]()
        if username.isEmpty { missingFields.append("Username") }
        if password.isEmpty { missingFields.append("Password") }
        if email.isEmpty { missingFields.append("Email") }
        if voucher.isEmpty { missingFields.append("Voucher") }

        guard missingFields.isEmpty else {
            presentAlert(withTitle: "SignUp Failed!", message: "Please enter \(missingFields.minimalDescrption)!")
            return
        }

        guard password == confirmPassword else {
            presentAlert(withTitle: "SignUp Failed!", message: "Passwords do not match")
            return
        }

        let sha3 = CryptoJS.SHA3()
        let hash = sha3.hash(password, outputLength: 512)

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await AuthDataManager.shared.signUp(
                    voucher: voucher,
                    email: email,
                    username: username,
                    passwordHash: hash,
                    deviceId: deviceId,
                    systemVersion: systemVersion
                )
                self.dismiss(animated: true, completion: nil)
            } catch let err as AppError {
                self.presentAlert(withTitle: "SignUp Failed!", message: ErrorHandler.message(for: err))
            } catch {
                self.presentAlert(
                    withTitle: "Connection Failure!",
                    message: ErrorHandler.message(for: AppError.networkFailure(underlying: error))
                )
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
