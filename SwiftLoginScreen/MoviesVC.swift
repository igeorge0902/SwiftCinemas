// MoviesVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import UIKit

nonisolated(unsafe) var endOfFile = false
nonisolated(unsafe) var veil = true
nonisolated(unsafe) var shouldShowSearchResults = false
class MoviesVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate, HasAppServices {
    // MARK: Lifecycle

    deinit {
        endOfFile = false
        adminPage = false
        adminUpdatePage = false
        print(#function, "\(self)")
    }

    // MARK: Internal

    var appServices: AppServices!
    private lazy var viewModel = MoviesViewModel(movies: .shared, admin: .shared)
    var AdminUpadteData: [AdminScreeningModel] { viewModel.state.adminRows }
    var SearchData: [MovieDataModel] { viewModel.state.search }
    var TableData: [MovieDataModel] { viewModel.state.browse }
    var CategoryData: [String] { viewModel.state.categories }
    var tableView: UITableView?
    var searchBarFrame: UIView?
    var categoryScrollView: UIScrollView?
    var categoryStack: UIStackView?
    var section_: Int { viewModel.state.section }
    var category_: String? { viewModel.state.category }
    var searchString: String? { viewModel.state.searchString }
    var categoryChips: [String] { viewModel.state.categoryChips }
    var favoritesByMovieId: [Int: Bool] { viewModel.state.favorites }
    var ratingsByMovieId: [Int: String] { viewModel.state.ratings }
    var fallbackCategories: [String] { viewModel.fallbackCategories }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goto_venues",
           let indexPath = tableView?.indexPathForSelectedRow,
           let movie = selectedMovie(at: indexPath)
        {
            viewModel.selectMovie(movie)
        }
        if segue.identifier == "goto_movie_detail",
           let tag = (sender as? UIButton)?.tag,
           tag < TableData.count || tag < SearchData.count
        {
            let movie = TableData.indices.contains(tag) ? TableData[tag] : SearchData[tag]
            viewModel.selectMovie(movie)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        injectAppServicesIfNeeded()
        viewModel.onStateChange = { [weak self] state in
            if case .movies = state.rowChange { self?.renderCategoryChips() }
            self?.tableView?.reloadData()
        }

        veil = true
        searchBar.delegate = self
        searchBar.placeholder = "Search in Title and Description..."
        searchBar.autocapitalizationType = .none
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundImage = UIImage()

        definesPresentationContext = true
        viewModel.setCategory("nil")

        view.backgroundColor = .white

        viewModel.loadRatingsFixture()

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

        viewModel.resolveCategories(from: TableData)
        renderCategoryChips()

        if adminUpdatePage == true {
            viewModel.clearBrowse()
            addLoadMoviesonVenue()
        } else {
            addData(category: "nil")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel.clearAdminContext()
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
        let query = viewModel.browseQuery(category: category)
        Task { @MainActor [weak self] in
            guard let self else { return }
            await viewModel.loadBrowse(query: query)
        }
    }

    func addLoadMoviesonVenue(category: String) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            _ = await viewModel.loadAdmin(category: category == "nil" ? nil : category)
        }
    }

