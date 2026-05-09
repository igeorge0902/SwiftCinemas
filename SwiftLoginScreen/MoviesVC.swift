//
//  MoviesVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 30/05/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import UIKit

// data modell for updating Screen
var ScreenData_2: [AdminScreeningModel] {
    get { AdminScreeningsDataManager.shared.screeningsForAdminUpdate }
    set { AdminScreeningsDataManager.shared.screeningsForAdminUpdate = newValue }
}

var endOfFile = false
var veil = true
var shouldShowSearchResults = false
class MoviesVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate, HasAppServices {
    var appServices: AppServices!
    deinit {
        endOfFile = false
        TableData.removeAll()
        adminPage = false
        adminUpdatePage = false
        print(#function, "\(self)")
    }

    var SearchData: [MovieDataModel] = []
    var TableData: [MovieDataModel] = []
//    var ScreenData_: [datastruct] = [datastruct]()
    var CategoryData = [String]()
    var searchController: UISearchController?
    var tableView: UITableView?
    lazy var section_: Int = 0
    var category_: String?
    var searchString: String?

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goto_venues",
           let indexPath = tableView?.indexPathForSelectedRow,
           let movie = selectedMovie(at: indexPath) {
            MoviesDataManager.shared.selectedMovie = movie
        }
        if segue.identifier == "goto_movie_detail",
           let tag = (sender as? UIButton)?.tag,
           tag < TableData.count || tag < SearchData.count {
            let movie = TableData.indices.contains(tag) ? TableData[tag] : SearchData[tag]
            MoviesDataManager.shared.selectedMovie = movie
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        injectAppServicesIfNeeded()

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
    /// - Returns: list of movie models.
    func addData(category: String) {
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

        Task { @MainActor [weak self] in
            guard let self, let query else { return }
            do {
                let movies = try await MoviesDataManager.shared.fetchPaging(query: query)
                self.TableData.append(contentsOf: movies)
                endOfFile = movies.isEmpty
                self.tableView?.reloadData()
            } catch {
                NSLog("addData: %@", error.localizedDescription)
            }
        }
    }

    func addLoadMoviesonVenue(category: String) {
        var query: [String: String]?

        if category != "nil" {
            query = ["category": category]
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                ScreenData_2 = try await AdminDataManager.shared.fetchScreenings(category: query?["category"])
                self.tableView?.reloadData()
            } catch {
                NSLog("addLoadMoviesonVenue(category): %@", error.localizedDescription)
            }
        }
    }

    func addLoadMoviesonVenue(search: String) {
        let query = ["match": search]

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                ScreenData_2 = try await AdminDataManager.shared.searchScreenings(match: search)
                self.tableView?.reloadData()
            } catch {
                NSLog("addLoadMoviesonVenue(search): %@", error.localizedDescription)
            }
        }
    }

    func addData_(_ match: String, category: String) {
        SearchData.removeAll()
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

        Task { @MainActor [weak self] in
            guard let self, let query else { return }
            do {
                self.SearchData = try await MoviesDataManager.shared.search(query: query)
                shouldShowSearchResults = true
                endOfFile = self.SearchData.isEmpty
                self.tableView?.reloadData()
            } catch {
                NSLog("addData_: %@", error.localizedDescription)
            }
        }
    }

    @objc func addLoadMoviesonVenue() {
        ScreenData_2.removeAll()

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                ScreenData_2 = try await AdminDataManager.shared.fetchScreenings()
                if !ScreenData_2.isEmpty {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "venueSelected"), object: nil)
                }
                self.tableView?.reloadData()
            } catch {
                NSLog("addLoadMoviesonVenue: %@", error.localizedDescription)
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
        var movieData: MovieDataModel?
        var adminRow: AdminScreeningModel?

        if adminUpdatePage {
            if ScreenData_2.count > 0 {
                adminRow = ScreenData_2[indexPath.row]
            } else if TableData.count > 0 {
                movieData = TableData[indexPath.row]
            } else if SearchData.count > 0 {
                movieData = SearchData[indexPath.row]
            } else if CategoryData.count > 0 {
                categories = CategoryData[indexPath.row]
            }
        } else {
            if ScreenData_2.count > 0 {
                adminRow = ScreenData_2[indexPath.section]
            } else if TableData.count > 0 {
                movieData = TableData[indexPath.section]
            } else if SearchData.count > 0 {
                movieData = SearchData[indexPath.section]
            } else if CategoryData.count > 0 {
                categories = CategoryData[indexPath.row]
            }
        }

        // Pass the information about whether to load image or not
        configureCell(cell: cell, with: movieData, adminRow, categories: categories, indexPath: indexPath, shouldLoadImage: section_ != 1)

        return cell!
    }

    private func configureCell(cell: ListViewCell?, with data: MovieDataModel?, _ venueData: AdminScreeningModel?, categories: String?, indexPath _: IndexPath, shouldLoadImage: Bool) {
        guard let cell else { return }

        let textAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Courier New", size: 13.0)!,
            .foregroundColor: UIColor.label,
        ]

        // ── Admin/update mode: show venue › movie rows from ScreenData_2 ──
        if adminUpdatePage, let venueData {
            cell.configureLayout(compact: true)
            let label = "\(venueData.venue ?? "") › \(venueData.movie ?? "")"
            cell.titleText.attributedText = NSAttributedString(string: label, attributes: textAttr)
            cell.movieImageView.image = nil
            return
        }

        // ── Category rows ──
        if let categories, !categories.isEmpty {
            cell.configureLayout(compact: true)
            cell.titleText.attributedText = NSAttributedString(string: categories, attributes: textAttr)
            cell.movieImageView.image = nil
            return
        }

        // ── Normal movie rows ──
        guard let data else { return }

        cell.configureLayout(compact: false)
        cell.titleText.attributedText = NSAttributedString(string: data.name, attributes: textAttr)

        if shouldLoadImage {
            let urlString = URLManager.image(data.largePicture)
            if let url = URL(string: urlString) {
                loadImage(from: url, for: cell)
            }
        } else {
            cell.movieImageView.image = nil
        }
    }

    private func loadImage(from url: URL, for cell: ListViewCell) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let data = try await self.appServices.images.getData(urlString: url.absoluteString, realmCache: true)
                if let image = UIImage(data: data) {
                    cell.movieImageView.image = image
                    cell.setNeedsLayout()
                }
            } catch {
                let errorMsg: String
                if let appError = error as? AppError {
                    errorMsg = appError.userMessage
                } else {
                    errorMsg = error.localizedDescription
                }
                NSLog("loadImage: %@ url=%@", errorMsg, url.absoluteString)
            }
        }
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
                addScreeningID = ScreenData_2[indexPath.row].screeningId
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
                if let movie = selectedMovie(at: indexPath) {
                    MoviesDataManager.shared.selectedMovie = movie
                }
                if VenuesFeatureFlags.shouldUseMigration(), let movie = selectedMovie(at: indexPath) {
                    presentVenuesMigration(for: movie)
                } else {
                    performSegue(withIdentifier: "goto_venues", sender: self)
                }
            }
        }
    }

    private func selectedMovie(at indexPath: IndexPath) -> MovieDataModel? {
        if TableData.count > 0 {
            return TableData[indexPath.section]
        }
        if SearchData.count > 0 {
            return SearchData[indexPath.section]
        }
        return nil
    }

    private func presentVenuesMigration(for movie: MovieDataModel) {
        injectAppServicesIfNeeded()

        let input = VenuesInput(
            movieId: movie.movieId,
            movieName: movie.name,
            selectLargePicture: movie.largePicture,
            selectDetails: movie.detail,
            imdb: movie.imdbUrl,
            mode: .admin
        )

        let migrationVC = VenuesMigrationFactory.make(input: input, mode: .standard, appServices: appServices)
        migrationVC.modalPresentationStyle = .fullScreen
        present(migrationVC, animated: true)
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

