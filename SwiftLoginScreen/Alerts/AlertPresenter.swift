// AlertPresenter.swift

import UIKit

extension UIViewController {
    func presentAlert(
        withTitle title: String,
        message: String,
        action: AlertAction = .none
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            switch action {
            case .none:
                break
            case .resendActivation:
                let user = UserDefaults.standard.value(forKey: "USERNAME")
                Task { @MainActor in
                    guard let userStr = user as? String else { return }
                    do {
                        try await AuthDataManager.shared.activateCurrentDevice(user: userStr)
                    } catch { print(error) }
                }
            case let .custom(handler):
                handler()
            }
        })
        present(alert, animated: true)
    }
}
