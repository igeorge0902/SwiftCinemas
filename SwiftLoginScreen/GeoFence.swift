//
//  GeoFence.swift
//  SwiftCinemas
//
//  Created by Gaspar Gyorgy on 2025. 02. 22..
//  Copyright © 2025. George Gaspar. All rights reserved.
//

import CoreLocation
import UserNotifications

class GeofenceManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    // Add a geofence at a specific location
    func addGeofence(latitude: Double, longitude: Double, radius: Double, identifier: String) {
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), radius: radius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = false // Change to true if you want exit notifications too

        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            locationManager.startMonitoring(for: region)
            print("Geofence added at \(latitude), \(longitude) with \(radius)m radius")
        }
    }
}
