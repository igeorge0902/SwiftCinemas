// VenueForMoviesVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import UIKit

class VenueForMoviesVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating, UISearchBarDelegate, HasAppServices {
    // MARK: Lifecycle

    deinit {
        print(#function, "\(self)")
    }

    // MARK: Internal

    var appServices: AppServices!
    var venuesId: Int!
    var venues_picture: String!
    var locationId: Int!

    var tableData: [VenueMovieSelection] = []
    var searchController: UISearchController!
    var shouldShowSearchResults = false

    var refreshControl: UIRefreshControl!
    var collectionView: UICollectionView!

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_venues_details2" {
            if let indexPath = collectionView.indexPathsForSelectedItems?.first {
                let selection = tableData[indexPath.row]

                MoviesDataManager.shared.selectedMovie = selection.movie
                VenuesDataManager.shared.selectedVenue = Venue(
                    venuesId: selection.venue.venuesId,
                    name: selection.venue.name,
                    address: selection.venue.address,
                    venuesPicture: selection.venue.venuesPicture,
                    screenId: selection.venue.screenId,
                    locationId: locationId
                )
                LocationsDataManager.shared.selectedLocationId = locationId
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        injectAppServicesIfNeeded()
        view.backgroundColor = .white

        backButton = makeTopNavigationButton(title: "‹ Back", action: #selector(VenueForMoviesVC.navigateBack))
        view.addSubview(backButton)

        // Initialize and set up the search controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search in Title and Description..."
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.backgroundColor = .white
        definesPresentationContext = true
        searchController.searchBar.sizeToFit()

        let searchBarFrame = UIView(frame: .zero)
        searchBarFrame.backgroundColor = .white
        searchBarFrame.translatesAutoresizingMaskIntoConstraints = false
        searchBarFrame.addSubview(searchController.searchBar)
        view.addSubview(searchBarFrame)

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)

        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: "CELL")
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true

        view.addSubview(collectionView)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        searchController.searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),

            searchBarFrame.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBarFrame.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBarFrame.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8),
            searchBarFrame.heightAnchor.constraint(equalToConstant: 44),

            searchController.searchBar.leadingAnchor.constraint(equalTo: searchBarFrame.leadingAnchor),
            searchController.searchBar.trailingAnchor.constraint(equalTo: searchBarFrame.trailingAnchor),
            searchController.searchBar.topAnchor.constraint(equalTo: searchBarFrame.topAnchor),
            searchController.searchBar.bottomAnchor.constraint(equalTo: searchBarFrame.bottomAnchor),

            collectionView.topAnchor.constraint(equalTo: searchBarFrame.bottomAnchor, constant: 6),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewWillAppear(_: Bool) {
        if locationId == nil {
            locationId = LocationsDataManager.shared.selectedLocationId
        }
        addData()
        // self.addDatesData()
    }

    @objc func navigateBack() {
        dismiss(animated: true, completion: nil)
    }

    func addData() {
        tableData.removeAll()

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                self.tableData = try await VenuesDataManager.shared.fetchVenueMovieSelections(locationId: String(self.locationId ?? 0))
                self.collectionView.reloadData()
            } catch {
                NSLog("VenueForMoviesVC addData: %@", error.localizedDescription)
            }
        }
    }

    func searchBarTextDidBeginEditing(_: UISearchBar) {
        shouldShowSearchResults = true
        collectionView.reloadData()
    }

    func searchBarCancelButtonClicked(_: UISearchBar) {
        shouldShowSearchResults = false
        collectionView.reloadData()
    }

    func searchBarSearchButtonClicked(_: UISearchBar) {
        if !shouldShowSearchResults {
            shouldShowSearchResults = true
            collectionView.reloadData()
        }

        searchController.searchBar.resignFirstResponder()
    }

    func updateSearchResults(for searchController: UISearchController) {
        _ = searchController.searchBar.text

        // TODO: call API for fulltextSearch
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        tableData.count
    }

    func collectionView(_: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: view.bounds.width - 24, height: 92)
        }
        let horizontalInsets = layout.sectionInset.left + layout.sectionInset.right
        return CGSize(width: max(0, collectionView.bounds.width - horizontalInsets), height: 92)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath) as! MovieCollectionViewCell

        let display = makeDisplayRow(from: tableData[indexPath.row])
        cell.configureRedesign(
            title: display.title,
            category: display.categoryText,
            screeningDate: display.screeningDateText
        )
        cell.representedImagePath = display.imagePath
        cell.imageView.image = UIImage(systemName: "film")

        let imagePath = display.imagePath
        let urlString = URLManager.image(imagePath)

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let imgData = try await self.appServices.images.getData(urlString: urlString, realmCache: true)
                guard let updatedCell = collectionView.cellForItem(at: indexPath) as? MovieCollectionViewCell,
                      updatedCell.representedImagePath == imagePath else { return }
                updatedCell.imageView.image = UIImage(data: imgData)
            } catch {
                NSLog("VenueForMoviesVC image: %@", error.localizedDescription)
            }
        }

        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt _: IndexPath) {
        performSegue(withIdentifier: "goto_venues_details2", sender: self)
    }

    // MARK: Private

    private struct VenueMovieRowDisplay {
        let title: String
        let imagePath: String
        let categoryText: String
        let screeningDateText: String
    }

    private var backButton: UIButton!

    private func makeDisplayRow(from selection: VenueMovieSelection) -> VenueMovieRowDisplay {
        let category = (selection.category?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? selection.category!
            : "N/A"
        let screeningDate = (selection.screeningDate?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? selection.screeningDate!
            : "TBA"

        return VenueMovieRowDisplay(
            title: selection.movie.name,
            imagePath: selection.movie.largePicture,
            categoryText: "Category: \(category)",
            screeningDateText: "Date: \(screeningDate)"
        )
    }
}
