import SafariServices
import SwiftyJSON
import UIKit

class MenuVC: UIViewController, HasAppServices {
    var appServices: AppServices!
    // MARK: - UI Elements

    private lazy var profileCard = createProfileCard()
    private lazy var usernameTitleLabel = createFieldTitleLabel(text: "Username")
    private lazy var usernameValueLabel = createFieldValueLabel()
    private lazy var emailTitleLabel = createFieldTitleLabel(text: "Email")
    private lazy var emailValueLabel = createFieldValueLabel()
    private lazy var imageView = createImageView()
    private lazy var adminButton = createButton(title: "Admin", action: #selector(admin))

    lazy var session: URLSession = .sharedCustomSession
    private let url = URL(string: URLManager.login("/logout"))
    private var sessionCookieValue = ""

    private var items = [JSON]()

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        injectAppServicesIfNeeded()
        setupUI()
        loadCookies()
        getUser()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.95, alpha: 1)

        addTopNavigationButtons([
            (title: "Back", action: #selector(navigateBack)),
            (title: "Purchases", action: #selector(navigateToPurchases)),
        ])

        imageView.image = UIImage(named: "placeholder")
        [profileCard, adminButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        [imageView, usernameTitleLabel, usernameValueLabel, emailTitleLabel, emailValueLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            profileCard.addSubview($0)
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
        ])
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

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_mypurchases" {
            _ = segue.destination as? PurchasesVC
        }
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

    // MARK: - Networking

    func getUser() {
        Task { [weak self] in
            guard let self else { return }

            do {
                let profile = try await AuthDataManager.shared.fetchUserProfile()

                self.usernameValueLabel.text = profile.username.isEmpty
                    ? "No logged-in user"
                    : profile.username

                self.emailValueLabel.text = profile.email.isEmpty
                    ? "No email"
                    : profile.email

                let urlString = URLManager.image(profile.profilePicture)

                let imagedata = try await self.appServices.images.getData(
                    urlString: urlString,
                    realmCache: true
                )

                self.imageView.image = UIImage(data: imagedata)

                } catch let err as AppError {
                    let title: String
                    switch err {
                    case .activationRequired(voucherActive: false):
                        title = "Warning!"
                        self.presentAlertWithFunction(withTitle: title, message: ErrorHandler.message(for: err), function: "sendEmail")

                    default:
                        title = "No valid session!"
                    }
                    self.presentAlert(withTitle: title, message: ErrorHandler.message(for: err))
                    
                } catch {
                    self.presentAlert(
                        withTitle: "Error!",
                        message: ErrorHandler.message(for: AppError.networkFailure(underlying: error))
                    )
                }
        }
    }

    @IBAction private func logoutTapped(_: UIButton) {
        performLogout { success in
            DispatchQueue.main.async {
                if success {
                    self.presentAlert(withTitle: "Logout Successful", message: "Bye!")
                    self.clearCookies()
                } else {
                    self.presentAlert(withTitle: "Logout Failed", message: "Please try again.")
                }
            }
        }
    }

    private func performLogout(completion: @escaping (Bool) -> Void) {
        guard let requestUrl = url else { return }

        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = session.dataTask(with: request) { _, response, error in
            guard error == nil, let httpResponse = response as? HTTPURLResponse else {
                completion(false)
                return
            }

            if httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }
        task.resume()
    }

    private func clearCookies() {
        let cookieStorage = HTTPCookieStorage.shared
        cookieStorage.cookies?.forEach { cookieStorage.deleteCookie($0) }

        usernameValueLabel.text = "No logged-in user"
        emailValueLabel.text = "No email"
        sessionCookieValue = ""

        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        SecureStore.remove("X-Token")
        SecureStore.remove("JSESSIONID")
    }
}
