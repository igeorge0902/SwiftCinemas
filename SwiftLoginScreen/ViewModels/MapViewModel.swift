import Foundation

@MainActor
final class MapViewModel {
    struct State {
        var selectVenueId: Int?
        var locationId: Int?
        var isLoading = false
        var error: Error?
    }
    private let locations: LocationsDataManager
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?

    init(locations: LocationsDataManager) { self.locations = locations }
    var rows: [Location] { locations.locationsToDisplay }
    var isFromVenueDetails: Bool { locations.isMapFromVenueDetails }
    func setVenueInput(_ id: Int?) { state.selectVenueId = id }
    func setLocationInput(_ id: Int?) { state.locationId = id }
    func enterMapFlow() { locations.isVenuesFromMapFlow = true }
    func selectLocation(id: Int?) { locations.selectedLocationId = id }
    func leaveParent() {
        locations.isVenuesFromMapFlow = false
        locations.locationsToDisplay = []
        locations.locationsForMapPicker = []
    }

    func load() async {
        state.isLoading = true
        state.error = nil
        do {
            if locations.isVenuesFromMapFlow {
                let all = try await locations.fetchLocations()
                locations.locationsToDisplay = locations.isMapFromVenueDetails
                    ? all.filter { $0.locationId == locations.selectedLocationId } : all
                locations.locationsForMapPicker = locations.locationsToDisplay
            }
            if locations.isMapFromVenueDetails, let id = state.selectVenueId ?? locations.selectedVenueId {
                locations.locationsToDisplay = try [await locations.fetchLocationForVenue(venuesId: String(id))]
            }
            state.isLoading = false
            onStateChange?(state)
        } catch {
            state.isLoading = false
            state.error = error
            NSLog("MapViewController addData: %@", error.localizedDescription)
        }
    }
}
