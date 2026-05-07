//
//  VenueForMoviesVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 14/08/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import UIKit

class VenueForMoviesVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchResultsUpdating, UISearchBarDelegate, HasAppServices {
    var appServices: AppServices!
    deinit {
        print(#function, "\(self)")
    }

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

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.setTitle("Back", for: UIControl.State())
        btnNav.showsTouchWhenHighlighted = true
        btnNav.addTarget(self, action: #selector(VenueForMoviesVC.navigateBack), for: UIControl.Event.touchUpInside)

        view.addSubview(btnNav)

        // Initialize and set up the search controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search in Title and Description..."
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchBarStyle = .minimal
        definesPresentationContext = true
        searchController.searchBar.sizeToFit()

        let searchBarFrame = UIView(frame: CGRect(x: 0.0, y: 50, width: view.frame.width, height: 44))
        searchBarFrame.addSubview(searchController.searchBar)
        view.addSubview(searchBarFrame)

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.size.width / 2 - 10, height: view.frame.size.width / 2)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: "CELL")

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
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

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath) as! MovieCollectionViewCell

        let data = tableData[indexPath.row].movie

        // Add text into the cell
        cell.textLabel.text = data.name

        let urlString = URLManager.image(data.largePicture)

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let imgData = try await self.appServices.images.getData(urlString: urlString, realmCache: true)
                cell.imageView.image = UIImage(data: imgData)
            } catch {
                NSLog("VenueForMoviesVC image: %@", error.localizedDescription)
            }
        }

        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt _: IndexPath) {
        performSegue(withIdentifier: "goto_venues_details2", sender: self)
    }
}
