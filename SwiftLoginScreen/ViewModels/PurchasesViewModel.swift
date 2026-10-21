import Foundation

@MainActor
final class PurchasesViewModel {
    struct State {
        var rows: [PurchaseSummaryModel] = []
        var sortBy = "purchase"
        var refundArmedSection: Int?
        var refundedEntries: [String] = []
        var isLoading = false
        var error: Error?
    }
    private let checkout: CheckoutDataManager
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?

    init(checkout: CheckoutDataManager) { self.checkout = checkout }
    func clearRows() { state.rows.removeAll() }
    func setSort(_ sort: String) { state.sortBy = sort }
    func armRefund(section: Int) { state.refundArmedSection = section }
    func selectPurchase(at section: Int) { checkout.selectedPurchaseId = state.rows[section].purchaseId }

    func applySorting() {
        switch state.sortBy {
        case "screening": state.rows.sort { $0.screeningDate > $1.screeningDate }
        default: state.rows.sort { $0.purchaseDate > $1.purchaseDate }
        }
    }

    func load() async throws {
        state.isLoading = true
        state.error = nil
        do {
            // Do not automatically re-sort a refresh: the original load did not do that.
            state.rows = try await checkout.fetchAllPurchases()
            state.isLoading = false
            onStateChange?(state)
        } catch {
            state.isLoading = false
            state.error = error
            throw error
        }
    }

    func refund(at section: Int) async throws -> Bool {
        let purchase = state.rows[section]
        if try await checkout.refundPurchase(purchaseId: purchase.purchaseId) {
            state.rows.remove(at: section)
            state.refundedEntries.insert("#\(purchase.purchaseId) \(purchase.movieName)", at: 0)
            state.refundArmedSection = nil
            return true
        }
        return false
    }
}
