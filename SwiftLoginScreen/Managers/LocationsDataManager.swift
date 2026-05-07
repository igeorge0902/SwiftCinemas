//
//  LocationsDataManager.swift
//  SwiftCinemas
//

import Foundation
import Contacts
import MapKit
import SwiftyJSON

final class LocationsDataManager: SharedDataManager, HasAppServices {
    static let shared = LocationsDataManager()
    static var domain: String { "Locations" }

    var appServices: AppServices!

    private var mbooks: MbooksService { appServices.mbooks }

    private init() {}

    // MARK: - Navigation Context

    /// The selected location (cinema area) for booking flow
    var selectedLocationId: Int?

    /// The selected venue ID when navigating to map from VenuesDetailsVC
    var selectedVenueId: Int?

    /// True when navigating to the map from Venue Details (vs. from browse)
    var isMapFromVenueDetails: Bool = false

    /// Legacy venues list data source used by admin/location flows.
    var locationsToDisplay: [Location] = []

    /// Legacy venues list data source used when opening list from map screen.
    var locationsForMapPicker: [Location] = []

    /// Legacy mode flag for venue list opened from the map screen.
    var isVenuesFromMapFlow: Bool = false

    /// Shared map instance used by legacy venue picker flow.
    weak var activeMapView: MKMapView?

    /// Last location selected in list/map flows.
    var selectedLocation: Location?

    /// Reset all navigation context (call when starting a new booking flow)
    func resetNavigationContext() {
        selectedLocationId = nil
        selectedVenueId = nil
        isMapFromVenueDetails = false
        locationsToDisplay = []
        locationsForMapPicker = []
        isVenuesFromMapFlow = false
        activeMapView = nil
        selectedLocation = nil
    }

    /// Apply venue selection side effects consistently for map/admin flows.
    func applySelection(_ location: Location, notificationName: String? = nil) {
        selectedLocation = location
        selectedLocationId = location.locationId
        if let title = location.title {
            addVenue = title
        }

        if let mapView = activeMapView {
            let selectedItem = location.mapItem().placemark
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedItem.coordinate
            annotation.title = selectedItem.name
            if let city = selectedItem.locality, let state = selectedItem.administrativeArea {
                annotation.subtitle = "(city) (state)"
            }
            mapView.addAnnotation(annotation)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: selectedItem.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }

        if let notificationName {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationName), object: nil)
        }
    }

    // MARK: - Fetch Methods

    /// Fetch all cinema locations
    func fetchLocations() async throws -> [Location] {
        do {
            let data = try await mbooks.locations()
            let json = try JSON(data: data)

            guard let locationArray = json["locations"].array else {
                throw AppError.decodingFailed
            }

            return locationArray.compactMap { Location(json: $0) }
        } catch {
            throw handleError(error)
        }
    }

    /// Fetch location for specific venue
    func fetchLocationForVenue(venuesId: String) async throws -> Location {
        do {
            let data = try await mbooks.locationsVenue(venuesId: venuesId)
            let json = try JSON(data: data)

            // API may return either {"location": {...}} or a direct location object.
            let locationJSON = json["location"].exists() ? json["location"] : json

            guard let location = Location(json: locationJSON) else {
                throw AppError.decodingFailed
            }

            return location
        } catch {
            throw handleError(error)
        }
    }

    /// Returns coordinates for a specific location object.
    func getCoordinates(location: Location) -> CLLocationCoordinate2D? {
        location.coordinate
    }

    /// Returns coordinates for a location ID if it exists in currently loaded location caches.
    func getCoordinates(locationId: Int) -> CLLocationCoordinate2D? {
        if let selectedLocation, selectedLocation.locationId == locationId {
            return selectedLocation.coordinate
        }

        if let match = locationsToDisplay.first(where: { $0.locationId == locationId })
            ?? locationsForMapPicker.first(where: { $0.locationId == locationId }) {
            return match.coordinate
        }

        return nil
    }
}

final class Location: NSObject, MKAnnotation {
    let locationId: Int
    let title: String?
    let address: String
    let formattedAddress: String
    let coordinate: CLLocationCoordinate2D
    let thumbnail: String?

    init?(json: JSON) {
        let id = json["locationId"].int ?? Int(json["locationId"].string ?? "")
        let name = json["name"].string ?? json["title"].string
        let address = json["address"].string ?? json["formatted_address"].string ?? ""
        let formatted = json["formatted_address"].string ?? json["address"].string ?? ""
        let latitude = json["latitude"].double ?? Double(json["latitude"].string ?? "")
        let longitude = json["longitude"].double ?? Double(json["longitude"].string ?? "")

        guard let id,
              let name,
              let latitude,
              let longitude else {
            return nil
        }

        self.locationId = id
        self.title = name
        self.address = address
        self.formattedAddress = formatted
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.thumbnail = json["thumbnail"].string ?? "No picture"

        super.init()
    }

    @objc dynamic var subtitle: String? { address }

    func pinColor() -> MKPinAnnotationColor { .red }

    func mapItem() -> MKMapItem {
        let placemark = MKPlacemark(coordinate: coordinate,
                                    addressDictionary: [CNPostalAddressStreetKey: address])
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        return mapItem
    }
}

typealias LocationModel = Location

