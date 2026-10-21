import Foundation

@MainActor
final class BasketViewModel {
    struct State {
        enum Phase { case idle, loading, loaded, failed }
        var phase: Phase = .idle
        var isCheckoutInProgress = false
        var clientToken: String?
        var result: CheckoutResultModel?
        var error: Error?
        var title = ""
        var message = ""
        var submission = 0
    }

    private let basket: BasketDataManager
    private let checkout: CheckoutDataManager
    private let seats: SeatsDataManager
    private let dates: DatesDataManager
    private var handledSubmission = 0
    private var finalizedSubmission = 0
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?

    init(basket: BasketDataManager, checkout: CheckoutDataManager, seats: SeatsDataManager, dates: DatesDataManager) {
        self.basket = basket
        self.checkout = checkout
        self.seats = seats
        self.dates = dates
    }

    // Read the shared basket live: constructing/rendering a VM never restores an old snapshot.
    var values: [BasketItem] {
        basket.basketItemsBySeatId.values.sorted { $0.movieName < $1.movieName }
    }

    func remove(at index: Int) {
        let item = values[index]
        if let current = basket.seatsToReservePayloadByScreening[item.screeningDateId] {
            let updated = current.replacingOccurrences(of: item.seatNumber + "-", with: "")
            if updated.isEmpty {
                basket.seatsToReservePayloadByScreening.removeValue(forKey: item.screeningDateId)
            } else {
                basket.seatsToReservePayloadByScreening[item.screeningDateId] = updated
            }
        }
        basket.basketItemsBySeatId.removeValue(forKey: item.seatId)
        seats.selectedSeatIds.removeAll { $0 == item.seatId }
        seats.selectedSeatNumbers.removeAll { $0 == item.seatNumber }
    }

    func beginCheckout() { state.isCheckoutInProgress = true }
    func cancelCheckout() { state.isCheckoutInProgress = false }

    func loadClientToken() async throws -> ClientTokenModel {
        do {
            let token = try await checkout.fetchClientToken()
            state.clientToken = token.clientToken
            return token
        } catch {
            state.isCheckoutInProgress = false
            throw error
        }
    }

    func submit(nonce: String) async throws -> CheckoutResultModel {
        state.submission += 1
        state.phase = .loading
        state.isCheckoutInProgress = true
        state.result = nil
        state.error = nil
        state.title = ""
        state.message = ""
        onStateChange?(state)
        do {
            let orderId = String(zeroTime(0).getCurrentMillis())
            let payload = try basket.makeSeatsToBeReservedPayload()
            let result = try await checkout.checkout(paymentMethodNonce: nonce, orderId: orderId, seatsToBeReserved: payload)
            seats.allSeats = result.reservedSeats
            state.result = result
            if result.isSuccess {
                state.phase = .loaded
                state.title = "Payment info:"
                let summary = result.tickets.map(\.seatNumber).minimalDescrption
                state.message = "ResponseText: \(result.responseText ?? "success"), Status: \(result.status ?? "success"), Amount: \(result.amount ?? ""), TaxAmount: \(result.taxAmount ?? ""), Seats: \(summary)"
            } else {
                state.phase = .failed
                state.title = "Booking failed with payment info:"
                if let failed = result.failedTickets.first {
                    state.message = "Failed tickets for movie: \(failed.movieName), seats_seatNumber: \(failed.seatNumber), ResponseText: \(result.errorMessage ?? "Payment failed")"
                } else {
                    state.message = "Payment error: \(result.errorMessage ?? "Unknown error")"
                }
            }
            // Synchronous observation starts the alert before success finalization.
            onStateChange?(state)
            return result
        } catch {
            NSLog("postNonceToServer: %@", error.localizedDescription)
            state.phase = .failed
            state.error = error
            state.title = "Payment error"
            state.message = error.localizedDescription
            onStateChange?(state)
            throw error
        }
    }

    func consumeTerminalSubmission() -> Bool {
        switch state.phase {
        case .loaded, .failed:
            guard handledSubmission != state.submission else { return false }
            handledSubmission = state.submission
            return true
        case .idle, .loading: return false
        }
    }

    func finalizeSuccessfulSubmission() {
        guard case .loaded = state.phase, state.result?.isSuccess == true,
              finalizedSubmission != state.submission else { return }
        finalizedSubmission = state.submission
        basket.resetNavigationContext()
        seats.resetNavigationContext()
        dates.resetNavigationContext()
        // No publication here: recursively publishing a terminal outcome would replay the alert.
    }

    func finishOutcomeHandling() { state.isCheckoutInProgress = false }
}
