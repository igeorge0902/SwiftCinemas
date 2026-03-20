//
//  MoviesVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 30/05/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import AVFoundation
import SwiftyJSON
import UIKit

// data modell for updating Screen
var ScreenData_2: [Admin_ScreenData] = .init()

var TableData_: [MoviesData] = .init()
var endOfFile = false
var veil = true
var shouldShowSearchResults = false
class MoviesVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    deinit {
        endOfFile = false
        TableData.removeAll()
        adminPage = false
        adminUpdatePage = false
        print(#function, "\(self)")
    }

    var SearchData: [MoviesData] = .init()
    var TableData: [MoviesData] = .init()
//    var ScreenData_: [datastruct] = [datastruct]()
    var CategoryData = [String]()
    var data: MoviesData?
    var venueData: Admin_ScreenData?
    var searchController: UISearchController?
    lazy var session = URLSession.sharedCustomSession

    var refreshControl: UIRefreshControl!
    var tableView: UITableView?
    lazy var section_: Int = 0
    var category_: String?
    var searchString: String?

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goto_venues" {
            let nextSegue = segue.destination as? VenuesVC

            if let indexPath = tableView!.indexPathForSelectedRow {
                var data: MoviesData

                if TableData.count > 0 {
                    data = TableData[indexPath.section]

                    nextSegue!.movieId = data.movieId
                    nextSegue!.movieName = data.name
                    nextSegue!.selectDetails = data.detail
                    nextSegue!.selectLarge_picture = data.large_picture
                    nextSegue!.imdb = data.imdb
                }
                if SearchData.count > 0 {
                    data = SearchData[indexPath.section]

                    nextSegue!.movieId = data.movieId
                    nextSegue!.movieName = data.name
                    nextSegue!.selectDetails = data.detail
                    nextSegue!.selectLarge_picture = data.large_picture
                    nextSegue!.imdb = data.imdb
                }
            }
        }
        if segue.identifier == "goto_movie_detail" {
            let nextSegue = segue.destination as? MovieDetailVC
            guard let tag = (sender as? UIButton)?.tag else { return }
            var data: MoviesData

            if TableData.count > 0 {
                data = TableData[tag]

                nextSegue!.movieId = data.movieId
                nextSegue!.movieName = data.name
                nextSegue!.selectDetails = data.detail
                nextSegue!.selectLarge_picture = data.large_picture
                nextSegue!.iMDB = data.imdb
            }
            if SearchData.count > 0 {
                data = SearchData[tag]

                nextSegue!.movieId = data.movieId
                nextSegue!.movieName = data.name
                nextSegue!.selectDetails = data.detail
                nextSegue!.selectLarge_picture = data.large_picture
                nextSegue!.iMDB = data.imdb
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        veil = true
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.delegate = self
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.searchBar.placeholder = "Search in Title and Description..."
        searchController?.searchBar.autocapitalizationType = .none
        searchController?.searchBar.searchBarStyle = .minimal
        definesPresentationContext = true

        searchController?.searchBar.sizeToFit()

        let searchBarFrame = UIView(frame: CGRect(x: 0.0, y: 50, width: view.frame.width, height: 44))
        searchBarFrame.addSubview(searchController!.searchBar)
        view.addSubview(searchBarFrame)

        NotificationCenter.default.addObserver(self, selector: #selector(navigateBack), name: NSNotification.Name(rawValue: "navigateBack"), object: nil)
    }

    override func viewWillAppear(_: Bool) {
        let frame = CGRect(x: 0, y: 100, width: view.frame.width, height: view.frame.height - 100)
        tableView = UITableView(frame: frame)
        tableView?.dataSource = self
        tableView?.delegate = self
        view.addSubview(tableView!)

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.setTitle("Back", for: UIControl.State())
        btnNav.showsTouchWhenHighlighted = true
        btnNav.addTarget(self, action: #selector(MoviesVC.navigateBack), for: UIControl.Event.touchUpInside)

        view.addSubview(btnNav)

        if adminUpdatePage == true {
            TableData.removeAll()
            addLoadMoviesonVenue()
        } else {
            addData(category: "nil")
        }
    }

    @objc func navigateBack() {
        if veil {
            dismiss(animated: true, completion: nil)
        }
        veil = false
        dismiss(animated: true, completion: nil)
    }

    /// Returns a categorized list of movies with paging by 30 results.
    ///
    /// - Parameters:
    ///   - category: Name of the category.
    /// - Returns: list of ``MoviesData`` objects.
    func addData(category: String) {
        var errorOnLogin: GeneralRequestManager?
        var setFirstResult: Int?
        var query: [String: String]?

        if category != "nil" {
            query = ["category": category, "setFirstResult": String(TableData.count)]
        } else if TableData.count > 0, category == "nil" {
            setFirstResult = TableData.count
            query = ["setFirstResult": String(setFirstResult!)]
        } else {
            setFirstResult = 0
            query = ["setFirstResult": String(setFirstResult!)]
        }

        errorOnLogin = GeneralRequestManager(url: URLManager.mbooks("/movies/paging"), errors: "", method: "GET", headers: nil, queryParameters: query, bodyParameters: nil, isCacheable: "1", contentType: "", bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            if let list = json["movies"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        self.TableData.append(MoviesData(add: dataBlock))
                    }
                }
            }

            if let _ = json["NotFoundMovies"].string as NSString? {
                endOfFile = true
            }
            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
    }

    func addLoadMoviesonVenue(category: String) {
        // TableData.removeAll()

        var errorOnLogin: GeneralRequestManager?
        var query: [String: String]?

        if category != "nil" {
            query = ["category": category]
        }

        errorOnLogin = GeneralRequestManager(url: URLManager.mbooks("/admin/moviesonvenuescategorized"), errors: "", method: "GET", headers: nil, queryParameters: query, bodyParameters: nil, isCacheable: "1", contentType: "", bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            if let list = json["venues"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        ScreenData_2.append(Admin_ScreenData(add: dataBlock))
                    }
                }
            }
            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
    }

    func addLoadMoviesonVenue(search: String) {
        // TableData.removeAll()

        var errorOnLogin: GeneralRequestManager?
        var query: [String: String]?
        query = ["match": search]

        errorOnLogin = GeneralRequestManager(url: URLManager.mbooks("/admin/moviesonvenuessearch"), errors: "", method: "GET", headers: nil, queryParameters: query, bodyParameters: nil, isCacheable: "1", contentType: "", bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            if let list = json["venues"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        ScreenData_2.append(Admin_ScreenData(add: dataBlock))
                    }
                }
            }
            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
    }

    func addData_(_ match: String, category: String) {
        SearchData.removeAll()
        var errorOnLogin: GeneralRequestManager?
        var setFirstResult: Int?
        var query: [String: String]?

        if SearchData.count > 0, category != "nil" {
            setFirstResult = SearchData.count
            query = ["match": match, "setFirstResult": String(setFirstResult!), "category": category]
        } else if SearchData.count > 0, category == "nil" {
            setFirstResult = SearchData.count
            query = ["match": match, "setFirstResult": String(setFirstResult!)]
        } else if SearchData.count == 0, category != "nil" {
            setFirstResult = SearchData.count
            query = ["match": match, "setFirstResult": String(setFirstResult!), "category": category]
        } else if SearchData.count == 0, category == "nil" {
            setFirstResult = SearchData.count
            query = ["match": match, "setFirstResult": String(setFirstResult!)]
        }

        errorOnLogin = GeneralRequestManager(url: URLManager.mbooks("/movies/search"), errors: "", method: "GET", headers: nil, queryParameters: query, bodyParameters: nil, isCacheable: nil, contentType: "", bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            if let list = json["searchedMovies"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        self.SearchData.append(MoviesData(add: dataBlock))
                        shouldShowSearchResults = true
                    }
                }
            }

            if let _ = json["NotFoundMovies"].string as NSString? {
                // TODO: present empty list
                endOfFile = true
            }

            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
    }

    @objc func addLoadMoviesonVenue() {
        ScreenData_2.removeAll()
        var errorOnLogin: GeneralRequestManager?

        errorOnLogin = GeneralRequestManager(url: URLManager.mbooks("/admin/moviesonvenues"), errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: nil, contentType: contentType_.json.rawValue, bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            if let list = json["venues"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        ScreenData_2.append(Admin_ScreenData(add: dataBlock))
                    }
                }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "venueSelected"), object: nil)
            }
            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
    }

    func searchBarTextDidBeginEditing(_: UISearchBar) {
        shouldShowSearchResults = true
        // self.tableView!.reloadData()
    }

    func searchBarShouldEndEditing(_: UISearchBar) -> Bool {
        // self.searchController!.searchBar.isHidden = true;
        searchController?.searchBar.resignFirstResponder()
        return true
    }

    func searchBarCancelButtonClicked(_: UISearchBar) {
        shouldShowSearchResults = true
        searchController?.searchBar.resignFirstResponder()
    }

    func searchBarTextDidEndEditing(_: UISearchBar) {
        shouldShowSearchResults = true
        searchController?.searchBar.resignFirstResponder()
    }

    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        if searchText.substring(from: searchText.startIndex).count > 2 {
            TableData.removeAll()
            SearchData.removeAll()
            if !adminUpdatePage {
                let backgroundQueue = DispatchQueue.global()
                let deadline = DispatchTime.now() + .milliseconds(100)
                backgroundQueue.asyncAfter(deadline: deadline, qos: .background) {
                    if self.section_ == 0 {
                        self.addData_(searchText, category: "nil")
                    } else if self.section_ == 1 {
                        self.addData_(searchText, category: self.category_!)
                    }
                }
            }
            if adminUpdatePage {
                ScreenData_2.removeAll()
                if section_ == 0 {
                    addLoadMoviesonVenue(search: searchText)
                } else if section_ == 1 {
                    addLoadMoviesonVenue(search: searchText)
                }
            }
        }
        if searchText.substring(from: searchText.startIndex).count == 0 {
            SearchData.removeAll()
            TableData.removeAll()

            if !adminUpdatePage {
                addData(category: category_ ?? "nil")
                tableView!.reloadData()
            }

            if adminUpdatePage {
                addLoadMoviesonVenue()
                tableView?.reloadData()
            }
        }
        shouldShowSearchResults = true
    }

    func updateSearchResults(for searchController: UISearchController) {
        searchString = searchController.searchBar.text
        print(searchString!)
    }

    func searchDisplayController(_: UISearchController, shouldReloadTableForSearchString _: NSString) {}

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50)) // Set header height

        let control = UISegmentedControl(items: ["Reset", "Categories", "NA"])
        control.frame = CGRect(x: 10, y: -20, width: headerView.frame.width - 20, height: 36) // Adjust control height
        control.backgroundColor = UIColor.darkGray
        control.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)

        headerView.addSubview(control)
        return section == 0 ? headerView : nil
    }

    @objc func valueChanged(_ segmentedControl: UISegmentedControl) {
        print("Coming in : \(segmentedControl.selectedSegmentIndex)")
        section_ = segmentedControl.selectedSegmentIndex
        if segmentedControl.selectedSegmentIndex == 0 {
            searchController?.searchBar.text = ""
            category_ = nil
            SearchData.removeAll()
            TableData.removeAll()
            CategoryData.removeAll()
            ScreenData_2.removeAll()
            if adminUpdatePage {
                addLoadMoviesonVenue()
            } else {
                addData(category: "nil")
            }
        } else if section_ == 1 {
            searchController?.searchBar.text = ""
            CategoryData = ["Action", "Drama", "Crime", "Romance", "Troll"]
            SearchData.removeAll()
            TableData.removeAll()
            ScreenData_2.removeAll()
            tableView!.reloadData()
        } else if segmentedControl.selectedSegmentIndex == 2 {}
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        if adminUpdatePage {
            return 60
        }
        if CategoryData.count > 0 {
            return 60
        }
        return 180.0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if CategoryData.count > 0 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "CELL")
            cell.textLabel?.text = CategoryData[indexPath.row]
            return cell
        }

        var cell = tableView.dequeueReusableCell(withIdentifier: "CELL") as? ListViewCell

        if cell == nil {
            cell = ListViewCell(style: .default, reuseIdentifier: "CELL")
        }

        var categories = ""

        // Define your data type here
        if adminUpdatePage {
            if ScreenData_2.count > 0 {
                venueData = ScreenData_2[indexPath.row]
            } else if TableData.count > 0 {
                data = TableData[indexPath.row]
            } else if SearchData.count > 0 {
                data = SearchData[indexPath.row]
            } else if CategoryData.count > 0 {
                categories = CategoryData[indexPath.row]
            }
        } else {
            if ScreenData_2.count > 0 {
                venueData = ScreenData_2[indexPath.section]
            } else if TableData.count > 0 {
                data = TableData[indexPath.section]
            } else if SearchData.count > 0 {
                data = SearchData[indexPath.section]
            } else if CategoryData.count > 0 {
                categories = CategoryData[indexPath.row]
            }
        }

        // Pass the information about whether to load image or not
        configureCell(cell: cell, with: data, venueData, categories: categories, indexPath: indexPath, shouldLoadImage: section_ != 1)

        return cell!
    }

    private func configureCell(cell: ListViewCell?, with data: MoviesData?, _: Admin_ScreenData?, categories: String?, indexPath _: IndexPath, shouldLoadImage: Bool) {
        guard let cell, let data else { return }

        if categories != "" {
            cell.textLabel?.text = categories
            cell.imageView?.image = nil
            return

        } else {
            // Set up text attributes
            let myTextAttribute: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Courier New", size: 13.0)!,
            ]
            let detailText = NSMutableAttributedString(string: data.name, attributes: myTextAttribute)

            // Configure cell appearance
            cell.titleText.attributedText = detailText
            cell.titleText.textColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? .black : .black
            }

            // Load image only if shouldLoadImage is true
            if shouldLoadImage {
                let urlString = URLManager.image(data.large_picture)
                if let url = URL(string: urlString) {
                    loadImage(from: url, for: cell)
                }
            } else {
                cell.imageView?.image = nil
            }
        }
        cell.textLabel?.numberOfLines = 3
    }

    private func loadImage(from url: URL, for cell: ListViewCell) {
        var loadPictures: GeneralRequestManager?
        loadPictures = GeneralRequestManager(url: url.absoluteString, errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: "1", contentType: "", bodyToPost: nil)

        loadPictures?.getData_ { (data: Data, _: NSError?) in
            if let image = UIImage(data: data) {
                 let resizedImage = image.resize(140, 140)

                DispatchQueue.main.async {
                    cell.movieImageView.image = image
                    cell.setNeedsLayout()
                }
            }
        }
    }

    private func addButtonToCell(cell: ListViewCell, at indexPath: IndexPath) {
        if let existingButton = cell.contentView.viewWithTag(indexPath.row) as? UIButton {
            return
        }

        let btn = UIButton(type: .custom)
        btn.frame = CGRect(x: cell.frame.width - 30, y: 15, width: 20, height: 30)
        btn.addTarget(self, action: #selector(MoviesVC.movieDetail), for: .touchUpInside)
        btn.tag = indexPath.row // Set the tag to identify the button later
        btn.setImage(UIImage(named: "window-7.png"), for: .normal)
        cell.contentView.addSubview(btn)
    }

    func numberOfSections(in _: UITableView) -> Int {
        if adminUpdatePage {
            return 1

        } else {
            if SearchData.count > 0 {
                return SearchData.count
            }
            if CategoryData.count > 0 {
                return 1
            }
            if ScreenData_2.count > 0 {
                return ScreenData_2.count
            }
            return TableData.count
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        if adminUpdatePage {
            if SearchData.count > 0 {
                return SearchData.count
            }
            if CategoryData.count > 0 {
                return CategoryData.count
            }
            if ScreenData_2.count > 0 {
                return ScreenData_2.count
            }
            return TableData.count
        } else if section_ == 1 {
            if CategoryData.count > 0 {
                return CategoryData.count
            }
        } else {
            return 1
        }
        return 1
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        30
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        15
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchController!.searchBar.isHidden = false
        section_ = 0

        if adminPage, CategoryData.count == 0 {
            if TableData.count > 0 {
                addMovie = TableData[indexPath.section].name
            } else {
                addMovie = SearchData[indexPath.section].name
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newScreenMovieSelected"), object: nil)
        }

        if adminUpdatePage, CategoryData.count == 0 {
            if ScreenData_2.count > 0 {
                addMovie = ScreenData_2[indexPath.row].movie
                addVenue = ScreenData_2[indexPath.row].venue
                addScreeningID = ScreenData_2[indexPath.row].ScreeningId
                addScreeningDate = ScreenData_2[indexPath.row].date
                addScreeningDateId = ScreenData_2[indexPath.row].screeningDatesId
                addMovieId = ScreenData_2[indexPath.row].movieId
                addVenueId = ScreenData_2[indexPath.row].venueId
                addCategory = ScreenData_2[indexPath.row].category
            }

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "movieSelected"), object: nil)
        }

        if CategoryData.count > 0 {
            // select category
            category_ = CategoryData[indexPath.row]
            CategoryData.removeAll()
            TableData.removeAll()
            if !adminUpdatePage {
                addData(category: category_!)
            }
            if adminUpdatePage {
                // add admin movie:venue with category
                addLoadMoviesonVenue(category: category_!)
            }
        } else {
            if adminPage || adminUpdatePage {} else {
                if veil, shouldShowSearchResults {
                    dismiss(animated: true, completion: nil)
                }
                veil = false
                shouldShowSearchResults = false
                performSegue(withIdentifier: "goto_venues", sender: self)
            }
        }
    }

    func tableView(_: UITableView, willDisplay _: UITableViewCell, forRowAt indexPath: IndexPath) {
        searchController!.searchBar.isHidden = false

        if TableData.count > 10 || SearchData.count > 10 {
            if indexPath.section == TableData.count - 3 {
                if endOfFile == false {
                    addData(category: "nil")
                }
                if indexPath.section == SearchData.count - 3, section_ == 0, endOfFile == false {
                    addData_(searchString!, category: "nil")
                } else if indexPath.section == SearchData.count - 3, section_ == 1, endOfFile == false {
                    addData_(searchString!, category: category_!)
                }
            }
        }
        if adminUpdatePage {
            if TableData.count > 10 || SearchData.count > 10 {
                if indexPath.row == TableData.count - 3 {
                    if endOfFile == false {
                        addData(category: "nil")
                    }
                    if indexPath.row == SearchData.count - 3, section_ == 0, endOfFile == false {
                        addData_(searchString!, category: "nil")
                    } else if indexPath.row == SearchData.count - 3, section_ == 1, endOfFile == false {
                        addData_(searchString!, category: category_!)
                    }
                }
            }
        }
    }

    @objc func movieDetail(button: UIButton, event _: UIEvent) {
        if veil, shouldShowSearchResults {
            dismiss(animated: true, completion: nil)
        }
        veil = false
        shouldShowSearchResults = false
        performSegue(withIdentifier: "goto_movie_detail", sender: button)
    }
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

public extension UIImage {
    /// Resize image while keeping the aspect ratio. Original image is not modified.
    /// - Parameters:
    ///   - width: A new width in pixels.
    ///   - height: A new height in pixels.
    /// - Returns: Resized image.
    func resize(_ width: Int, _ height: Int) -> UIImage {
        // Keep aspect ratio
        let maxSize = CGSize(width: width, height: height)

        let availableRect = AVFoundation.AVMakeRect(
            aspectRatio: size,
            insideRect: .init(origin: .zero, size: maxSize)
        )
        let targetSize = availableRect.size

        // Set scale of renderer so that 1pt == 1px
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        // Resize the image
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resized
    }
}
