import Foundation

@MainActor
final class ScreeningDateSelectionViewModel {
    private let dates: DatesDataManager
    init(dates: DatesDataManager) { self.dates = dates }

    var rowCount: Int { dates.availableDates.count + 1 }
    var hasDates: Bool { !dates.availableDates.isEmpty }

    func title(at row: Int) -> String {
        if row == 0 { return "Select a date" }
        let titleData = dates.availableDates[row - 1].date
        let parts = titleData.split(separator: ".")
        let date = Date.formatDate(dateString: String(parts.first!))
        return String.formatDate(date: date)
    }

    func selectDate(atPickerRow row: Int) {
        precondition(row > 0 && row < rowCount)
        let selected = dates.availableDates[row - 1]
        dates.selectedScreeningDateText = selected.date
        dates.selectedScreeningDateId = selected.screeningDateId
    }
}
