// VenuesVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import MapKit
import SwiftyJSON
import UIKit

class VenuesVC: UIViewController, UITableViewDataSource, UITableViewDelegate, HasAppServices {
    // MARK: Lifecycle

    deinit {
        adminPage = false
        print(#function, "\(self)")
    }

    // MARK: Internal

    var appServices: AppServices!
    var movieId: Int!
    var movieName: String!
    var selectLarge_picture: String!
    var selectDetails: String!
    var selectVenues_picture: String!
    var imdb: String!

    /// Old flow used mapViewPage global; keep equivalent as per-instance state.
    var openedFromMapFlow: Bool = false

    var tableData: [VenueModel] = []

    var mapView: MKMapView?
    var handleMapSearchDelegate: HandleMapSearch?

    var tableView: UITableView!
    var detailsView: UIView!
    var detailsLabel: UILabel!
    var continueButton: UIButton!

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_venues_details" {
            if let selectedVenueIndex, selectedVenueIndex < tableData.count {
                VenuesDataManager.shared.selectedVenue = tableData[selectedVenueIndex]
            } else if let indexPath = tableView?.indexPathForSelectedRow,
                      indexPath.row < tableData.count
            {
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Keep map caches while MapViewController is alive; it owns lifecycle reset.
        if !isMapFlow {
            LocationsDataManager.shared.locationsForMapPicker.removeAll()
            LocationsDataManager.shared.locationsToDisplay.removeAll()
        }
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "CELL")
        cell.selectionStyle = .none
        cell.backgroundColor = .white
        cell.contentView.backgroundColor = .white
        cell.contentView.layer.cornerRadius = 0
        cell.contentView.layer.masksToBounds = false
        cell.tag = indexPath.row
        cell.imageView?.layer.cornerRadius = 8
        cell.imageView?.clipsToBounds = true

        if adminPage || isMapFlow {
            sortVenueRowsForAdminFlows()

            let data_: Location? = if isMapFlow {
                mapFlowRows[indexPath.row]
            } else {
                LocationsDataManager.shared.locationsToDisplay[indexPath.row]
            }

            var s = ""
            if originalVenueName != nil {
                s = (originalVenueName.string as NSString) as String
            }

            let currentTitle = data_?.title ?? ""
            let isOriginal = currentTitle == s
            let isSelected = currentTitle == adminSelectedVenueTitle
            let font = UIFont(name: "Courier New", size: 13.0) ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
            let selectedFont = UIFont(name: "Courier New", size: 13.0) ?? .monospacedSystemFont(ofSize: 13, weight: .semibold)
            let mutableAttributedString = NSMutableAttributedString(
                string: currentTitle,
                attributes: [.font: isSelected ? selectedFont : font, .foregroundColor: isSelected ? UIColor.black : UIColor.darkGray]
            )

            cell.textLabel?.attributedText = mutableAttributedString
            cell.textLabel?.font = UIFont(name: "Courier New", size: 12.0) ?? .monospacedSystemFont(ofSize: 12, weight: .regular)
            let marker = isOriginal ? "(original)" : (isSelected ? "(new selection)" : "")
            let statusLine = marker.isEmpty ? "" : "\(marker) |"
            if let data_, expandedAdminVenueIds.contains(data_.locationId) {
                cell.detailTextLabel?.text = "\(statusLine)\ninfo: \(data_.address)"
                cell.detailTextLabel?.numberOfLines = 3
            } else {
                cell.detailTextLabel?.text = statusLine
                cell.detailTextLabel?.numberOfLines = 1
            }
            cell.detailTextLabel?.font = .systemFont(ofSize: 10, weight: .regular)
            cell.detailTextLabel?.lineBreakMode = .byTruncatingTail
            cell.detailTextLabel?.textColor = VenueUIStyle.detailText
            // Keep selection highlight on the whole row, including accessory area.
            applyRowSelectionBackground(cell, isSelected: isSelected)
            cell.accessoryType = .none
            cell.accessoryView = makeVenueAccessory(capacity: data_?.capacity, isSelected: isSelected)

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

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if adminPage {
            return isExpandedAdminRow(indexPath) ? expandedAdminRowHeight : compactRowHeight
        }
        if isMapFlow {
            return compactRowHeight
        }
        return standardVenueRowHeight
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if adminPage, tableData.isEmpty {
            let selectedVenue = LocationsDataManager.shared.locationsToDisplay[indexPath.row]
            adminSelectedVenueTitle = selectedVenue.title
            LocationsDataManager.shared.applySelection(selectedVenue, notificationName: "newScreenVenueSelected")
            tableView.reloadData()

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

    // MARK: Private

    private enum VenueUIStyle {
        static let selectedRowBackground = UIColor(white: 0.95, alpha: 1)
        static let defaultRowBackground = UIColor.white
        static let accessoryChipBackground = UIColor(white: 0.94, alpha: 1)
        static let accessoryChipBorder = UIColor(white: 0.85, alpha: 1)
        static let accessoryText = UIColor(white: 0.35, alpha: 1)
        static let detailText = UIColor(white: 0.40, alpha: 1)
        static let disabledButtonBackground = UIColor(white: 0.70, alpha: 1)
    }

    private let compactRowHeight: CGFloat = 60
    private let expandedAdminRowHeight: CGFloat = 94
    private let standardVenueRowHeight: CGFloat = 94

    private var backButton: UIButton!
    private var selectedVenueIndex: Int?
    private var adminSelectedVenueTitle: String?
    private var expandedAdminVenueIds = Set<Int>()
    private var hasConfiguredStaticUI = false

    private var isMapFlow: Bool {
        openedFromMapFlow || LocationsDataManager.shared.isVenuesFromMapFlow
    }

    private var mapFlowRows: [Location] {
        if !LocationsDataManager.shared.locationsForMapPicker.isEmpty {
            return LocationsDataManager.shared.locationsForMapPicker
        }
        return LocationsDataManager.shared.locationsToDisplay
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
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 2, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = compactRowHeight
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleAdminVenueLongPress(_:)))
        longPress.minimumPressDuration = 0.35
        tableView.addGestureRecognizer(longPress)
        view.addSubview(tableView)
    }

    @objc private func handleAdminVenueLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              adminPage,
              let tableView,
              let indexPath = tableView.indexPathForRow(at: gesture.location(in: tableView)),
              indexPath.row < LocationsDataManager.shared.locationsToDisplay.count else { return }

        let location = LocationsDataManager.shared.locationsToDisplay[indexPath.row]
        if expandedAdminVenueIds.contains(location.locationId) {
            expandedAdminVenueIds.remove(location.locationId)
        } else {
            expandedAdminVenueIds.insert(location.locationId)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        tableView.reloadRows(at: [indexPath], with: .none)
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
        continueButton.backgroundColor = VenueUIStyle.disabledButtonBackground
        continueButton.layer.cornerRadius = 12
        continueButton.isEnabled = false
        continueButton.addTarget(self, action: #selector(continueToVenueDetails), for: .touchUpInside)

        detailsView.addSubview(detailsLabel)
        detailsView.addSubview(continueButton)
        view.addSubview(detailsView)
    }

    private func layoutStaticUI() {
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
        continueButton?.backgroundColor = VenueUIStyle.disabledButtonBackground
        tableView?.indexPathForSelectedRow.map { tableView?.deselectRow(at: $0, animated: false) }
    }

    @objc private func continueToVenueDetails() {
        guard let selectedVenueIndex, selectedVenueIndex < tableData.count else { return }
        let selectedIndexPath = IndexPath(row: selectedVenueIndex, section: 0)
        tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
        performSegue(withIdentifier: "goto_venues_details", sender: self)
    }

    private func sortVenueRowsForAdminFlows() {
        LocationsDataManager.shared.locationsToDisplay.sort { ($0.title ?? "") < ($1.title ?? "") }
        LocationsDataManager.shared.locationsForMapPicker.sort { ($0.title ?? "") < ($1.title ?? "") }
    }

    private func isExpandedAdminRow(_ indexPath: IndexPath) -> Bool {
        guard adminPage else { return false }
        sortVenueRowsForAdminFlows()
        guard indexPath.row < LocationsDataManager.shared.locationsToDisplay.count else { return false }
        let location = LocationsDataManager.shared.locationsToDisplay[indexPath.row]
        return expandedAdminVenueIds.contains(location.locationId)
    }

    private func applyRowSelectionBackground(_ cell: UITableViewCell, isSelected: Bool) {
        let background = isSelected ? VenueUIStyle.selectedRowBackground : VenueUIStyle.defaultRowBackground
        cell.backgroundColor = background
        cell.contentView.backgroundColor = background
    }

    private func makeVenueAccessory(capacity: Int?, isSelected: Bool) -> UIView {
        let capacityLabel = UILabel()
        capacityLabel.text = "capacity \(capacity.map(String.init) ?? "n/a")"
        capacityLabel.font = .systemFont(ofSize: 10, weight: .regular)
        capacityLabel.textColor = VenueUIStyle.accessoryText
        capacityLabel.backgroundColor = VenueUIStyle.accessoryChipBackground
        capacityLabel.layer.borderWidth = 1
        capacityLabel.layer.borderColor = VenueUIStyle.accessoryChipBorder.cgColor
        capacityLabel.layer.cornerRadius = 10
        capacityLabel.layer.masksToBounds = true
        capacityLabel.textAlignment = .center
        capacityLabel.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 108, height: 24))
        container.backgroundColor = isSelected ? VenueUIStyle.selectedRowBackground : VenueUIStyle.defaultRowBackground
        container.addSubview(capacityLabel)

        NSLayoutConstraint.activate([
            capacityLabel.heightAnchor.constraint(equalToConstant: 20),
            capacityLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 84),
            capacityLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            capacityLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        return container
    }
}

/// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    input.rawValue
}

/// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
