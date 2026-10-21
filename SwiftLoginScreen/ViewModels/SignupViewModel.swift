import Foundation

@MainActor
final class SignupViewModel {
    struct State {
        var isSubmitting = false
        var succeeded = false
    }
    struct Failure: Error {
        let title: String
        let message: String
    }
    struct Submission {
        let username: String
        let voucher: String
        let email: String
        let passwordHash: String
    }
    private let auth: AuthDataManager
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?

    init(auth: AuthDataManager) { self.auth = auth }

    func prepare(username: String, password: String, confirmPassword: String, voucher: String,
                 email: String) -> Result<Submission, Failure> {
        var missingFields = [String]()
        if username.isEmpty { missingFields.append("Username") }
        if password.isEmpty { missingFields.append("Password") }
        if email.isEmpty { missingFields.append("Email") }
        if voucher.isEmpty { missingFields.append("Voucher") }
        guard missingFields.isEmpty else {
            return .failure(Failure(title: "SignUp Failed!", message: "Please enter \(missingFields.minimalDescrption)!"))
        }
        guard password == confirmPassword else {
            return .failure(Failure(title: "SignUp Failed!", message: "Passwords do not match"))
        }
        let hash: String
        do {
            hash = try NativeCrypto.sha3Hex(password, outputLength: 512)
        } catch {
            return .failure(Failure(title: "SignUp Failed!", message: ErrorHandler.message(for: AppError.decodingFailed)))
        }
        return .success(Submission(username: username, voucher: voucher, email: email, passwordHash: hash))
    }

    func submit(_ submission: Submission, deviceId: String, systemVersion: String) async -> Failure? {
        state.isSubmitting = true
        state.succeeded = false
        onStateChange?(state)
        defer {
            state.isSubmitting = false
            onStateChange?(state)
        }
        do {
            try await auth.signUp(voucher: submission.voucher, email: submission.email,
                                  username: submission.username, passwordHash: submission.passwordHash,
                                  deviceId: deviceId, systemVersion: systemVersion)
            state.succeeded = true
            return nil
        } catch let error as AppError {
            return Failure(title: "SignUp Failed!", message: ErrorHandler.message(for: error))
        } catch {
            return Failure(title: "Connection Failure!", message: ErrorHandler.message(for: AppError.networkFailure(underlying: error)))
        }
    }
}
