//
//  VenuesVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 24/06/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import MapKit
import SwiftyJSON
import UIKit

class VenuesVC: UIViewController, UITableViewDataSource, UITableViewDelegate, HasAppServices {
    var appServices: AppServices!
    var movieId: Int!
    var movieName: String!
    var selectLarge_picture: String!
    var selectDetails: String!
    var selectVenues_picture: String!
    var imdb: String!

    // Old flow used mapViewPage global; keep equivalent as per-instance state.
    var openedFromMapFlow: Bool = false

    deinit {
        adminPage = false
        print(#function, "\(self)")
        // Keep map caches while MapViewController is alive; it owns lifecycle reset.
        if !isMapFlow {
            LocationsDataManager.shared.locationsForMapPicker.removeAll()
            LocationsDataManager.shared.locationsToDisplay.removeAll()
        }
    }

    var tableData: [VenueModel] = []

    var mapView: MKMapView? = nil
    var handleMapSearchDelegate: HandleMapSearch? = nil

    var tableView: UITableView!
    var detailsView: UIView!
    var detailsLabel: UILabel!

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_venues_details",
           let indexPath = tableView?.indexPathForSelectedRow,
           indexPath.row < tableData.count {
            VenuesDataManager.shared.selectedVenue = tableData[indexPath.row]
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        injectAppServicesIfNeeded()

        setupTableView()
        setupDetailsView()

        NotificationCenter.default.addObserver(self, selector: #selector(navigateBack), name: NSNotification.Name(rawValue: "navigateBack"), object: nil)
    }

    override func viewWillAppear(_: Bool) {
        if let selectedMovie = MoviesDataManager.shared.selectedMovie {
            movieId = selectedMovie.movieId
            movieName = selectedMovie.name
            selectLarge_picture = selectedMovie.largePicture
            selectDetails = selectedMovie.detail
            imdb = selectedMovie.imdbUrl
        }

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.setTitle("Back", for: UIControl.State())
        btnNav.showsTouchWhenHighlighted = true
        btnNav.addTarget(self, action: #selector(VenuesVC.navigateBack), for: UIControl.Event.touchUpInside)

        view.addSubview(btnNav)

        if adminPage {
            addLocation()
        } else if isMapFlow {
            addLocation()
        } else {
            addData()
        }
    }

    private var isMapFlow: Bool {
        openedFromMapFlow || LocationsDataManager.shared.isVenuesFromMapFlow
    }

    private func setupTableView() {
        let tableHeight = view.frame.height / 2
        tableView = UITableView(frame: CGRect(x: 0, y: 100, width: view.frame.width, height: tableHeight))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = true
        tableView.clipsToBounds = true
        view.addSubview(tableView)
    }

    private func setupDetailsView() {
        let detailsFrame = CGRect(x: 0, y: view.frame.height / 2, width: view.frame.width, height: view.frame.height / 2)
        detailsView = UIView(frame: detailsFrame)
        detailsView.backgroundColor = UIColor.lightGray

        // Add a label inside detailsView to show selected venue details
        detailsLabel = UILabel(frame: CGRect(x: 20, y: 20, width: detailsView.frame.width - 40, height: 100))
        detailsLabel.numberOfLines = 0
        detailsLabel.textAlignment = .center
        detailsLabel.font = UIFont.systemFont(ofSize: 16)
        detailsLabel.text = "Select a venue to see details here."

        detailsView.addSubview(detailsLabel)
        view.addSubview(detailsView)
    }

    @objc func navigateBack() {
        dismiss(animated: false, completion: nil)
    }

    @objc func navigateToVenue(button _: UIButton, event _: UIEvent) {
        performSegue(withIdentifier: "goto_venues_details", sender: self)
    }

    func addData() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                self.tableData = try await VenuesDataManager.shared.fetchVenuesForMovie(movieId: String(self.movieId ?? 0))
                self.tableView?.reloadData()
            } catch {
                NSLog("VenuesVC.addData: %@", error.localizedDescription)
            }
        }
    }


