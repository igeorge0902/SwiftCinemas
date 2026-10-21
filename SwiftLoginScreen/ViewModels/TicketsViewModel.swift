import Foundation

@MainActor
final class TicketsViewModel {
    struct State {
        var rows: [TicketDetailModel] = []
        var purchaseId: String?
        var deleteArmedTicketIndex: Int?
        var isLoading = false
        var error: Error?
    }
    private let checkout: CheckoutDataManager
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?

    init(checkout: CheckoutDataManager) { self.checkout = checkout }
    var resolvedPurchaseId: String? { state.purchaseId ?? checkout.selectedPurchaseId }
    func setPurchaseId(_ id: String?) { state.purchaseId = id }
    func armDelete(at index: Int) { state.deleteArmedTicketIndex = index }

    func load(purchaseId: String) async {
        state.isLoading = true
        state.error = nil
        do {
            state.rows = try await checkout.fetchTickets(purchaseId: purchaseId)
            state.rows.sort { $0.seatNumber < $1.seatNumber }
            state.isLoading = false
            onStateChange?(state)
        } catch {
            state.isLoading = false
            state.error = error
            NSLog("TicketsVC addData: %@", error.localizedDescription)
        }
    }

    func cancel(purchaseId: String, ticketId: Int) async throws -> Bool {
        try await checkout.cancelTickets(purchaseId: purchaseId, ticketIds: [ticketId])
    }

    func removeCancelledTicket(at index: Int) {
        state.rows.remove(at: index)
        state.deleteArmedTicketIndex = nil
    }
}
