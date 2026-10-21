import Foundation

@MainActor
final class VenuesViewModel {
    struct State {
        var rows: [VenueModel] = []
        var selectedVenueIndex: Int?
        var adminSelectedVenueTitle: String?
        var expandedAdminVenueIds = Set<Int>()
        var openedFromMapFlow = false
        var isLoading = false
        var error: Error?
    }
    private let venues: VenuesDataManager
    private let locations: LocationsDataManager
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?

    init(venues: VenuesDataManager, locations: LocationsDataManager) {
        self.venues = venues
        self.locations = locations
    }

    var isVenuesFromMapFlow: Bool { locations.isVenuesFromMapFlow }
    var isMapFlow: Bool { state.openedFromMapFlow || locations.isVenuesFromMapFlow }
    func setOpenedFromMapFlow(_ value: Bool) { state.openedFromMapFlow = value }
    var locationRows: [Location] { locations.locationsToDisplay }
    var mapFlowRows: [Location] {
        locations.locationsForMapPicker.isEmpty ? locations.locationsToDisplay : locations.locationsForMapPicker
    }

    func load(movieId: Int) async {
        state.isLoading = true
        state.error = nil
        do {
            state.rows = try await venues.fetchVenuesForMovie(movieId: String(movieId))
            state.isLoading = false
            onStateChange?(state)
        } catch {
            state.isLoading = false
            state.error = error
            NSLog("VenuesVC.addData: %@", error.localizedDescription)
        }
    }

    func loadLocations() async {
        state.isLoading = true
        state.error = nil
        do {
            let fetched = try await locations.fetchLocations()
            locations.locationsToDisplay = fetched
            if isMapFlow { locations.locationsForMapPicker = fetched }
            state.isLoading = false
            onStateChange?(state)
        } catch {
            state.isLoading = false
            state.error = error
            if isMapFlow, !locations.locationsToDisplay.isEmpty {
                locations.locationsForMapPicker = locations.locationsToDisplay
                onStateChange?(state)
                return
            }
            NSLog("VenuesVC.addLocation: %@", error.localizedDescription)
        }
    }

    func leave(isMapFlow: Bool) {
        if !isMapFlow {
            locations.locationsForMapPicker.removeAll()
            locations.locationsToDisplay.removeAll()
        }
    }
    func resetSelection() { state.selectedVenueIndex = nil }

    func selectVenue(at row: Int) {
        venues.selectedVenue = state.rows[row]
        state.selectedVenueIndex = row
    }

    func commitVenue(at row: Int) { venues.selectedVenue = state.rows[row] }

    func selectAdminLocation(at row: Int) {
        let location = locationRows[row]
        state.adminSelectedVenueTitle = location.title
        locations.applySelection(location, notificationName: "newScreenVenueSelected")
    }

    func selectMapLocation(_ location: Location) {
        locations.applySelection(location, notificationName: "screeningVenueSelected")
    }

    func sortLocationRows() {
        locations.locationsToDisplay.sort { ($0.title ?? "") < ($1.title ?? "") }
        locations.locationsForMapPicker.sort { ($0.title ?? "") < ($1.title ?? "") }
    }

    func toggleExpandedLocation(at row: Int) {
        let id = locationRows[row].locationId
        if state.expandedAdminVenueIds.contains(id) {
            state.expandedAdminVenueIds.remove(id)
        } else {
            state.expandedAdminVenueIds.insert(id)
        }
    }
}
