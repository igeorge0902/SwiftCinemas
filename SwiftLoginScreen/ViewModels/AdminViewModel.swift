import Foundation

@MainActor
final class AdminViewModel {
    struct Form {
        var movie: String?
        var venue: String?
        var date = ""
        var rows = ""
        var seatsInRow = ""
        var screeningId = ""
        var category = ""
    }
    struct State {
        var form = Form()
        var isSubmitting = false
        var result: ScreenMutationResultModel?
        var error: Error?
    }
    struct Notice {
        let title: String
        let message: String
    }
    private let admin: AdminDataManager
    private let movies: MoviesDataManager
    private let locations: LocationsDataManager
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?

    init(admin: AdminDataManager, movies: MoviesDataManager, locations: LocationsDataManager) {
        self.admin = admin
        self.movies = movies
        self.locations = locations
    }
    func editForm(_ edit: (inout Form) -> Void) { edit(&state.form) }
    func refreshMovie() { state.form.movie = movies.selectedMovie?.name }
    func refreshVenue() { state.form.venue = locations.selectedLocation?.title }
    func setDate(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        state.form.date = formatter.string(from: date)
    }
    func validateCategory() -> Bool {
        let valid = ["Action", "Drama", "Crime", "Romance", "Troll"]
        if !valid.contains(state.form.category), state.form.category != "" {
            state.form.category = ""
            return false
        }
        return true
    }

    // Capture the displayed strings synchronously, before the task boundary.
    func submissionBody() -> [String: Any] {
        ["venue": state.form.venue ?? "", "movie": state.form.movie ?? "", "date": state.form.date,
         "nrOfRows": state.form.rows, "nrOfSeatsInRow": state.form.seatsInRow,
         "ScreeningId": state.form.screeningId, "category": state.form.category]
    }

    func submit(body: [String: Any], screeningId: String) async -> Notice? {
        state.isSubmitting = true
        state.error = nil
        defer { state.isSubmitting = false }
        do {
            let result = try await admin.addScreen(body: body)
            state.result = result
            if result.screeningId.contains("Error") {
                return Notice(title: "Error:", message: "Duplicate ScreeningId: \(screeningId)")
            }
            return Notice(title: "Info:", message: "New screen added:, Screen: \(result.movie)")
        } catch {
            state.error = error
            NSLog("addNewScreen: %@", error.localizedDescription)
            return nil
        }
    }
}
