// GeoFence.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import CoreLocation
import UserNotifications

class GeofenceManager: NSObject, CLLocationManagerDelegate {
    // MARK: Internal

    /// Add a geofence at a specific location
    func addGeofence(latitude: Double, longitude: Double, radius: Double, identifier: String) {
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), radius: radius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = false // Change to true if you want exit notifications too

        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            locationManager.startMonitoring(for: region)
            print("Geofence added at \(latitude), \(longitude) with \(radius)m radius")
        }
    }

    // MARK: Private

    private let locationManager = CLLocationManager()
}
