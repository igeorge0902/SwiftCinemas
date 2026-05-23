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

    private enum PopoverUIStyle {
        static let selectedRowBackground = UIColor(white: 0.95, alpha: 1)
        static let defaultRowBackground = UIColor.white
        static let searchBorder = UIColor(white: 0.84, alpha: 1)
        static let chipTitle = UIColor(white: 0.2, alpha: 1)
        static let chipActiveBackground = UIColor(white: 0.90, alpha: 1)
        static let chipBackground = UIColor(white: 0.94, alpha: 1)
        static let chipBorder = UIColor(white: 0.86, alpha: 1)
    }

    deinit {
        endOfFile = false
        TableData.removeAll()
        adminPage = false
        adminUpdatePage = false
        print(#function, "\(self)")
    }

    var SearchData: [MovieDataModel] = []
    var TableData: [MovieDataModel] = []
    var CategoryData = [String]()
   // var searchController: UISearchController?
    private let searchBar = UISearchBar()
    var tableView: UITableView?
    var searchBarFrame: UIView?
    var categoryScrollView: UIScrollView?
    var categoryStack: UIStackView?
    lazy var section_: Int = 0
    var category_: String?
    var searchString: String?
    var categoryChips: [String] = []
    var favoritesByMovieId: [Int: Bool] = [:]
    var ratingsByMovieId: [Int: String] = [:]
    let fallbackCategories = ["All", "Action", "Drama", "Crime", "Romance", "Troll"]
    private var selectedPopoverMovieRow: Int?

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
        searchBar.delegate = self
        searchBar.placeholder = "Search in Title and Description..."
        searchBar.autocapitalizationType = .none
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundImage = UIImage()
        
        definesPresentationContext = true
        category_ = "nil"

        view.backgroundColor = .white

        loadRatingsFixture()

        let sbFrame = UIView(frame: CGRect(x: 12.0, y: 50, width: view.frame.width - 70, height: 40))
        sbFrame.backgroundColor = .white
        searchBar.frame = sbFrame.bounds
        sbFrame.addSubview(searchBar)
        
        styleSearchBarForPopover()
        sbFrame.layer.borderColor = PopoverUIStyle.searchBorder.cgColor
        sbFrame.layer.borderWidth = 1
        sbFrame.layer.cornerRadius = 8
        sbFrame.clipsToBounds = true
        view.addSubview(sbFrame)
        searchBarFrame = sbFrame

        let dismissTap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissSearchKeyboard)
        )

        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)

        buildCategoryChipsBar()

        NotificationCenter.default.addObserver(self, selector: #selector(navigateBack), name: NSNotification.Name(rawValue: "navigateBack"), object: nil)
    }

    override func viewWillAppear(_: Bool) {
        tableView?.removeFromSuperview()
        let frame = CGRect(x: 0, y: 136, width: view.frame.width, height: view.frame.height - 136)
        tableView = UITableView(frame: frame)
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.backgroundColor = .white
        tableView?.separatorStyle = .none
        view.addSubview(tableView!)

        addTopNavigationButtons([
            (title: "Back", action: #selector(MoviesVC.navigateBack)),
        ])

        resolveCategories(from: TableData)
        renderCategoryChips()

        if adminUpdatePage == true {
            TableData.removeAll()
            addLoadMoviesonVenue()
        } else {
            addData(category: "nil")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func applyPopoverRowSelection(_ cell: UITableViewCell, indexPath: IndexPath) {
        cell.contentView.backgroundColor = selectedPopoverMovieRow == indexPath.row
            ? PopoverUIStyle.selectedRowBackground
            : PopoverUIStyle.defaultRowBackground
    }

    private func selectPopoverMovieRow(_ indexPath: IndexPath) {
        selectedPopoverMovieRow = indexPath.row
        tableView?.reloadData()
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
                self.resolveCategories(from: self.TableData)
                self.renderCategoryChips()
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
                self.resolveCategories(from: self.SearchData)
                self.renderCategoryChips()
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

    func searchBarShouldBeginEditing(_: UISearchBar) -> Bool {
        DispatchQueue.main.async { [weak self] in
            self?.searchBar.becomeFirstResponder()
        }
        return true
    }

    @objc private func focusSearchBar() {
        searchBar.becomeFirstResponder()
    }
    
    @objc private func dismissSearchKeyboard() {
        searchBar.resignFirstResponder()
        view.endEditing(true)
    }

    func searchBarShouldEndEditing(_: UISearchBar) -> Bool {
        // self.searchController!.searchBar.isHidden = true;
        searchBar.resignFirstResponder()
        return true
    }

    func searchBarCancelButtonClicked(_: UISearchBar) {
        shouldShowSearchResults = true
        searchBar.resignFirstResponder()
    }

    func searchBarTextDidEndEditing(_: UISearchBar) {
        shouldShowSearchResults = true
        searchBar.resignFirstResponder()
    }

    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        if searchText.substring(from: searchText.startIndex).count > 2 {
            TableData.removeAll()
            SearchData.removeAll()
            if !adminUpdatePage {
                let backgroundQueue = DispatchQueue.global()
                let deadline = DispatchTime.now() + .milliseconds(100)
                backgroundQueue.asyncAfter(deadline: deadline, qos: .background) {
                    self.addData_(searchText, category: self.category_ ?? "nil")
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

    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? { nil }

    @objc func valueChanged(_ segmentedControl: UISegmentedControl) {
        print("Coming in : \(segmentedControl.selectedSegmentIndex)")
        section_ = segmentedControl.selectedSegmentIndex
        if segmentedControl.selectedSegmentIndex == 0 {
            searchBar.text = ""
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
            searchBar.text = ""
            CategoryData = ["Action", "Drama", "Crime", "Romance", "Troll"]
            SearchData.removeAll()
            TableData.removeAll()
            ScreenData_2.removeAll()
            tableView!.reloadData()
        } else if segmentedControl.selectedSegmentIndex == 2 {}
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        if adminPage || adminUpdatePage {
            return 60
        }
        return 180.0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if adminPage, !adminUpdatePage {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ADMIN_MOVIE_CELL")
                ?? UITableViewCell(style: .default, reuseIdentifier: "ADMIN_MOVIE_CELL")
            configureAdminCreateMovieCell(cell, at: indexPath)
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
            }
        } else {
            if ScreenData_2.count > 0 {
                adminRow = ScreenData_2[indexPath.row]
            } else if TableData.count > 0 {
                movieData = TableData[indexPath.row]
            } else if SearchData.count > 0 {
                movieData = SearchData[indexPath.row]
            }
        }

        // Pass the information about whether to load image or not
        configureCell(cell: cell, with: movieData, adminRow, categories: categories, indexPath: indexPath, shouldLoadImage: !adminUpdatePage)

        if adminUpdatePage {
            applyPopoverRowSelection(cell!, indexPath: indexPath)
        }

        return cell!
    }

    private func configureCell(cell: ListViewCell?, with data: MovieDataModel?, _ venueData: AdminScreeningModel?, categories: String?, indexPath _: IndexPath, shouldLoadImage: Bool) {
        guard let cell else { return }

        let textAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Courier New", size: 14.0)!,
            .foregroundColor: UIColor.black,
        ]
        let ratingAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Courier New", size: 12.0)!,
            .foregroundColor: UIColor.darkGray,
        ]

        // ── Admin/update mode: show venue › movie rows from ScreenData_2 ──
        if adminUpdatePage, let venueData {
            cell.configureLayout(compact: true)
            let label = venueData.movie
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

        // ── Normal movie rows ─��
        guard let data else { return }

        cell.configureLayout(compact: false)
        let movieId = data.movieId
        let rating = ratingsByMovieId[movieId] ?? "N/A"
        let isFavorite = favoritesByMovieId[movieId] ?? false
        cell.configureRedesign(
            title: NSAttributedString(string: data.name, attributes: textAttr),
            rating: NSAttributedString(string: "Rating: \(rating)", attributes: ratingAttr),
            isFavorite: isFavorite,
            onFavoriteTap: { [weak self] in
                guard let self else { return }
                let current = self.favoritesByMovieId[movieId] ?? false
                self.favoritesByMovieId[movieId] = !current
                self.tableView?.reloadData()
            }
        )

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

    private func configureAdminCreateMovieCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let rowData: MovieDataModel? = if TableData.indices.contains(indexPath.row) {
            TableData[indexPath.row]
        } else if SearchData.indices.contains(indexPath.row) {
            SearchData[indexPath.row]
        } else {
            nil
        }

        cell.backgroundColor = PopoverUIStyle.defaultRowBackground
        cell.selectionStyle = .none
        applyPopoverRowSelection(cell, indexPath: indexPath)

        let thumbTag = 4001
        let titleTag = 4002
        let thumb = (cell.contentView.viewWithTag(thumbTag) as? UIImageView) ?? {
            let v = UIImageView()
            v.tag = thumbTag
            v.translatesAutoresizingMaskIntoConstraints = false
            v.contentMode = .scaleAspectFit // Keep full poster visible, no crop.
            v.backgroundColor = UIColor(white: 0.96, alpha: 1)
            v.layer.cornerRadius = 6
            v.layer.masksToBounds = true
            v.layer.borderWidth = 1
            v.layer.borderColor = PopoverUIStyle.chipBorder.cgColor
            cell.contentView.addSubview(v)
            NSLayoutConstraint.activate([
                v.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 10),
                v.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                v.widthAnchor.constraint(equalToConstant: 42),
                v.heightAnchor.constraint(equalToConstant: 56),
            ])
            return v
        }()

        let titleLabel = (cell.contentView.viewWithTag(titleTag) as? UILabel) ?? {
            let v = UILabel()
            v.tag = titleTag
            v.translatesAutoresizingMaskIntoConstraints = false
            v.font = UIFont(name: "Courier New", size: 13.0) ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
            v.textColor = PopoverUIStyle.chipTitle
            v.numberOfLines = 1
            cell.contentView.addSubview(v)
            NSLayoutConstraint.activate([
                v.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 10),
                v.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -10),
                v.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            ])
            return v
        }()

        titleLabel.text = rowData?.name ?? ""
        thumb.image = nil

        if let rowData {
            let urlString = URLManager.image(rowData.largePicture)
            Task { @MainActor [weak self, weak cell] in
                guard let self, let cell else { return }
                do {
                    let imgData = try await self.appServices.images.getData(urlString: urlString, realmCache: true)
                    if let image = UIImage(data: imgData) {
                        thumb.image = image
                        cell.setNeedsLayout()
                    }
                } catch {
                    NSLog("MoviesVC admin image: %@", error.localizedDescription)
                }
            }
        }
    }

    private func styleSearchBarForPopover() {
        searchBar.backgroundImage = UIImage()
        searchBar.layer.borderColor = PopoverUIStyle.searchBorder.cgColor
        searchBar.layer.borderWidth = 1
        searchBar.layer.cornerRadius = 8
        searchBar.layer.masksToBounds = true
        searchBar.searchTextField.layer.cornerRadius = 0
        searchBar.searchTextField.layer.borderWidth = 0
        searchBar.searchTextField.borderStyle = .none
        searchBar.searchTextField.backgroundColor = .clear
        searchBar.setSearchFieldBackgroundImage(UIImage(), for: .normal)
    }

    func numberOfSections(in _: UITableView) -> Int {
        if adminUpdatePage {
            return 1
        }
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        if adminUpdatePage {
            if SearchData.count > 0 {
                return SearchData.count
            }
            if ScreenData_2.count > 0 {
                return ScreenData_2.count
            }
            return TableData.count
        }
        if SearchData.count > 0 {
            return SearchData.count
        }
        return TableData.count
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        0.01
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        0.01
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchBar.isHidden = false

        if adminPage, CategoryData.count == 0 {
            selectPopoverMovieRow(indexPath)
            if TableData.count > 0 {
                addMovie = TableData[indexPath.row].name
            } else {
                addMovie = SearchData[indexPath.row].name
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newScreenMovieSelected"), object: nil)
        }

        if adminUpdatePage, CategoryData.count == 0 {
            selectPopoverMovieRow(indexPath)
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

    private func selectedMovie(at indexPath: IndexPath) -> MovieDataModel? {
        if TableData.count > 0 {
            return TableData[indexPath.row]
        }
        if SearchData.count > 0 {
            return SearchData[indexPath.row]
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
        searchBar.isHidden = false

        if TableData.count > 10 || SearchData.count > 10 {
            if indexPath.row == TableData.count - 3 {
                if endOfFile == false {
                    addData(category: category_ ?? "nil")
                }
                if indexPath.row == SearchData.count - 3, endOfFile == false {
                    addData_(searchString ?? "", category: category_ ?? "nil")
                }
            }
        }
        if adminUpdatePage {
            if TableData.count > 10 || SearchData.count > 10 {
                if indexPath.row == TableData.count - 3 {
                    if endOfFile == false {
                        addData(category: category_ ?? "nil")
                    }
                    if indexPath.row == SearchData.count - 3, endOfFile == false {
                        addData_(searchString ?? "", category: category_ ?? "nil")
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

    private func buildCategoryChipsBar() {
        categoryScrollView?.removeFromSuperview()
        let scroll = UIScrollView(frame: CGRect(x: 0, y: 96, width: view.frame.width, height: 40))
        scroll.showsHorizontalScrollIndicator = false
        scroll.backgroundColor = .white
        scroll.alwaysBounceHorizontal = true
        scroll.alwaysBounceVertical = false
        scroll.decelerationRate = .fast

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -4),
            stack.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor, constant: -8),
        ])

        view.addSubview(scroll)
        categoryScrollView = scroll
        categoryStack = stack
    }

    private func renderCategoryChips() {
        guard let stack = categoryStack else { return }
        stack.arrangedSubviews.forEach { v in
            stack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }

        let chips = categoryChips.isEmpty ? fallbackCategories : categoryChips
        for chip in chips {
            let button = UIButton(type: .system)
            button.setTitle(chip, for: .normal)
            button.setTitleColor(PopoverUIStyle.chipTitle, for: .normal)
            button.backgroundColor = (category_ == chip || (chip == "All" && (category_ == nil || category_ == "nil")))
                ? PopoverUIStyle.chipActiveBackground
                : PopoverUIStyle.chipBackground
            button.layer.borderColor = PopoverUIStyle.chipBorder.cgColor
            button.layer.borderWidth = 1
            button.layer.cornerRadius = 9
            button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 7)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.titleLabel?.font = .systemFont(ofSize: 10, weight: .regular)
            button.addTarget(self, action: #selector(didTapCategoryChip(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }

    @objc private func didTapCategoryChip(_ sender: UIButton) {
        let title = sender.currentTitle ?? "All"
        category_ = (title == "All") ? "nil" : title
        searchBar.text = ""
        SearchData.removeAll()
        TableData.removeAll()
        addData(category: category_ ?? "nil")
        renderCategoryChips()
    }

    private func resolveCategories(from movies: [MovieDataModel]) {
        let extracted = Set(movies.compactMap { extractedCategory(from: $0) })
        if extracted.isEmpty {
            categoryChips = fallbackCategories
            NSLog("MoviesVC categories source=fallback count=%d", categoryChips.count)
        } else {
            categoryChips = ["All"] + extracted.sorted()
            NSLog("MoviesVC categories source=backend count=%d", categoryChips.count)
        }
    }

    private func extractedCategory(from _: MovieDataModel) -> String? {
        nil
    }

    private func loadRatingsFixture() {
        guard let url = Bundle.main.url(forResource: "ratings-mock", withExtension: "json") else {
            ratingsByMovieId = [:]
            NSLog("MoviesVC ratings source=fallback count=0")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(RatingsPayload.self, from: data)
            ratingsByMovieId = Dictionary(uniqueKeysWithValues: payload.ratings.map { ($0.movieId, $0.rating) })
            NSLog("MoviesVC ratings source=fixture count=%d", ratingsByMovieId.count)
        } catch {
            ratingsByMovieId = [:]
            NSLog("MoviesVC ratings source=fallback error=%@", error.localizedDescription)
        }
    }
}

private struct RatingsPayload: Codable {
    let ratings: [RatingItem]
}

private struct RatingItem: Codable {
    let movieId: Int
    let rating: String
}
