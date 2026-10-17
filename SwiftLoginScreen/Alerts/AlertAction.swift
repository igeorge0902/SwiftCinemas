// AlertAction.swift

enum AlertAction {
    case none
    case resendActivation
    case custom(() -> Void)
}