    func addLoadMoviesonVenue(search: String) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await viewModel.searchAdmin(search)
        }
    }

    func addData_(_ match: String, category: String) {
        let query = viewModel.searchQuery(match, category: category)
        Task { @MainActor [weak self] in
            guard let self else { return }
            await viewModel.loadSearch(query: query)
        }
    }

    @objc func addLoadMoviesonVenue() {
        viewModel.clearAdmin()

        Task { @MainActor [weak self] in
            guard let self else { return }
            if await viewModel.loadAdmin(publishRows: false) {
                if !AdminUpadteData.isEmpty {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "venueSelected"), object: nil)
                }
                self.tableView?.reloadData()
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
        switch viewModel.searchTextChanged(searchText, isAdminUpdate: adminUpdatePage) {
        case .delayedSearch:
            Task { @MainActor in
                await self.viewModel.delayedSearch(searchText)
            }
        case .adminSearch:
            addLoadMoviesonVenue(search: searchText)
        case .browseReload:
            addData(category: category_ ?? "nil")
            tableView!.reloadData()
        case .adminReload:
            addLoadMoviesonVenue()
            tableView?.reloadData()
        case .none: break
        }
        shouldShowSearchResults = true
    }

    func updateSearchResults(for searchController: UISearchController) {
        viewModel.setSearchString(searchController.searchBar.text)
        print(searchString!)
    }

    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        nil
    }

    @objc func valueChanged(_ segmentedControl: UISegmentedControl) {
        print("Coming in : \(segmentedControl.selectedSegmentIndex)")
        viewModel.selectSection(segmentedControl.selectedSegmentIndex)
        if segmentedControl.selectedSegmentIndex == 0 {
            searchBar.text = ""
            if adminUpdatePage {
                addLoadMoviesonVenue()
            } else {
                addData(category: "nil")
            }
        } else if section_ == 1 {
            searchBar.text = ""
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
            if AdminUpadteData.count > 0 {
                adminRow = AdminUpadteData[indexPath.row]
            } else if TableData.count > 0 {
                movieData = TableData[indexPath.row]
            } else if SearchData.count > 0 {
                movieData = SearchData[indexPath.row]
            }
        } else {
            if AdminUpadteData.count > 0 {
                adminRow = AdminUpadteData[indexPath.row]
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
            if AdminUpadteData.count > 0 {
                return AdminUpadteData.count
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
            if TableData.count > 0 {
                viewModel.selectMovie(TableData[indexPath.row])
            } else {
                viewModel.selectMovie(SearchData[indexPath.row])
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newScreenMovieSelected"), object: nil)
        }

        if adminUpdatePage, CategoryData.count == 0 {
            if AdminUpadteData.count > 0 {
                viewModel.selectAdminScreen(at: indexPath.row)
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
                viewModel.selectMovie(movie)
            }
            if !VenuesFeatureFlags.shouldUseMigration(), let movie = selectedMovie(at: indexPath) {
                presentVenuesMigration(for: movie)
            } else {
                performSegue(withIdentifier: "goto_venues", sender: self)
            }
        }
    }

    func tableView(_: UITableView, willDisplay _: UITableViewCell, forRowAt indexPath: IndexPath) {
        searchBar.isHidden = false

        for request in viewModel.pagingRequests(for: indexPath.row, isAdminUpdate: adminUpdatePage) {
            switch request {
            case .browse:
                addData(category: category_ ?? "nil")
            case .search:
                addData_(searchString ?? "", category: category_ ?? "nil")
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

    // MARK: Private

    private enum PopoverUIStyle {
        static let selectedRowBackground = UIColor(white: 0.95, alpha: 1)
        static let defaultRowBackground = UIColor.white
        static let searchBorder = UIColor(white: 0.84, alpha: 1)
        static let chipTitle = UIColor(white: 0.2, alpha: 1)
        static let chipActiveBackground = UIColor(white: 0.90, alpha: 1)
        static let chipBackground = UIColor(white: 0.94, alpha: 1)
        static let chipBorder = UIColor(white: 0.86, alpha: 1)
    }

    // var searchController: UISearchController?
    private let searchBar = UISearchBar()
    private var selectedPopoverMovieRow: Int? { viewModel.state.selectedPopoverMovieRow }

    private func applyPopoverRowSelection(_ cell: UITableViewCell, indexPath: IndexPath) {
        cell.contentView.backgroundColor = selectedPopoverMovieRow == indexPath.row
            ? PopoverUIStyle.selectedRowBackground
            : PopoverUIStyle.defaultRowBackground
    }

    @objc private func focusSearchBar() {
        searchBar.becomeFirstResponder()
    }

    @objc private func dismissSearchKeyboard() {
        searchBar.resignFirstResponder()
        view.endEditing(true)
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
                self.viewModel.toggleFavorite(movieId: movieId)
                self.tableView?.reloadData()
            }
        )

        if shouldLoadImage {
            if let url = URL(string: data.largePicture) {
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

    private func selectedMovie(at indexPath: IndexPath) -> MovieDataModel? {
        viewModel.selectedMovie(at: indexPath.row)
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
        for v in stack.arrangedSubviews {
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
        viewModel.selectCategoryChip(title)
        searchBar.text = ""
        addData(category: category_ ?? "nil")
        renderCategoryChips()
    }

}