    func addLocation() {
        if isMapFlow, !LocationsDataManager.shared.locationsToDisplay.isEmpty {
            LocationsDataManager.shared.locationsForMapPicker = LocationsDataManager.shared.locationsToDisplay
            tableView?.reloadData()
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let locations = try await LocationsDataManager.shared.fetchLocations()
                LocationsDataManager.shared.locationsToDisplay = locations
                if self.isMapFlow {
                    LocationsDataManager.shared.locationsForMapPicker = locations
                }
                self.tableView?.reloadData()
            } catch {
                // Keep any existing in-memory map data as fallback to avoid empty modal.
                if self.isMapFlow, !LocationsDataManager.shared.locationsToDisplay.isEmpty {
                    LocationsDataManager.shared.locationsForMapPicker = LocationsDataManager.shared.locationsToDisplay
                    self.tableView?.reloadData()
                    return
                }
                NSLog("VenuesVC.addLocation: %@", error.localizedDescription)
            }
        }
    }

    private var mapFlowRows: [Location] {
        if !LocationsDataManager.shared.locationsForMapPicker.isEmpty {
            return LocationsDataManager.shared.locationsForMapPicker
        }
        return LocationsDataManager.shared.locationsToDisplay
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "CELL") as UITableViewCell?

        if cell == nil {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "CELL")
        }

        if adminPage || isMapFlow {
            LocationsDataManager.shared.locationsToDisplay.sort { ($0.title ?? "") < ($1.title ?? "") }
            LocationsDataManager.shared.locationsForMapPicker.sort { ($0.title ?? "") < ($1.title ?? "") }

            let data_: Location? = if isMapFlow {
                mapFlowRows[indexPath.row]
            } else {
                LocationsDataManager.shared.locationsToDisplay[indexPath.row]
            }

            var s = ""
            if originalVenueName != nil {
                s = (originalVenueName.string as NSString) as String
            }

            if data_?.title! == s as String {
                let range = (s as NSString).range(of: s as String)
                let mutableAttributedString = NSMutableAttributedString(string: s as String)
                mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: range)
                cell!.textLabel?.attributedText = mutableAttributedString
                cell!.detailTextLabel?.text = data_?.address

            } else {
                let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
                let detailText = NSMutableAttributedString(string: (data_?.title!)!, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

                cell!.textLabel?.attributedText = detailText
                //   cell!.detailTextLabel?.text = data_?.address
            }

        } else {
            let btn = UIButton(type: UIButton.ButtonType.custom) as UIButton
            btn.frame = CGRect(x: view.frame.width * 0.9, y: 15, width: 20, height: 30)
            btn.addTarget(self, action: #selector(VenuesVC.navigateToVenue), for: .touchUpInside)
            btn.tag = indexPath.row
            btn.setImage(UIImage(named: "window-7.png"), for: .normal)
            cell?.contentView.addSubview(btn)

            // TableData.sort { ($0.title ?? "") < ($1.title ?? "")}
            let data = tableData[indexPath.row]

            let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
            let detailText = NSMutableAttributedString(string: data.name, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

            cell!.textLabel?.attributedText = detailText
            // cell!.detailTextLabel?.text = data.address!

            let urlString = URLManager.image(data.venuesPicture)

            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let imgData = try await self.appServices.images.getData(urlString: urlString, realmCache: true)
                    let image = UIImage(data: imgData)
                    cell!.imageView?.image = image
                    if let updatedCell = tableView.cellForRow(at: indexPath) {
                        updatedCell.imageView?.image = image
                        updatedCell.setNeedsLayout()
                    }
                } catch {
                    NSLog("VenuesVC cell image: %@", error.localizedDescription)
                }
            }
        }

        return cell!
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        if adminPage {
            LocationsDataManager.shared.locationsToDisplay.count

        } else if isMapFlow {
            mapFlowRows.count
        } else {
            tableData.count
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if adminPage, tableData.isEmpty {
            let selectedVenue = LocationsDataManager.shared.locationsToDisplay[indexPath.row]
            LocationsDataManager.shared.applySelection(selectedVenue, notificationName: "newScreenVenueSelected")

        } else if isMapFlow {
            let rows = mapFlowRows
            guard indexPath.row < rows.count else { return }
            let selectedVenue = rows[indexPath.row]
            let placemark = MKPlacemark(coordinate: selectedVenue.coordinate)
            handleMapSearchDelegate?.dropPinZoomIn(placemark: placemark)
            LocationsDataManager.shared.applySelection(selectedVenue, notificationName: "screeningVenueSelected")

            dismiss(animated: true, completion: nil)
        } else {
            let data = tableData[indexPath.row]
            VenuesDataManager.shared.selectedVenue = data
            // Update detailsView with the selected venue information
            detailsLabel.text = "📍 Venue: \(data.name)\n🏠 Address: \(data.address)"

            performSegue(withIdentifier: "goto_venues_details", sender: self)
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
