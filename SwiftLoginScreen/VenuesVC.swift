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
    var continueButton: UIButton!
    private var backButton: UIButton!
    private var selectedVenueIndex: Int?
    private var hasConfiguredStaticUI = false

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_venues_details" {
            if let selectedVenueIndex, selectedVenueIndex < tableData.count {
                VenuesDataManager.shared.selectedVenue = tableData[selectedVenueIndex]
            } else if let indexPath = tableView?.indexPathForSelectedRow,
                      indexPath.row < tableData.count {
                VenuesDataManager.shared.selectedVenue = tableData[indexPath.row]
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        injectAppServicesIfNeeded()

        configureStaticUIIfNeeded()

        NotificationCenter.default.addObserver(self, selector: #selector(navigateBack), name: NSNotification.Name(rawValue: "navigateBack"), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Rebuild top nav button via shared helper so style/layout stays consistent on re-entry.
        setupBackButton()

        if let selectedMovie = MoviesDataManager.shared.selectedMovie {
            movieId = selectedMovie.movieId
            movieName = selectedMovie.name
            selectLarge_picture = selectedMovie.largePicture
            selectDetails = selectedMovie.detail
            imdb = selectedMovie.imdbUrl
        }

        resetSelectionState()

        if adminPage {
            addLocation()
        } else if isMapFlow {
            addLocation()
        } else {
            addData()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutStaticUI()
    }

    private var isMapFlow: Bool {
        openedFromMapFlow || LocationsDataManager.shared.isVenuesFromMapFlow
    }

    private func configureStaticUIIfNeeded() {
        guard !hasConfiguredStaticUI else { return }
        hasConfiguredStaticUI = true
        view.backgroundColor = .white
        setupBackButton()
        setupTableView()
        setupDetailsView()
    }

    private func setupBackButton() {
        backButton = addTopNavigationButtons([
            (title: "‹ Back", action: #selector(VenuesVC.navigateBack)),
        ], topOffset: 12).first
    }

    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = true
        tableView.clipsToBounds = true
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 8, right: 0)
        tableView.rowHeight = 82
        view.addSubview(tableView)
    }

    private func setupDetailsView() {
        detailsView = UIView(frame: .zero)
        detailsView.backgroundColor = UIColor(white: 0.96, alpha: 1)
        detailsView.layer.borderColor = UIColor.black.withAlphaComponent(0.08).cgColor
        detailsView.layer.borderWidth = 1

        detailsLabel = UILabel(frame: .zero)
        detailsLabel.numberOfLines = 0
        detailsLabel.textAlignment = .left
        detailsLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        detailsLabel.textColor = .black
        detailsLabel.text = "Select a venue to see details here."

        continueButton = UIButton(type: .system)
        continueButton.setTitle("Continue to Venue Details", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = UIColor(white: 0.70, alpha: 1)
        continueButton.layer.cornerRadius = 12
        continueButton.isEnabled = false
        continueButton.addTarget(self, action: #selector(continueToVenueDetails), for: .touchUpInside)

        detailsView.addSubview(detailsLabel)
        detailsView.addSubview(continueButton)
        view.addSubview(detailsView)
    }

    private func layoutStaticUI() {
        let safeTop = view.safeAreaInsets.top
        let safeBottom = max(view.safeAreaInsets.bottom, 12)
        layoutTopNavigationButtons([backButton].compactMap { $0 }, topOffset: 12)

        let detailsHeight: CGFloat = (adminPage || isMapFlow) ? 0 : 170
        if detailsHeight > 0 {
            detailsView.isHidden = false
            detailsView.frame = CGRect(
                x: 0,
                y: view.bounds.height - detailsHeight - safeBottom,
                width: view.bounds.width,
                height: detailsHeight + safeBottom
            )
            detailsLabel.frame = CGRect(x: 16, y: 14, width: detailsView.bounds.width - 32, height: 78)
            continueButton.frame = CGRect(x: 16, y: detailsLabel.frame.maxY + 10, width: detailsView.bounds.width - 32, height: 46)
        } else {
            detailsView.isHidden = true
        }

        let tableTop = backButton.frame.maxY + 12
        let tableBottom = detailsView.isHidden ? (safeBottom + 8) : detailsView.frame.height
        tableView.frame = CGRect(
            x: 0,
            y: tableTop,
            width: view.bounds.width,
            height: max(0, view.bounds.height - tableTop - tableBottom)
        )
    }

    private func resetSelectionState() {
        guard !adminPage, !isMapFlow else { return }
        selectedVenueIndex = nil
        detailsLabel.text = "Select a venue to see details here."
        continueButton?.isEnabled = false
        continueButton?.backgroundColor = UIColor(white: 0.70, alpha: 1)
        tableView?.indexPathForSelectedRow.map { tableView?.deselectRow(at: $0, animated: false) }
    }

    @objc func navigateBack() {
        dismiss(animated: false, completion: nil)
    }

    @objc func navigateToVenue(button _: UIButton, event _: UIEvent) {
        performSegue(withIdentifier: "goto_venues_details", sender: self)
    }

    @objc private func continueToVenueDetails() {
        guard let selectedVenueIndex, selectedVenueIndex < tableData.count else { return }
        let selectedIndexPath = IndexPath(row: selectedVenueIndex, section: 0)
        tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
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
      //  if isMapFlow, !LocationsDataManager.shared.locationsToDisplay.isEmpty {
      //      LocationsDataManager.shared.locationsForMapPicker = LocationsDataManager.shared.locationsToDisplay
      //      tableView?.reloadData()
      //      return
      //  }

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
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "CELL")
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .white
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.layer.masksToBounds = true
        cell.tag = indexPath.row
        cell.imageView?.layer.cornerRadius = 8
        cell.imageView?.clipsToBounds = true

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
                cell.textLabel?.attributedText = mutableAttributedString
                cell.detailTextLabel?.text = data_?.address

            } else {
                let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
                let detailText = NSMutableAttributedString(string: (data_?.title!)!, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

                cell.textLabel?.attributedText = detailText
                //   cell!.detailTextLabel?.text = data_?.address
            }

        } else {
            // TableData.sort { ($0.title ?? "") < ($1.title ?? "")}
            let data = tableData[indexPath.row]

            let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
            let detailText = NSMutableAttributedString(string: data.name, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

            cell.textLabel?.attributedText = detailText
            cell.detailTextLabel?.text = data.address
            cell.detailTextLabel?.textColor = UIColor.black.withAlphaComponent(0.65)
            cell.accessoryType = .disclosureIndicator

            let urlString = URLManager.image(data.venuesPicture)

            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let imgData = try await self.appServices.images.getData(urlString: urlString, realmCache: true)
                    let image = UIImage(data: imgData)
                    if let updatedCell = tableView.cellForRow(at: indexPath) {
                        guard updatedCell.tag == indexPath.row else { return }
                        updatedCell.imageView?.image = image
                        updatedCell.setNeedsLayout()
                    }
                } catch {
                    NSLog("VenuesVC cell image: %@", error.localizedDescription)
                }
            }
        }

        return cell
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
            selectedVenueIndex = indexPath.row
            detailsLabel.text = "📍 Venue: \(data.name)\n🏠 Address: \(data.address)"
            continueButton.isEnabled = true
            continueButton.backgroundColor = .black
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
