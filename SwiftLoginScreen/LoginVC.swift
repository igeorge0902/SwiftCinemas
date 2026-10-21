// LoginVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Security
import UIKit

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
    private lazy var viewModel = LoginViewModel(auth: .shared)

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
        username = txtUsername.text! as NSString
        txtUsername.textContentType = .username

        password = txtPassword.text! as NSString
        txtPassword.textContentType = .newPassword

        let systemVersion = UIDevice.current.systemVersion

        let hash: String
        switch viewModel.passwordHash(username: username! as String, password: password! as String) {
        case let .success(value):
            hash = value
        case let .failure(failure):
            presentAlert(withTitle: failure.title, message: failure.message)
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            let deviceId = currentDeviceId()
            NSLog("deviceId ==> %@", deviceId)
            if let failure = await viewModel.submit(
                username: self.username! as String,
                passwordHash: hash,
                deviceId: deviceId,
                systemVersion: systemVersion
            ) {
                self.presentAlert(withTitle: failure.title, message: failure.message)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
