//
//  ViewController.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2021. 08. 10..
//  Copyright © 2021. George Gaspar. All rights reserved.
//

import MapKit
import UIKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark)
}

// var mapview_:MKMapView? = nil
class ViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    deinit {
        mapview_ = nil
    }

    @IBOutlet var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var selectedPin: MKPlacemark? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        mapViewPage = true
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()

        mapview_ = mapView

        let btnVen = UIButton(frame: CGRect(x: view.frame.width / 2, y: 100, width: view.frame.width / 2, height: 20))
        btnVen.backgroundColor = UIColor.black
        btnVen.setTitle("Venues", for: UIControl.State())
        btnVen.showsTouchWhenHighlighted = true
        btnVen.addTarget(self, action: #selector(ViewController.listVenues), for: UIControl.Event.touchUpInside)

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.setTitle("Back", for: UIControl.State())
        btnNav.showsTouchWhenHighlighted = true
        btnNav.addTarget(self, action: #selector(ViewController.navigateBack), for: UIControl.Event.touchUpInside)

        view.addSubview(btnVen)
        view.addSubview(btnNav)
    }

    @objc func navigateBack() {
        dismiss(animated: false, completion: nil)
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
                y: self.view.frame.height * 0.70,
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
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError _: Error) {
        print("error:: (error)")
    }
}

extension ViewController: HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark) {
        // cache the pin
        selectedPin = placemark
        // clear existing pins

        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name

        if let city = placemark.locality, let state = placemark.administrativeArea {
            annotation.subtitle = "(city) (state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}
