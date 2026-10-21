import Foundation

@MainActor
final class MenuViewModel {
    struct State {
        var username: String?
        var email: String?
        var avatarData: Data?
        var hasAvatarResult = false
        var confirmedNewsScreen: Bool?
        var isNewsScreenEnabled = false
        var newsStatus = "Loading…"
        var animateNewsChanges = false
    }

    private let auth: AuthDataManager
    private let gateway: LoginGatewayService
    private let images: ImageResourceService
    private var newsScreenTask: Task<Void, Never>?
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?
    var onError: ((Error, String) -> Void)?

    init(auth: AuthDataManager, gateway: LoginGatewayService, images: ImageResourceService) {
        self.auth = auth
        self.gateway = gateway
        self.images = images
    }

    deinit { newsScreenTask?.cancel() }

    var hasNewsRequest: Bool { newsScreenTask != nil }

    func loadProfile() async {
        do {
            let profile = try await auth.fetchUserProfile()
            state.username = profile.username.isEmpty ? "No logged-in user" : profile.username
            state.email = profile.email.isEmpty ? "No email" : profile.email
            onStateChange?(state)
            state.avatarData = try await images.getData(urlString: profile.profilePicture, realmCache: true)
            state.hasAvatarResult = true
            onStateChange?(state)
        } catch let error as AppError {
            onError?(error, "No valid session!")
        } catch {
            onError?(error, "Error!")
        }
    }

    func requestNewsScreen(enabled: Bool?) {
        guard newsScreenTask == nil else { return }
        let gateway = gateway
        let previousConfirmed = state.confirmedNewsScreen
        state.isNewsScreenEnabled = false
        state.animateNewsChanges = false
        state.newsStatus = enabled == nil ? "Loading…" : "Saving…"
        onStateChange?(state)
        // Capture the service, not the screen/VM, across suspension.
        newsScreenTask = Task { @MainActor [weak self] in
            guard !Task.isCancelled else { return }
            do {
                let settings: ScreenNews
                if let enabled {
                    settings = try await gateway.putNewsScreen(enabled: enabled)
                } else {
                    settings = try await gateway.getNewsScreen()
                }
                guard !Task.isCancelled, let self else { return }
                newsScreenTask = nil
                state.confirmedNewsScreen = settings.enabled
                state.animateNewsChanges = true
                state.isNewsScreenEnabled = true
                state.newsStatus = settings.enabled ? "Enabled" : "Disabled"
                onStateChange?(state)
            } catch {
                guard !Task.isCancelled, let self else { return }
                newsScreenTask = nil
                state.confirmedNewsScreen = previousConfirmed
                state.animateNewsChanges = true
                state.isNewsScreenEnabled = enabled != nil && previousConfirmed != nil
                state.newsStatus = enabled == nil ? "Unavailable" : "Not saved"
                onStateChange?(state)
                onError?(error, "Error!")
            }
        }
    }

    func disappear() {
        newsScreenTask?.cancel()
        newsScreenTask = nil
        state.isNewsScreenEnabled = false
        state.animateNewsChanges = false
        onStateChange?(state)
    }

    func logout() async throws { _ = try await auth.logOut() }

    func clearNewsScreen() {
        newsScreenTask?.cancel()
        newsScreenTask = nil
        state.confirmedNewsScreen = nil
        state.isNewsScreenEnabled = false
        state.newsStatus = "Unavailable"
        state.animateNewsChanges = false
        onStateChange?(state)
    }

    func clearProfile() {
        state.username = "No logged-in user"
        state.email = "No email"
        state.avatarData = nil
        state.hasAvatarResult = true
        onStateChange?(state)
    }
}
