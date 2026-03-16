//
//  PlacesData.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 26/06/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//
//

import AddressBook
import Foundation
import MapKit
import SwiftyJSON

class PlacesData: NSObject, MKAnnotation {
    // Place structure
    let locationId: Int!
    let title: String?
    let address: String
    let type: String
    let coordinate: CLLocationCoordinate2D
    var thumbnail: String?

    init(locationId: Int, title: String, address: String, type: String, coordinate: CLLocationCoordinate2D, thumbnail: String) {
        self.locationId = locationId
        self.title = title
        self.address = address
        self.type = type
        self.coordinate = coordinate
        self.thumbnail = thumbnail
        // if thumbnail.isEmpty { self.thumbnail = "No picture" }

        super.init()
    }

    class func fromJSON(_ json: NSDictionary) -> PlacesData! {
        let locationId = json.value(forKey: "locationId") as! Int
        let title = json.value(forKey: "name") as! String
        let address = json.value(forKey: "formatted_address") as! String
        let type = "movie_theater" as String
        /*
         guard let geometry = json.valueForKey("geometry"),
             let location = geometry.valueForKey("location") else { return nil }
         */
        let latitude = json.value(forKey: "latitude") as! Double
        let longitude = json.value(forKey: "longitude") as! Double
        let thumbnail = json.value(forKey: "thumbnail") as? String

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        return PlacesData(locationId: locationId, title: title, address: address, type: type, coordinate: coordinate, thumbnail: thumbnail ?? "No picture")
    }

    var locationaddress: String? {
        address
    }

    var locationId_: Int? {
        locationId
    }

    // MARK: - MapKit related methods

    // pinColor for disciplines: Sculpture, Plaque, Mural, Monument, other
    func pinColor() -> MKPinAnnotationColor {
        switch type {
        case "movie_theater":
            .red
        case "beauty_salon":
            .purple
        default:
            .green
        }
    }

    // annotation callout opens this mapItem in Maps app
    func mapItem() -> MKMapItem {
        // decorate the map with the appended Artwork structure items
        let addressDict = [String(kABPersonAddressStreetKey): locationaddress! as String]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        // mapItem.phoneNumber = String(self.locationId)

        return mapItem
    }
}
