import Foundation

@MainActor
final class LoginViewModel {
    struct State {
        var isSubmitting = false
        var succeeded = false
    }
    struct Failure {
        let title: String
        let message: String
    }
    private let auth: AuthDataManager
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?

    init(auth: AuthDataManager) { self.auth = auth }

    // Hashing precedes empty-input validation, as in the existing sign-in action.
    func passwordHash(username: String, password: String) -> Result<String, HashFailure> {
        let hash: String
        do {
            hash = try NativeCrypto.sha3Hex(password, outputLength: 512)
        } catch {
            return .failure(HashFailure(title: "Sign in Failed!"))
        }
        guard !username.isEmpty, !password.isEmpty else {
            return .failure(HashFailure(title: "Warning"))
        }
        return .success(hash)
    }

    struct HashFailure: Error {
        let title: String
        var message: String { ErrorHandler.message(for: AppError.decodingFailed) }
    }

    func submit(username: String, passwordHash: String, deviceId: String, systemVersion: String) async -> Failure? {
        state.isSubmitting = true
        state.succeeded = false
        onStateChange?(state)
        defer {
            state.isSubmitting = false
            onStateChange?(state)
        }
        do {
            try await auth.signIn(username: username, passwordHash: passwordHash,
                                  deviceId: deviceId, systemVersion: systemVersion)
            state.succeeded = true
            return nil
        } catch let error as AppError {
            let title: String
            switch error {
            case .decodingFailed: title = "Error!"
            default: title = "Sign in Failed!"
            }
            return Failure(title: title, message: ErrorHandler.message(for: error))
        } catch {
            return Failure(title: "Sign in Failed!", message: ErrorHandler.message(for: AppError.networkFailure(underlying: error)))
        }
    }
}
