//
//  MapViewController.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 26/06/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import MapKit
import SwiftyJSON
import UIKit
import UserNotifications

var PlacesData_: [PlacesData] = .init()
var PlacesData2_: [PlacesData] = .init()
var mapViewPage: Bool = false
var mapview_: MKMapView?

protocol HandleMapSearch_ {
    func dropPinZoomIn(placemark: MKPlacemark)
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate {
    deinit {
        PlacesData_.removeAll()
        mapViewPage = false
        print(#function, "\(self)")
    }

    var icons: [String: String] = Dictionary()
    var imageView: UIImageView!
    var locationManager: CLLocationManager!
    var locationId_: Int!
    var selectVenueId: Int!
    var map2: Bool?
    var selectedPin: MKPlacemark? = nil

    @IBOutlet var mapView: MKMapView!

    let regionRadius: CLLocationDistance = 1000

    override func viewDidLoad() {
        super.viewDidLoad()

        mapViewPage = true
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        mapview_ = mapView

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
        mapView.userTrackingMode = .follow
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
        mapView.addAnnotations(PlacesData_)
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)

        let location = locationManager.location
        centerMapOnLocation(location!)
        mapView.centerCoordinate = location!.coordinate
    }

    // instantiate Artwork class
    var artworks = [PlacesData]()

    @objc func navigateBack() {
        dismiss(animated: true, completion: nil)
    }

    @objc func listVenues() {
        mapViewPage = true
        DispatchQueue.main.async {
            let popOver = VenuesVC()
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
        var pathString = ""
        var queryString: [String: String]?
        if selectVenueId == nil {
            pathString = "locations"
        } else {
            pathString = "locations/venue"
            queryString = ["venuesId": String(selectVenueId!)]
        }

        var errorOnLogin: GeneralRequestManager?

        errorOnLogin = GeneralRequestManager(url: URLManager.mbooks("/" + pathString), errors: "", method: "GET", headers: nil, queryParameters: queryString, bodyParameters: nil, isCacheable: "", contentType: "", bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            //   PlacesData_.removeAll()

            if let list = json["locations"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        if let artwork = PlacesData.fromJSON(dataBlock) {
                            PlacesData_.append(artwork)
                        }
                    }
                }

            } else {
                let locationId = json["locationId"].int
                let formatted_address = json["formatted_address"].string
                let name = json["name"].string
                let latitude = json["latitude"].rawValue
                let longitude = json["longitude"].rawValue

                let venuePlaceData: NSDictionary = ["locationId": locationId!, "formatted_address": formatted_address!, "name": name!, "latitude": latitude, "longitude": longitude]

                if let artwork = PlacesData.fromJSON(venuePlaceData) {
                    PlacesData_.append(artwork)
                }
            }

            self.mapView.addAnnotations(PlacesData_)
        }
    }

    func centerMapOnLocation(_ location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius * 1.0, longitudinalMeters: regionRadius * 1.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? PlacesData {
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

                if map2 == false {
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

        if map2 == false {
            if control == view.leftCalloutAccessoryView {
                let location = view.annotation as! PlacesData
                locationId_ = location.locationId
                control.isHighlighted = true
                control.isSelected = true
                showActionSheetTapped()
            }
        }

        if control == view.rightCalloutAccessoryView {
            let location = view.annotation as! PlacesData
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

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_venues_for_movies" {
            let nextSegue = segue.destination as? VenueForMoviesVC

            nextSegue!.locationId = locationId_
        }
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

    class HalfSizePresentationController: UIPresentationController {
        override var frameOfPresentedViewInContainerView: CGRect {
            CGRect(x: 0, y: 200, width: containerView!.bounds.width, height: containerView!.bounds.height)
        }
    }

    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        .none
    }

    // MARK: - location manager to authorize user location for Maps app

    //  var locationManager = CLLocationManager()
    //  func checkLocationAuthorizationStatus() {
    //    if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
    //      mapView.showsUserLocation = true
    //    } else {
    //      locationManager.requestWhenInUseAuthorization()
    //    }
    //  }
    //
    //  override func viewDidAppear(animated: Bool) {
    //    super.viewDidAppear(animated)
    //    checkLocationAuthorizationStatus()
    //  }
}
