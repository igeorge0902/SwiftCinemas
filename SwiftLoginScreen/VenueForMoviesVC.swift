//
//  VenueForMoviesVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 14/08/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import SwiftyJSON
import UIKit

var ScreeningDates: [DatesData] = .init()
class VenueForMoviesVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    deinit {
        print(#function, "\(self)")
    }

    var venuesId: Int!
    var selectDetails: String!
    var venues_picture: String!
    var locationId: Int!

    var TableData: [MoviesData] = .init()
    var searchController: UISearchController!
    var shouldShowSearchResults = false

    var running = false

    // local
    var VenueData: [datastruct] = .init()

    struct datastruct {
        var venuesId: Int!
        var name: String!
        var address: String!
        var venues_picture: String!
        var screen_screenId: String!
        var image: UIImage?

        init(add: NSDictionary) {
            venuesId = (add["venuesId"] as! Int)
            name = (add["name"] as! String)
            address = (add["address"] as! String)
            venues_picture = (add["venues_picture"] as! String)
            screen_screenId = (add["screen_screenId"] as! String)
        }
    }

    var refreshControl: UIRefreshControl!
    var collectionView: UICollectionView!

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_venues_details2" {
            let nextSegue = segue.destination as? VenuesDetailsVC
            if let indexPath = collectionView.indexPathsForSelectedItems?.first {
                let data = TableData[indexPath.row]
                let venueData = VenueData[indexPath.row]

                nextSegue?.selectVenues_picture = venueData.venues_picture
                nextSegue?.selectVenueId = venueData.venuesId
                nextSegue?.venueName = venueData.name
                nextSegue?.movieId = data.movieId
                nextSegue?.movieName = data.name
                nextSegue?.movieDetails = data.detail
                nextSegue?.selectLarge_picture = data.large_picture
                nextSegue?.iMDB = data.imdb
                nextSegue?.locationId = locationId
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
        addData()
        // self.addDatesData()
    }

    @objc func navigateBack() {
        dismiss(animated: true, completion: nil)
    }

    func addData() {
        TableData.removeAll()
        VenueData.removeAll()

        var errorOnLogin: GeneralRequestManager?

        errorOnLogin = GeneralRequestManager(url: URLManager.mbooks("/venue/movies"), errors: "", method: "GET", headers: nil, queryParameters: ["locationId": String(locationId)], bodyParameters: nil, isCacheable: nil, contentType: "", bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            if let list = json["movies"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        self.TableData.append(MoviesData(add: dataBlock))
                    }
                }
            }

            if let list = json["venue"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        self.VenueData.append(datastruct(add: dataBlock))
                    }
                }
            }

            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    func addDatesData() {
        var errorOnLogin: GeneralRequestManager?

        errorOnLogin = GeneralRequestManager(url: URLManager.mbooks("/dates/" + String(2) + "/" + String(1002)), errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: nil, contentType: "", bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            if let list = json["dates"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        ScreeningDates.append(DatesData(add: dataBlock))
                    }
                }
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
        let searchString = searchController.searchBar.text

        // TODO: call API for fulltextSearch
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        TableData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath) as! MovieCollectionViewCell

        let data = TableData[indexPath.row]

        // Add text into the cell
        cell.textLabel.text = data.name

        let urlString = URLManager.image(data.large_picture ?? "")

        if let url = URL(string: urlString) {
            var loadPictures: GeneralRequestManager?
            loadPictures = GeneralRequestManager(url: urlString, errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: "1", contentType: "", bodyToPost: nil)

            loadPictures?.getData_ { (data: Data, _: NSError?) in
                let image = UIImage(data: data)
                cell.imageView.image = image
            }
        }

        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt _: IndexPath) {
        performSegue(withIdentifier: "goto_venues_details2", sender: self)
    }
}
