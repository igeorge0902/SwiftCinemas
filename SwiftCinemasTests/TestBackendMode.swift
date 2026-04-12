import Foundation

enum TestBackendMode: String {
    case mocked
    case real

    static var current: TestBackendMode {
        let env = ProcessInfo.processInfo.environment["SWIFT_REST_BACKEND"]?.lowercased()
        return TestBackendMode(rawValue: env ?? "") ?? .mocked
    }

    var requiresRealBackend: Bool {
        self == .real
    }
}

