import Combine
import MapKit
import SwiftyJSON
import SwiftUI
import UIKit

// Review slice for Venues SwiftUI migration. Legacy UIViewController flow stays untouched.
enum VenuesMode {
    case standard
    case admin
    case map
}

enum VenuesFlowMode: String {
    case legacy
    case migration
    case ab
}

enum VenuesFeatureFlags {
    static let flowModeKey = "venues.flow.mode"
    static let abBucketKey = "venues.flow.ab.bucket"

    static var flowMode: VenuesFlowMode {
        let raw = UserDefaults.standard.string(forKey: flowModeKey) ?? VenuesFlowMode.migration.rawValue
        return VenuesFlowMode(rawValue: raw) ?? .legacy
    }

    static func setFlowMode(_ mode: VenuesFlowMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: flowModeKey)
    }

    static func shouldUseMigration() -> Bool {
        switch flowMode {
        case .legacy:
            return false
        case .migration:
            return true
        case .ab:
            return abBucket
        }
    }

    private static var abBucket: Bool {
        if UserDefaults.standard.object(forKey: abBucketKey) == nil {
            UserDefaults.standard.set(Bool.random(), forKey: abBucketKey)
        }
        return UserDefaults.standard.bool(forKey: abBucketKey)
    }
}

struct VenuesInput {
    var movieId: Int
    var movieName: String
    var selectLargePicture: String
    var selectDetails: String
    var imdb: String
    var mode: VenuesMode
    
    /// Determines mode from manager-owned context.
    static func fromManagerContext(
        movieId: Int,
        movieName: String,
        selectLargePicture: String,
        selectDetails: String,
        imdb: String
    ) -> VenuesInput {
        let mode: VenuesMode
        if LocationsDataManager.shared.isVenuesFromMapFlow {
            mode = .map
        } else {
            mode = .standard
        }
        
        return VenuesInput(
            movieId: movieId,
            movieName: movieName,
            selectLargePicture: selectLargePicture,
            selectDetails: selectDetails,
            imdb: imdb,
            mode: mode
        )
    }
}

struct VenuesUnifiedItem: Identifiable, Equatable {
    let id: String
    let venuesId: Int?
    let locationId: Int?
    let name: String
    let address: String
    let venuesPicture: String?
    let screenScreenId: String?
    let coordinate: CLLocationCoordinate2D?

    static func == (lhs: VenuesUnifiedItem, rhs: VenuesUnifiedItem) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class VenuesMigrationViewModel: ObservableObject {
    @Published var venues: [VenuesUnifiedItem] = []
    @Published var locations: [Location] = []
    @Published var mapLocations: [Location] = []
    @Published var selectedVenue: VenuesUnifiedItem?
    @Published var selectedLocation: Location?
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 47.4979, longitude: 19.0402),
        span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
    )

    let input: VenuesInput
    private let mbooks: MbooksService
    let imageServices: ImageResourceService
    private var backObserver: AnyCancellable?
    var onDismiss: (() -> Void)?
    var onNavigateToDetails: ((VenuesUnifiedItem) -> Void)?

    init(input: VenuesInput, appServices: AppServices) {
        self.input = input
        self.mbooks = appServices.mbooks
        self.imageServices = appServices.images
        backObserver = NotificationCenter.default
            .publisher(for: NSNotification.Name(rawValue: "navigateBack"))
            .sink { [weak self] _ in
                self?.onDismiss?()
            }
    }

    deinit {
        backObserver?.cancel()
        LocationsDataManager.shared.isVenuesFromMapFlow = false
        LocationsDataManager.shared.locationsToDisplay = []
        LocationsDataManager.shared.locationsForMapPicker = []
    }

    func loadInitialData() async {
        switch input.mode {
        case .standard:
            await loadVenues()
        case .admin, .map:
            await loadLocations()
        }
    }

    func loadVenues() async {
        venues.removeAll()

        do {
            let data = try await mbooks.venue(movieId: String(input.movieId))
            let json = try JSON(data: data)
            if let list = json["venues"].object as? NSArray {
                venues = list.compactMap { block in
                    guard let dict = block as? NSDictionary else { return nil }
                    let venuesId = dict["venuesId"] as? Int
                        ?? (dict["venuesId"] as? String).flatMap(Int.init)
                    let locationId = dict["locationId"] as? Int
                        ?? (dict["locationId"] as? String).flatMap(Int.init)
                    let screenId = dict["screen_screenId"] as? String
                        ?? (dict["screen_screenId"] as? Int).map(String.init)
                    return VenuesUnifiedItem(
                        id: "venue-\(venuesId ?? -1)-\(locationId ?? -1)",
                        venuesId: venuesId,
                        locationId: locationId,
                        name: dict["name"] as? String ?? "",
                        address: dict["address"] as? String ?? "",
                        venuesPicture: dict["venues_picture"] as? String,
                        screenScreenId: screenId,
                        coordinate: nil
                    )
                }
            }
        } catch {
            NSLog("VenuesMigrationViewModel.loadVenues: %@", error.localizedDescription)
        }
    }

    func loadLocations() async {
        locations.removeAll()
        mapLocations.removeAll()

        do {
            let data = try await mbooks.locations()
            let json = try JSON(data: data)
            if let list = json["locations"].object as? NSArray {
                locations = list.compactMap { block in
                    guard let dict = block as? NSDictionary else { return nil }
                    return Location(json: JSON(dict))
                }
                locations.sort { ($0.title ?? "") < ($1.title ?? "") }

                LocationsDataManager.shared.locationsToDisplay = locations

                if input.mode == .map {
                    LocationsDataManager.shared.locationsForMapPicker = locations
                    mapLocations = LocationsDataManager.shared.locationsForMapPicker
                } else {
                    mapLocations = locations
                }

                let initialSelection = input.mode == .map ? mapLocations.first : locations.first
                if let first = initialSelection {
                    select(location: first, emitNotification: false)
                }
            }
        } catch {
            NSLog("VenuesMigrationViewModel.loadLocations: %@", error.localizedDescription)
        }
    }

    func select(venue: VenuesUnifiedItem) {
        selectedVenue = venue
    }

    func select(location: Location, emitNotification: Bool = true) {
        selectedLocation = location
        mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )

        guard emitNotification else { return }
        if input.mode == .admin {
            LocationsDataManager.shared.applySelection(location, notificationName: "newScreenVenueSelected")
        } else if input.mode == .map {
            LocationsDataManager.shared.applySelection(location, notificationName: "screeningVenueSelected")
        }
    }

    var legacySelectedVenueName: String {
        (originalVenueName?.string as NSString?) as String? ?? ""
    }
}

