import Foundation

@MainActor
final class AdminUpdateViewModel {
    struct Context {
        var movieSelected = false
        var addMovie = ""
        var addMovieId = ""
        var addVenueId = ""
        var addVenue = ""
        var addScreeningID = ""
        var addScreeningDate = ""
        var addScreeningDateId = ""
        var addCategory = ""
        var originalVenueTitle = ""
    }
    struct Form {
        var movie = ""
        var venue = ""
        var screeningId = ""
        var date = ""
        var category = ""
    }
    struct State {
        var context = Context()
        var form = Form()
        var isSubmitting = false
        var result: ScreenMutationResultModel?
        var error: Error?
    }
    struct Notice {
        let title: String
        let message: String
        var deleted = false
    }
    private let admin: AdminDataManager
    private let locations: LocationsDataManager
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?

    init(admin: AdminDataManager, locations: LocationsDataManager) {
        self.admin = admin
        self.locations = locations
    }
    func updateInput(_ edit: (inout Context) -> Void) { edit(&state.context) }
    func editForm(_ edit: (inout Form) -> Void) { edit(&state.form) }
    func leave() { admin.screeningsForAdminUpdate = [] }

    func prefill() {
        let selected = admin.selectedScreen
        let context = state.context
        state.form = Form(movie: selected?.movie ?? context.addMovie, venue: selected?.venue ?? context.addVenue,
                          screeningId: selected?.screeningId ?? context.addScreeningID,
                          date: selected?.date ?? context.addScreeningDate, category: selected?.category ?? context.addCategory)
        if let selected {
            state.context.addMovie = selected.movie
            state.context.addVenue = selected.venue
            state.context.addScreeningID = selected.screeningId
            state.context.addScreeningDate = selected.date
            state.context.addScreeningDateId = selected.screeningDatesId
            state.context.addMovieId = selected.movieId
            state.context.addVenueId = selected.venueId
            state.context.addCategory = selected.category
        }
        state.context.originalVenueTitle = selected?.venue ?? state.context.addVenue
        onStateChange?(state)
    }

    func refreshVenue() {
        state.context.addVenue = locations.selectedLocation!.title!
        let title = state.context.originalVenueTitle
        let changed = !title.isEmpty && state.context.addVenue != title
        state.form.venue = changed ? "\(state.context.addVenue) (changed)" : state.context.addVenue
        // Keep the existing venueId and displayed marker in the submitted body.
    }

    func clear() {
        state.context.addMovie = ""
        state.context.addVenue = ""
        state.context.addScreeningID = ""
        state.context.addScreeningDate = ""
        state.context.addCategory = ""
        state.context.addScreeningDateId = ""
        state.form = Form()
        onStateChange?(state)
    }

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
    func updateBody() -> [String: Any] {
        ["venue": state.form.venue, "venueId": state.context.addVenueId, "movieId": state.context.addMovieId,
         "date": state.form.date, "ScreeningDatesId": state.context.addScreeningDateId,
         "screenId": state.form.screeningId, "category": state.form.category]
    }
    func deleteBody() -> [String: Any] { ["ScreeningDatesId": state.context.addScreeningDateId as Any] }

    func update(body: [String: Any], screeningId: String) async -> Notice? {
        state.isSubmitting = true
        state.error = nil
        defer { state.isSubmitting = false }
        do {
            let result = try await admin.updateScreen(body: body)
            state.result = result
            if result.screeningId.contains("Error") {
                return Notice(title: "Error:", message: "Duplicate ScreeningId: \(screeningId)")
            }
            return Notice(title: "Info:", message: "Screen updated:, ScreeningId: \(result.screeningId)")
        } catch {
            state.error = error
            NSLog("updateScreen: %@", error.localizedDescription)
            return nil
        }
    }
    func delete(body: [String: Any]) async -> Notice? {
        state.isSubmitting = true
        state.error = nil
        defer { state.isSubmitting = false }
        do {
            if try await admin.deleteScreen(body: body) {
                return Notice(title: "Info:", message: "Screen deleted:, ScreeningDatesId: \(state.context.addScreeningDateId)", deleted: true)
            }
            return nil
        } catch {
            state.error = error
            NSLog("deleteScreen: %@", error.localizedDescription)
            return Notice(title: "Error:", message: "Duplicate ScreeningDatesId: \(state.context.addScreeningDateId)")
        }
    }
}
