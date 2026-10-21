import Foundation

@MainActor
final class SeatSelectionViewModel {
    private let seats: SeatsDataManager
    private let basket: BasketDataManager
    private let dates: DatesDataManager
    private let movies: MoviesDataManager
    private let venues: VenuesDataManager

    init(seats: SeatsDataManager, basket: BasketDataManager, dates: DatesDataManager,
         movies: MoviesDataManager, venues: VenuesDataManager) {
        self.seats = seats
        self.basket = basket
        self.dates = dates
        self.movies = movies
        self.venues = venues
    }

    var rowKeys: [String] { seats.getRows(seats.allSeats) }
    var isBasketEmpty: Bool { basket.basketItemsBySeatId.isEmpty }
    var selectedSeatsById: [Int: String] {
        basket.basketItemsBySeatId.reduce(into: [Int: String]()) { result, element in
            result[element.key] = element.value.seatNumber
        }
    }
    var displayDate: String {
        let text = dates.selectedScreeningDateText ?? ""
        let normalized = text.split(separator: ".").first.map(String.init) ?? text
        let date = normalized.isEmpty ? Date() : Date.formatDate(dateString: normalized)
        return String.formatDate(date: date)
    }

    func seats(forRowTag tag: Int) -> [SeatModel] {
        guard tag >= 0, tag < rowKeys.count else { return [] }
        let row = rowKeys[tag]
        return seats.allSeats.filter { $0.seatRow == row }
    }

    func clear() -> Bool {
        guard let id = dates.selectedScreeningDateId else { return false }
        basket.seatsToReservePayloadByScreening.removeValue(forKey: id)
        for seat in seats.allSeats { basket.basketItemsBySeatId.removeValue(forKey: seat.seatId) }
        resetSeatSelection()
        return true
    }

    func resetSeatSelection() {
        seats.selectedSeatIds = []
        seats.selectedSeatNumbers = []
    }

    // nil preserves the original early-return path when required booking context is absent.
    func toggle(_ selectedSeat: SeatModel) -> Bool? {
        let seatId = selectedSeat.seatId
        let seatNumber = selectedSeat.seatNumber
        if !selectedSeatsById.keys.contains(seatId), !selectedSeat.isReserved {
            guard let id = dates.selectedScreeningDateId,
                  let movieName = movies.selectedMovie?.name,
                  let picture = movies.selectedMovie?.largePicture,
                  let venueName = venues.selectedVenue?.name,
                  let dateString = dates.selectedScreeningDateText?.split(separator: ".").first else { return nil }
            let date = Date.formatDate(dateString: String(dateString))
            basket.basketItemsBySeatId[seatId] = BasketItem(
                movieName: movieName, seatId: seatId, seatRow: selectedSeat.seatRow,
                seatNumber: seatNumber, price: selectedSeat.price, tax: selectedSeat.tax,
                screeningDateId: id, moviePicture: URLManager.image(picture), venuePicture: "",
                venueName: venueName, screeningDateText: String.formatDate(date: date))
            synchronizeSelection()
            updateSeatPayload(for: id)
            NSLog("SeatId is: \(seatNumber)")
            return true
        } else {
            deselect(seatId: seatId)
            NSLog("SeatId is: \(seatNumber) is already added!")
            return false
        }
    }

    func deselect(seatId: Int) {
        basket.basketItemsBySeatId.removeValue(forKey: seatId)
        synchronizeSelection()
        if let id = dates.selectedScreeningDateId { updateSeatPayload(for: id) }
    }

    private func synchronizeSelection() {
        seats.selectedSeatIds = selectedSeatsById.keys.sorted()
        seats.selectedSeatNumbers = selectedSeatsById.values.sorted()
    }

    private func updateSeatPayload(for id: String) {
        let concatenated = selectedSeatsById.values.sorted().map { "\($0)-" }.joined()
        if concatenated.isEmpty {
            basket.seatsToReservePayloadByScreening.removeValue(forKey: id)
        } else {
            basket.seatsToReservePayloadByScreening[id] = concatenated
        }
    }
}