struct VenuesMigrationView: View {
    @ObservedObject var viewModel: VenuesMigrationViewModel

    var body: some View {
        VStack(spacing: 0) {
            topBar

            switch viewModel.input.mode {
            case .standard:
                standardModeView
            case .admin:
                adminModeView
            case .map:
                mapModeView
            }
        }
        .task {
            await viewModel.loadInitialData()
        }
    }

    private var topBar: some View {
        HStack {
            Button("‹ Back") {
                viewModel.onDismiss?()
            }
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(14)

            Spacer()
            Text(viewModel.input.movieName)
                .lineLimit(1)
                .font(.headline)
                .foregroundColor(.black)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.white)
    }

    // MARK: - Standard Mode
    // Layout: full-width list of venues (with pictures) on top,
    // details panel pinned to the bottom (horizontal split is REMOVED per spec).
    private var standardModeView: some View {
        VStack(spacing: 0) {
            List(viewModel.venues) { venue in
                Button {
                    viewModel.select(venue: venue)
                } label: {
                    VenuePictureRow(
                        venue: venue,
                        isSelected: viewModel.selectedVenue?.id == venue.id,
                        imageServices: viewModel.imageServices
                    )
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.white)
            }
            .listStyle(.plain)
            .background(Color.white)

            Divider()

            // Details panel pinned at the bottom
            VStack(alignment: .leading, spacing: 6) {
                Text("Selected Venue Details")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.65))
                if let venue = viewModel.selectedVenue {
                    Text(venue.name)
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineLimit(1)
                    Text(venue.address)
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.7))
                } else {
                    Text("📍 Select a venue to see details")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.65))
                }

                Button {
                    if let venue = viewModel.selectedVenue {
                        viewModel.onNavigateToDetails?(venue)
                    }
                } label: {
                    Text("Continue to Venue Details")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .background(viewModel.selectedVenue == nil ? Color.gray.opacity(0.6) : Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(viewModel.selectedVenue == nil)
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(UIColor(white: 0.96, alpha: 1)))
        }
    }

    // MARK: - Admin Mode
    private var adminModeView: some View {
        List(viewModel.locations, id: \.locationId) { location in
            Button {
                viewModel.select(location: location)
            } label: {
                VenueListRow(
                    title: location.title ?? "",
                    subtitle: location.address,
                    isSelected: (location.title ?? "") == viewModel.legacySelectedVenueName
                )
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }

    // MARK: - Map Mode
    private var mapModeView: some View {
        VStack(spacing: 0) {
            VenuesLegacyMapView(
                locations: viewModel.mapLocations,
                region: $viewModel.mapRegion,
                selectedLocation: $viewModel.selectedLocation,
                onSelect: { location in
                    viewModel.select(location: location)
                }
            )
            .frame(height: 300)

            Divider()

            List(viewModel.mapLocations, id: \.locationId) { location in
                Button {
                    viewModel.select(location: location)
                } label: {
                    VenueListRow(
                        title: location.title ?? "",
                        subtitle: location.address,
                        isSelected: (location.title ?? "") == (viewModel.selectedLocation?.title ?? "")
                    )
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Shared list row components

/// Plain text row used by admin and map modes.
private struct VenueListRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(isSelected ? .red : .primary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

/// Image + name row used by standard mode where venue pictures are available.
private struct VenuePictureRow: View {
    let venue: VenuesUnifiedItem
    let isSelected: Bool
    let imageServices: ImageResourceService

    @State private var image: UIImage? = nil

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.gray.opacity(0.2)
                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                }
            }
            .frame(width: 56, height: 56)
            .clipped()
            .cornerRadius(6)

            VStack(alignment: .leading, spacing: 3) {
                Text(venue.name)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.black)
                if !venue.address.isEmpty {
                    Text(venue.address)
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.68))
                        .lineLimit(2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(red: 0.72, green: 0.75, blue: 0.82))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(isSelected ? Color.black.opacity(0.06) : Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.black.opacity(0.28) : Color.black.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(12)
        .contentShape(Rectangle())
        .task(id: venue.venuesPicture) {
            guard let pic = venue.venuesPicture, !pic.isEmpty else { return }
            let urlString = URLManager.image(pic)
            do {
                let data = try await imageServices.getData(urlString: urlString, realmCache: true)
                image = UIImage(data: data)
            } catch {
                NSLog("VenuePictureRow image load: %@", error.localizedDescription)
            }
        }
    }
}

struct VenuesLegacyMapView: UIViewRepresentable {
    let locations: [Location]
    @Binding var region: MKCoordinateRegion
    @Binding var selectedLocation: Location?
    let onSelect: (Location) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.pointOfInterestFilter = .includingAll
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(locations)
        mapView.setRegion(region, animated: true)

        if let selectedLocation {
            mapView.selectAnnotation(selectedLocation, animated: true)
        }

        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: VenuesLegacyMapView

        init(parent: VenuesLegacyMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let place = view.annotation as? Location else { return }
            parent.onSelect(place)
        }
    }
}

final class VenuesMigrationHostVC: UIViewController, HasAppServices {
    var appServices: AppServices!
    private let input: VenuesInput

    init(input: VenuesInput, appServices: AppServices) {
        self.input = input
        self.appServices = appServices
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewModel = VenuesMigrationViewModel(input: input, appServices: appServices)
        viewModel.onDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }

        viewModel.onNavigateToDetails = { [weak self] venue in
            guard let self else { return }
            self.presentVenuesDetails(for: venue)
        }

        let host = UIHostingController(rootView: VenuesMigrationView(viewModel: viewModel))
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        host.didMove(toParent: self)
    }

    private func presentVenuesDetails(for venue: VenuesUnifiedItem) {
        let storyboard = UIStoryboard(name: "Storyboard", bundle: nil)
        guard let detailsVC = storyboard.instantiateViewController(withIdentifier: "VenuesDetailsVC") as? VenuesDetailsVC else {
            return
        }
        detailsVC.appServices = appServices

        // Set properties from migration input
        detailsVC.movieId = input.movieId
        detailsVC.movieName = input.movieName
        detailsVC.movieDetails = input.selectDetails
        detailsVC.selectLargePicture = input.selectLargePicture
        detailsVC.iMDB = input.imdb

        // Set venue-specific properties from selected venue
        detailsVC.selectVenueId = venue.venuesId
        detailsVC.venueName = venue.name
        detailsVC.selectAddress = venue.address
        detailsVC.selectVenuesPicture = venue.venuesPicture
        detailsVC.screenScreenId = venue.screenScreenId
        detailsVC.locationId = venue.locationId ?? 0

        detailsVC.modalPresentationStyle = .fullScreen
        present(detailsVC, animated: true)
    }
}

enum VenuesMigrationFactory {
    static func make(input: VenuesInput, mode: VenuesMode, appServices: AppServices) -> UIViewController {
        var configuredInput = input
        configuredInput.mode = mode
        return VenuesMigrationHostVC(input: configuredInput, appServices: appServices)
    }
    
    /// Make controller using manager context.
    static func makeFromManagerContext(
        movieId: Int,
        movieName: String,
        selectLargePicture: String,
        selectDetails: String,
        imdb: String,
        appServices: AppServices
    ) -> UIViewController {
        let input = VenuesInput.fromManagerContext(
            movieId: movieId,
            movieName: movieName,
            selectLargePicture: selectLargePicture,
            selectDetails: selectDetails,
            imdb: imdb
        )
        return VenuesMigrationHostVC(input: input, appServices: appServices)
    }
}

