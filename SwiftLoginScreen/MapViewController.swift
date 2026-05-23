// MapViewController.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import MapKit
import UIKit

class MapViewController: UIViewController, MKMapViewDelegate, @MainActor CLLocationManagerDelegate, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate, @MainActor HasAppServices, @MainActor HandleMapSearch {
    // MARK: Lifecycle

    deinit {
        print(#function, "\(self)")
    }

    // MARK: Internal

    class HalfSizePresentationController: UIPresentationController {
        override var frameOfPresentedViewInContainerView: CGRect {
            CGRect(x: 0, y: 200, width: containerView!.bounds.width, height: containerView!.bounds.height)
        }
    }

    var appServices: AppServices!
    var icons: [String: String] = Dictionary()
    var imageView: UIImageView!
    var locationManager: CLLocationManager!
    var locationId_: Int!
    var selectVenueId: Int!

    @IBOutlet var mapView: MKMapView!

    let regionRadius: CLLocationDistance = 1000

    override func viewDidLoad() {
        super.viewDidLoad()

        if selectVenueId == nil {
            selectVenueId = VenuesDataManager.shared.selectedVenue?.venuesId
        }

        LocationsDataManager.shared.isVenuesFromMapFlow = true
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        LocationsDataManager.shared.activeMapView = mapView

        // user activated automatic authorization info mode
        let status = CLLocationManager.authorizationStatus()

        if status == .notDetermined || status == .denied {
            DispatchQueue.main.async { () in
                // present an alert indicating location authorization required
                let message = "\(status)\n\nPlease allow the app to access your location through the Settings."
                self.showMessage(message)
            }
        }

        locationManager!.startUpdatingLocation()
        locationManager!.startUpdatingHeading()

        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = MKMapType.standard
        mapView.userTrackingMode = LocationsDataManager.shared.isMapFromVenueDetails ? .none : .follow
        // mapView.userTrackingMode = MKUserTrackingMode(rawValue: 2)!

        mapView.showsScale = true
        mapView.showsTraffic = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.showsUserLocation = true
        mapView.isScrollEnabled = true

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.setTitle("Back", for: UIControl.State())
        btnNav.showsTouchWhenHighlighted = true
        btnNav.addTarget(self, action: #selector(MapViewController.navigateBack), for: UIControl.Event.touchUpInside)

        let btnVen = UIButton(frame: CGRect(x: view.frame.width / 2, y: 25, width: view.frame.width / 2, height: 20))
        btnVen.backgroundColor = UIColor.black
        btnVen.setTitle("Venues", for: UIControl.State())
        btnVen.showsTouchWhenHighlighted = true
        btnVen.addTarget(self, action: #selector(MapViewController.listVenues), for: UIControl.Event.touchUpInside)

        view.addSubview(btnVen)
        view.addSubview(btnNav)
    }

    override func viewWillAppear(_: Bool) {
        super.viewWillAppear(true)

        addData()
        mapView.addAnnotations(LocationsDataManager.shared.locationsToDisplay)
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)

        if LocationsDataManager.shared.isMapFromVenueDetails {
            return
        }

        let location = locationManager.location
        if let location {
            centerMapOnLocation(location)
            mapView.centerCoordinate = location.coordinate
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent {
            LocationsDataManager.shared.isVenuesFromMapFlow = false
            LocationsDataManager.shared.locationsToDisplay = []
            LocationsDataManager.shared.locationsForMapPicker = []
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_venues_for_movies" {
            LocationsDataManager.shared.selectedLocationId = locationId_
        }
    }

    @objc func navigateBack() {
        dismiss(animated: true, completion: nil)
    }

    @objc func listVenues() {
        LocationsDataManager.shared.isVenuesFromMapFlow = true
        DispatchQueue.main.async {
            let popOver = VenuesVC()
            popOver.openedFromMapFlow = true
            popOver.mapView = self.mapView
            popOver.handleMapSearchDelegate = self
            popOver.modalPresentationStyle = UIModalPresentationStyle.popover
            popOver.preferredContentSize = CGSize(width: self.view.frame.width * 0.90, height: self.view.frame.height / 2)

            let popoverMenuViewController = popOver.popoverPresentationController
            popoverMenuViewController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            popoverMenuViewController?.delegate = self
            popoverMenuViewController?.sourceView = self.view
            popoverMenuViewController?.backgroundColor = .white
            popoverMenuViewController!.sourceRect = CGRect(
                x: self.view.frame.width * 0.50,
                y: self.view.frame.height,
                width: 0,
                height: 0
            )

            self.present(
                popOver,
                animated: true,
                completion: nil
            )
        }
    }

    func addData() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let locationsManager = LocationsDataManager.shared
            do {
                if locationsManager.isVenuesFromMapFlow {
                    let all = try await locationsManager.fetchLocations()
                    locationsManager.locationsToDisplay = locationsManager.isMapFromVenueDetails ? all.filter { $0.locationId == locationsManager.selectedLocationId } : all
                    locationsManager.locationsForMapPicker = locationsManager.locationsToDisplay
                }

                if locationsManager.isMapFromVenueDetails {
                    if let venueId = self.selectVenueId ?? locationsManager.selectedVenueId {
                        locationsManager.locationsToDisplay = try [await locationsManager.fetchLocationForVenue(venuesId: String(venueId))]
                    }
                }

                // Update pins
                mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
                mapView.addAnnotations(locationsManager.locationsToDisplay)

                // Focus on venue when coming from details
                if locationsManager.isMapFromVenueDetails, let pin = locationsManager.locationsToDisplay.first {
                    mapView.setRegion(MKCoordinateRegion(
                        center: pin.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ), animated: true)
                    mapView.selectAnnotation(pin, animated: true)
                }
            } catch {
                NSLog("MapViewController addData: %@", error.localizedDescription)
            }
        }
    }

    func dropPinZoomIn(placemark: MKPlacemark) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }

