import SafariServices
import SwiftyJSON
import UIKit

@available(iOS 15.0, *)
class MenuVC: UIViewController {
    // MARK: - UI Elements

    private lazy var nameTextView = createTextView()
    private lazy var sessionCookieTextView = createTextView()
    private lazy var xsrfCookieTextView = createTextView()
    private lazy var imageView = createImageView()

    lazy var session: URLSession = .sharedCustomSession
    private let url = URL(string: serverURL + "/login/logout")

    private var items = [JSON]()

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCookies()
        addData()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white

        let buttonTitles = ["Purchases", "Back"]
        let buttonActions: [Selector] = [#selector(navigateToPurchases), #selector(navigateBack)]

        for (index, title) in buttonTitles.enumerated() {
            let button = createButton(title: title, action: buttonActions[index])
            button.frame.origin.x = index == 0 ? view.frame.width / 2 : 0
            view.addSubview(button)
        }

        let textViews = [nameTextView, sessionCookieTextView, xsrfCookieTextView]
        for (index, textView) in textViews.enumerated() {
            textView.frame.origin.y = CGFloat(80 + (index * 60))
            view.addSubview(textView)
        }

        imageView.image = UIImage(named: "placeholder")
        view.addSubview(imageView)

        let adminButton = createButton(title: "Admin", action: #selector(admin))
        adminButton.frame.origin = CGPoint(x: view.frame.width * 0.15, y: (view.frame.height / 2) - 150)
        adminButton.center.x = view.center.x
        view.addSubview(adminButton)
    }

    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 40)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func createTextView() -> UITextView {
        let textView = UITextView(frame: CGRect(x: view.frame.width * 0.1, y: 100, width: view.frame.width * 0.8, height: 50))
        textView.isEditable = false
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.darkGray.cgColor
        textView.font = UIFont(name: "Courier New", size: 13.0)
        return textView
    }

    private func createImageView() -> UIImageView {
        let imageView = UIImageView(frame: CGRect(x: view.frame.width * 0.1, y: view.frame.height / 2.5, width: view.frame.width * 0.8, height: view.frame.height / 3))
        imageView.contentMode = .scaleAspectFit
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

        sessionCookieTextView.text = cookies.first(where: { $0.name == "JSESSIONID" })?.value ?? "JSESSION cookie"
        //  xsrfCookieTextView.text = cookies.first(where: { $0.name == "XSRF-TOKEN" })?.value ?? "xsrf-cookie"
    }

    // MARK: - Networking

    private func addData() {
        RestApiManager.sharedInstance.getRandomUser { [weak self] json, _ in
            guard let self else { return }

            if let errorMsg = json["Error Details"]["Error Message:"].string {
                presentAlert(withTitle: "Error Details", message: errorMsg)
            } else {
                let user = json["user"].stringValue
                let email = json["email"].stringValue
                let profilePicture = json["profilePicture"].stringValue
                DispatchQueue.main.async {
                    self.nameTextView.text = user.isEmpty ? "No logged-in user" : user
                    self.xsrfCookieTextView.text = email.isEmpty ? "No email" : email

                    let urlString = serverURL + "/simple-service-webapp/webapi" + profilePicture

                    var loadPictures: GeneralRequestManager?
                    loadPictures = GeneralRequestManager(url: urlString, errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: "1", contentType: "", bodyToPost: nil)

                    loadPictures?.getData_ {
                        (data: Data, _: NSError?) in
                        self.imageView.image = UIImage(data: data)
                        self.imageView.setNeedsDisplay()
                    }
                }
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

        nameTextView.text = "No logged-in user"
        sessionCookieTextView.text = "JSESSION cookie"
        xsrfCookieTextView.text = "xsrf-cookie"

        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
}
