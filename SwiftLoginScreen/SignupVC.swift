// SignupVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import UIKit

class SignupVC: UIViewController, HasAppServices {
    var appServices: AppServices!
    private lazy var viewModel = SignupViewModel(auth: .shared)
    // MARK: Lifecycle

    deinit {
        print(#function, "\(self)")
    }

    // MARK: Internal

    var imageView: UIImageView = .init()
    var backgroundDict: [String: String] = Dictionary()

    @IBOutlet var txtVoucher: UITextField!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var txtUsername: UITextField!
    @IBOutlet var txtPassword: UITextField!
    @IBOutlet var txtConfirmPassword: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        injectAppServicesIfNeeded()

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
        NSLog("deviceId ==> %@", currentDeviceId())

        let username = txtUsername.text ?? ""
        let password = txtPassword.text ?? ""
        let confirmPassword = txtConfirmPassword.text ?? ""
        let voucher = txtVoucher.text ?? ""
        let email = txtEmail.text ?? ""
        let systemVersion = UIDevice.current.systemVersion
        let submission: SignupViewModel.Submission
        switch viewModel.prepare(username: username, password: password, confirmPassword: confirmPassword,
                                voucher: voucher, email: email) {
        case let .success(value):
            submission = value
        case let .failure(failure):
            presentAlert(withTitle: failure.title, message: failure.message)
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            if let failure = await viewModel.submit(submission, deviceId: currentDeviceId(), systemVersion: systemVersion) {
                self.presentAlert(withTitle: failure.title, message: failure.message)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