    func centerMapOnLocation(_ location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius * 1.0, longitudinalMeters: regionRadius * 1.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Location {
            let identifier = "pin"
            var view: MKPinAnnotationView

            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKPinAnnotationView
            {
                // 2
                dequeuedView.annotation = annotation
                view = dequeuedView

            } else {
                // 3
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.animatesDrop = true
                view.calloutOffset = CGPoint(x: -5, y: 5)

                icons = ["About": "about", "CircleRight": "circled_right"]

                let arrowButton = UIButton() as UIView

                arrowButton.frame.size.width = 44
                arrowButton.frame.size.height = 44

                let icon: UIImage? = UIImage(named: icons["CircleRight"]!)
                imageView = UIImageView(frame: CGRect(x: 0, y: 10, width: icon!.size.width, height: icon!.size.height))
                imageView.image = icon

                arrowButton.addSubview(imageView)

                view.rightCalloutAccessoryView = arrowButton

                /*
                 let button : UIButton = UIButton(type: .System) as UIButton
                 button.addTarget(self, action:#selector(self.showActionSheetTapped), forControlEvents: UIControlEvents.TouchUpInside)
                 */

                if !LocationsDataManager.shared.isMapFromVenueDetails {
                    let infoButton = UIButton() as UIView

                    infoButton.frame.size.width = 44
                    infoButton.frame.size.height = 44

                    let icon_: UIImage? = UIImage(named: icons["About"]!)
                    imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: icon_!.size.width, height: icon_!.size.height))
                    imageView.image = icon_

                    infoButton.addSubview(imageView)

                    view.leftCalloutAccessoryView = infoButton
                }
            }

            view.pinColor = annotation.pinColor()

            return view
        }
        return nil
    }

    func mapView(_: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if #available(iOS 9.0, *) {
        } else {
            // Fallback on earlier versions
        }

        if !LocationsDataManager.shared.isMapFromVenueDetails {
            if control == view.leftCalloutAccessoryView {
                let location = view.annotation as! Location
                locationId_ = location.locationId
                LocationsDataManager.shared.selectedLocationId = location.locationId
                control.isHighlighted = true
                control.isSelected = true
                showActionSheetTapped()
            }
        }

        if control == view.rightCalloutAccessoryView {
            let location = view.annotation as! Location
            let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
            location.mapItem().openInMaps(launchOptions: launchOptions)
        }
    }

    func mapView(_: MKMapView, didSelect _: MKAnnotationView) {
        //  self.showActionSheetTapped()
        print("hello")
    }

    func mapView(_: MKMapView, didUpdate _: MKUserLocation) {
        // mapView.centerCoordinate = userLocation.location!.coordinate
    }

    func locationManager(_: CLLocationManager, didUpdateToLocations newLocations: CLLocation, fromLocation _: CLLocation) {
        print("present location : \(newLocations.coordinate.latitude), \(newLocations.coordinate.longitude)")
    }

    func locationManager(manager _: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as! CLLocation

        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

        mapView.setRegion(region, animated: true)
    }

    func locationManager(_: CLLocationManager, didEnterRegion _: CLRegion) {
        NSLog("Entering region")
    }

    func locationManager(_: CLLocationManager, didExitRegion _: CLRegion) {
        NSLog("Exit region")
    }

    func showActionSheetTapped() {
        // Create the AlertController
        let actionSheetController = UIAlertController(title: "Action Sheet", message: "Choose an option!", preferredStyle: .actionSheet)

        // Create and add the Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        // Create and add first option action
        let takeAction = UIAlertAction(title: "Go to Venue", style: .default) { _ in
            self.performSegue(withIdentifier: "goto_venues_for_movies", sender: self)
            // Code for launching the camera goes here
        }
        actionSheetController.addAction(takeAction)

        // Present the AlertController
        present(actionSheetController, animated: true, completion: nil)
    }

    func showMessage(_ message: String) {
        // Create an Alert
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)

        // Add an OK button to dismiss
        let dismissAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { _ in
        }
        alertController.addAction(dismissAction)

        // Show the Alert
        present(alertController, animated: true, completion: nil)
    }

    func presentationController(forPresented presented: UIViewController, presenting _: UIViewController?, source _: UIViewController) -> UIPresentationController? {
        HalfSizePresentationController(presentedViewController: presented, presenting: presentingViewController)
    }

    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        .none
    }
}
