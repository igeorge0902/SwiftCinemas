// MenuVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import SafariServices
import SwiftyJSON
import UIKit

class MenuVC: UIViewController, HasAppServices {
    // MARK: Internal

    var appServices: AppServices!
    private lazy var viewModel = MenuViewModel(auth: .shared, gateway: appServices.loginGateway, images: appServices.images)

    lazy var session: URLSession = .sharedCustomSession

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        injectAppServicesIfNeeded()
        setupUI()
        bindViewModel()
        loadCookies()
        getUser()
        loadNewsScreen()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh after returning from another screen, including a cancelled save.
        if !viewModel.hasNewsRequest {
            loadNewsScreen()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.disappear()
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_mypurchases" {
            _ = segue.destination as? PurchasesVC
        }
    }

    // MARK: - Networking

    func getUser() {
        Task { [weak self] in
            guard let self else { return }

            await viewModel.loadProfile()
        }
    }

    // MARK: Private

    // MARK: - UI Elements

    private lazy var profileCard = createProfileCard()
    private lazy var usernameTitleLabel = createFieldTitleLabel(text: "Username")
    private lazy var usernameValueLabel = createFieldValueLabel()
    private lazy var emailTitleLabel = createFieldTitleLabel(text: "Email")
    private lazy var emailValueLabel = createFieldValueLabel()
    private lazy var imageView = createImageView()
    private lazy var adminButton = createButton(title: "Admin", action: #selector(admin))
    private let screenNewsSwitch = UISwitch()
    private let screenNewsStatusLabel = UILabel()
    private lazy var screenNewsRow = createScreenNewsRow()

    private let url = URL(string: URLManager.login("/logout"))
    private var sessionCookieValue = ""

    private var items = [JSON]()

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.95, alpha: 1)

        addTopNavigationButtons([
            (title: "Back", action: #selector(navigateBack)),
            (title: "Purchases", action: #selector(navigateToPurchases)),
        ])

        imageView.image = UIImage(named: "placeholder")
        for item in [profileCard, adminButton, screenNewsRow] {
            item.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(item)
        }

        for item in [imageView, usernameTitleLabel, usernameValueLabel, emailTitleLabel, emailValueLabel] {
            item.translatesAutoresizingMaskIntoConstraints = false
            profileCard.addSubview(item)
        }

        NSLayoutConstraint.activate([
            profileCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            profileCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            profileCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            imageView.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: profileCard.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 120),
            imageView.heightAnchor.constraint(equalToConstant: 120),

            usernameTitleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 18),
            usernameTitleLabel.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 16),
            usernameTitleLabel.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -16),

            usernameValueLabel.topAnchor.constraint(equalTo: usernameTitleLabel.bottomAnchor, constant: 4),
            usernameValueLabel.leadingAnchor.constraint(equalTo: usernameTitleLabel.leadingAnchor),
            usernameValueLabel.trailingAnchor.constraint(equalTo: usernameTitleLabel.trailingAnchor),

            emailTitleLabel.topAnchor.constraint(equalTo: usernameValueLabel.bottomAnchor, constant: 14),
            emailTitleLabel.leadingAnchor.constraint(equalTo: usernameTitleLabel.leadingAnchor),
            emailTitleLabel.trailingAnchor.constraint(equalTo: usernameTitleLabel.trailingAnchor),

            emailValueLabel.topAnchor.constraint(equalTo: emailTitleLabel.bottomAnchor, constant: 4),
            emailValueLabel.leadingAnchor.constraint(equalTo: usernameTitleLabel.leadingAnchor),
            emailValueLabel.trailingAnchor.constraint(equalTo: usernameTitleLabel.trailingAnchor),
            emailValueLabel.bottomAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: -20),

            adminButton.topAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: 18),
            adminButton.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor),
            adminButton.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor),
            adminButton.heightAnchor.constraint(equalToConstant: 42),

            screenNewsRow.topAnchor.constraint(equalTo: adminButton.bottomAnchor, constant: 18),
            screenNewsRow.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor),
            screenNewsRow.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor),
        ])
    }

    private func createScreenNewsRow() -> UIStackView {
        let title = createFieldTitleLabel(text: "Screen news")
        screenNewsStatusLabel.font = .systemFont(ofSize: 11)
        screenNewsStatusLabel.textColor = .darkGray
        screenNewsStatusLabel.numberOfLines = 0
        screenNewsStatusLabel.text = "Loading…"

        let labels = UIStackView(arrangedSubviews: [title, screenNewsStatusLabel])
        labels.axis = .vertical
        labels.spacing = 4

        screenNewsSwitch.isEnabled = false
        screenNewsSwitch.accessibilityLabel = "Screen news"
        screenNewsSwitch.addTarget(self, action: #selector(screenNewsChanged(_:)), for: .valueChanged)

        let row = UIStackView(arrangedSubviews: [labels, screenNewsSwitch])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        return row
    }

    // MARK: - Screen-news Subscription

    private func loadNewsScreen() {
        viewModel.requestNewsScreen(enabled: nil)
    }

    @objc private func screenNewsChanged(_ sender: UISwitch) {
        guard let confirmed = viewModel.state.confirmedNewsScreen, !viewModel.hasNewsRequest else { return }
        let wanted = sender.isOn
        // Keep displaying the last confirmed value until the server acknowledges the change.
        sender.setOn(confirmed, animated: true)
        viewModel.requestNewsScreen(enabled: wanted)
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in self?.render(state, animated: true) }
        viewModel.onError = { [weak self] error, title in self?.presentMenuError(error, title: title) }
        render(viewModel.state, animated: false)
    }

    private func render(_ state: MenuViewModel.State, animated: Bool) {
        if let username = state.username { usernameValueLabel.text = username }
        if let email = state.email { emailValueLabel.text = email }
        if state.hasAvatarResult { imageView.image = state.avatarData.flatMap { UIImage(data: $0) } }
        screenNewsSwitch.setOn(state.confirmedNewsScreen ?? false, animated: animated && state.animateNewsChanges)
        screenNewsSwitch.isEnabled = state.isNewsScreenEnabled
        screenNewsStatusLabel.text = state.newsStatus
    }

    private func presentMenuError(_ error: Error, title: String = "Error!") {
        let appError = (error as? AppError) ?? .networkFailure(underlying: error)
        var message = ErrorHandler.message(for: appError)

        // Profile and settings requests may fail together. Do not attempt overlapping alerts.
        if let alert = presentedViewController as? UIAlertController {
            if let existing = alert.message, !existing.isEmpty, existing != message {
                message = existing + "\n" + message
            }
            switch appError {
            case .activationRequired(voucherActive: false) where alert.title != "Warning!":
                // Upgrade a plain error alert to the existing activation-action alert.
                let combinedMessage = message
                alert.dismiss(animated: false) { [weak self] in
                    self?.presentAlert(
                        withTitle: "Warning!",
                        message: combinedMessage,
                        action: .resendActivation
                    )
                }
            default:
                alert.message = message
            }
            return
        }

        switch appError {
        case .activationRequired(voucherActive: false):
            presentAlert(
                withTitle: "Warning!",
                message: message,
                action: .resendActivation
            )
        default:
            presentAlert(withTitle: title, message: message)
        }
    }

    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        stylePrimaryButton(button, fontSize: 15)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func stylePrimaryButton(_ button: UIButton, fontSize: CGFloat) {
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: fontSize, weight: .semibold)
        button.layer.cornerRadius = 14
    }

    private func createProfileCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(white: 0.86, alpha: 1).cgColor
        return card
    }

    private func createFieldTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .darkGray
        return label
    }

    private func createFieldValueLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont(name: "Courier New", size: 13) ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }

    private func createImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = UIColor(white: 0.96, alpha: 1)
        return imageView
    }

    // MARK: - Navigation

    @objc private func navigateBack() {
        dismiss(animated: true)
    }

    @objc private func navigateToPurchases() {
        performSegue(withIdentifier: "goto_mypurchases", sender: self)
    }

    @objc private func admin() {
        performSegue(withIdentifier: "goto_admin", sender: self)
    }

    // MARK: - Cookie Handling

    private func loadCookies() {
        let cookieStorage = HTTPCookieStorage.shared
        let cookies = cookieStorage.cookies ?? []

        // Keep session cookie fetched for existing logout/session workflows, but not shown as a primary profile field.
        sessionCookieValue = cookies.first(where: { $0.name == "JSESSIONID" })?.value ?? ""
    }

    @IBAction private func logoutTapped(_: UIButton) {
        performLogout()
    }

    private func performLogout() -> Void {

        Task { @MainActor [weak self] in
            guard let self else { return }
            let deviceId = currentDeviceId()
            NSLog("deviceId ==> %@", deviceId)
            do {
                try await viewModel.logout()
                self.presentAlert(withTitle: "Logout Successful", message: "Bye!")
                self.clearCookies()
               // self.dismiss(animated: true, completion: nil)
            } catch let err as AppError {
                self.presentAlert(withTitle: "Error!", message: ErrorHandler.message(for: AppError.networkFailure(underlying: err))
                )
            }
        }
    }

    private func clearCookies() {
        viewModel.clearNewsScreen()

        let cookieStorage = HTTPCookieStorage.shared
        cookieStorage.cookies?.forEach { cookieStorage.deleteCookie($0) }

        viewModel.clearProfile()
        sessionCookieValue = ""

        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        SecureStore.remove("X-Token")
        SecureStore.remove("JSESSIONID")
    }
}
