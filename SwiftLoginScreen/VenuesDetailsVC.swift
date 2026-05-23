// VenuesDetailsVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import AVKit
import EventKit
import UIKit

class VenuesDetailsVC: UIViewController, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, UIViewControllerTransitioningDelegate, HasAppServices {
    // MARK: Lifecycle

    deinit {
        print(#function, "\(self)")
    }

    // MARK: Internal

    class HalfSizePresentationController: UIPresentationController {
        override var frameOfPresentedViewInContainerView: CGRect {
            CGRect(x: 0, y: 200, width: containerView!.bounds.width, height: containerView!.bounds.height)
        }
    }

    var appServices: AppServices!
    lazy var noPicture: [String: String] = [:]

    var nameTextView: UITextView?
    var selectVenuesPicture: String?
    var selectLargePicture: String?
    var selectVenueId: Int?
    var venueName: String?
    var selectAddress: String?
    var movieId: Int!
    var movieName: String?
    var movieDetails: String?
    var screenScreenId: String?
    var locationId: Int!
    var iMDB: String?

    var popOverY: CGFloat!

    lazy var imageView = UIImageView()
    lazy var venueImageView = UIImageView()
    var scrollView: UIScrollView!
    lazy var moviePicture = UIImage()
    lazy var venuePicture = UIImage()

    let eventStore = EKEventStore()

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        injectAppServicesIfNeeded()
        populateSelectionContext()
        setupScrollView()
        addDatesData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Only load images if not already loaded to avoid repeated network/decoding
        if moviePicture.size == CGSize.zero {
            loadMovieImage()
        }
        if venuePicture.size == CGSize.zero {
            loadVenueImage()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasSetupUI {
            setupUI()
            hasSetupUI = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        DatesDataManager.shared.resetNavigationContext()
        LocationsDataManager.shared.activeMapView = nil
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "navigateBack"), object: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_map2" {
            LocationsDataManager.shared.selectedLocationId = locationId
            LocationsDataManager.shared.selectedVenueId = selectVenueId
            LocationsDataManager.shared.isMapFromVenueDetails = true
        }
        if segue.identifier == "goto_movie_detail2" {
            let nextSegue = segue.destination as? MovieDetailVC
            nextSegue?.iMDB = iMDB
            nextSegue?.origin = "VenuesDetailsVC"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard hasSetupUI else { return }
        layoutRedesignedUIIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Avoid repeated audio-stack churn while this screen is not visible.
        playerViewController?.player?.pause()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        applyHeroBlur(for: scrollView.contentOffset.y)
    }

    @objc func showMoreActions(_ tap: UITapGestureRecognizer) {
        _ = tap.location(in: view)
    }

    @objc func navigateBack() {
        dismiss(animated: false, completion: nil)
    }

    @objc func movieDetail(_: UIButton, event _: UIEvent) {
        performSegue(withIdentifier: "goto_movie_detail2", sender: self)
    }

    @objc func book(_: UIButton, event: UIEvent) {
        if isLoadingSeats {
            return
        }

        if event.type == .touches {
            let touches: Set<UITouch> = event.allTouches!

            if let touch = touches.first {
                popOverY = touch.location(in: scrollView).y
            }
        }

        if DatesDataManager.shared.selectedScreeningDateId == nil {
            let alertView = UIAlertView()

            alertView.title = "Warning!"
            alertView.message = "Select dates first!"
            alertView.delegate = self
            alertView.addButton(withTitle: "OK")
            alertView.show()

        } else {
            Task { @MainActor [weak self] in
                guard let self,
                      let selectedId = DatesDataManager.shared.selectedScreeningDateId,
                      let parsedId = Int(selectedId) else { return }

                self.isLoadingSeats = true
                defer { self.isLoadingSeats = false }

                do {
                    _ = try await SeatsDataManager.shared.fetchSeats(screeningDateId: parsedId)

                    let popOver = PopOver()
                    popOver.modalPresentationStyle = UIModalPresentationStyle.popover
                    popOver.preferredContentSize = CGSize(width: self.view.frame.width * 0.90, height: self.view.frame.height / 2)

                    let popoverMenuViewController = popOver.popoverPresentationController
                    popoverMenuViewController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                    popoverMenuViewController?.delegate = self
                    popoverMenuViewController?.sourceView = self.view
                    popoverMenuViewController!.sourceRect = CGRect(
                        x: self.view.frame.width * 0.50,
                        y: self.popOverY,
                        width: 0,
                        height: 0
                    )

                    self.present(popOver, animated: true)
                } catch {
                    self.presentAlert(withTitle: "Error", message: error.userMessage)
                }
            }
        }
    }

    @objc func map(_: UIButton, event _: UIEvent) {
        performSegue(withIdentifier: "goto_map2", sender: self)
    }

    @objc func dates(_: UIButton, event: UIEvent) {
        if event.type == .touches {
            let touches: Set<UITouch> = event.allTouches!

            if let touch = touches.first {
                popOverY = touch.location(in: scrollView).y
            }
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            if DatesDataManager.shared.availableDates.isEmpty {
                do {
                    _ = try await self.loadDatesData()
                } catch {
                    self.presentAlert(withTitle: "Error", message: error.localizedDescription)
                    return
                }
            }

            guard !DatesDataManager.shared.availableDates.isEmpty else {
                self.presentAlert(withTitle: "Info", message: "No dates available for this venue.")
                return
            }

            let popOver = PopOverDates()
            popOver.modalPresentationStyle = UIModalPresentationStyle.popover
            popOver.preferredContentSize = CGSize(width: self.view.frame.width * 0.90, height: self.view.frame.height / 5)

            let popoverMenuViewController = popOver.popoverPresentationController
            popoverMenuViewController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)

            popoverMenuViewController?.delegate = self
            popoverMenuViewController?.sourceView = self.view
            popoverMenuViewController!.sourceRect = CGRect(
                x: self.view.frame.width * 0.50,
                y: self.popOverY,
                width: 0,
                height: 0
            )

            self.present(
                popOver,
                animated: true,
                completion: nil
            )
        }
    }

    @objc func selectCalendar(_: UIButton) {
        if DatesDataManager.shared.selectedScreeningDateId == nil {
            let alertView = UIAlertView()

            alertView.title = "Warning!"
            alertView.message = "Select dates first!"
            alertView.delegate = self
            alertView.addButton(withTitle: "OK")
            alertView.show()

        } else {
            // Access permission
            eventStore.requestAccess(to: EKEntityType.event) { granted, error in
                if granted, error == nil {
                    print("permission is granted")

                    DispatchQueue.main.async {
                        let popOver = iOSCalendarVC()
                        popOver.modalPresentationStyle = UIModalPresentationStyle.popover
                        popOver.preferredContentSize = CGSize(width: self.view.frame.width * 0.90, height: self.view.frame.height / 4)

                        let popoverMenuViewController = popOver.popoverPresentationController
                        popoverMenuViewController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                        popoverMenuViewController?.delegate = self
                        popoverMenuViewController?.sourceView = self.view
                        popoverMenuViewController!.sourceRect = CGRect(
                            x: self.view.frame.width * 0.50,
                            y: self.view.frame.height * 0.50,
                            width: 0,
                            height: 0
                        )

                        self.present(
                            popOver,
                            animated: true,
                            completion: nil
                        )
                    }
                }
            }
        }
    }

    func presentationController(forPresented presented: UIViewController, presenting _: UIViewController?, source _: UIViewController) -> UIPresentationController? {
        HalfSizePresentationController(presentedViewController: presented, presenting: presentingViewController)
    }

    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        .none
    }

    func addDatesData() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.loadDatesData()
            } catch {
                NSLog("addDatesData: %@", error.localizedDescription)
            }
        }
    }

    @objc func selectCalendar_(sender _: UIButton /* , event: UIEvent */ ) {
        if DatesDataManager.shared.selectedScreeningDateId == nil {
            let alertView = UIAlertView()

            alertView.title = "Warning!"
            alertView.message = "Select dates first!"
            alertView.delegate = self
            alertView.addButton(withTitle: "OK")
            alertView.show()

        } else {
            // Access permission
            eventStore.requestAccess(to: EKEntityType.event) { granted, error in
                if granted, error == nil {
                    print("permission is granted")
                    /*
                     if event.type == .touches {

                     let touches:Set<UITouch> = event.allTouches!

                     if let touch =  touches.first{

                     self.popOverY = touch.location(in: self.scrollView).y
                     self.popOverX = touch.location(in: self.view).x

                     }
                     }*/

                    DispatchQueue.main.async {
                        let popOver = iOSCalendarVC()
                        popOver.modalPresentationStyle = UIModalPresentationStyle.popover
                        popOver.preferredContentSize = CGSize(width: self.view.frame.width * 0.90, height: self.view.frame.height / 4)

                        let popoverMenuViewController = popOver.popoverPresentationController
                        popoverMenuViewController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                        popoverMenuViewController?.delegate = self
                        popoverMenuViewController?.sourceView = self.view
                        popoverMenuViewController!.sourceRect = CGRect(
                            x: self.view.frame.width * 0.50,
                            y: self.view.frame.height * 0.50,
                            width: 0,
                            height: 0
                        )

                        self.present(
                            popOver,
                            animated: true,
                            completion: nil
                        )
                    }
                }
            }
        }
    }

    // MARK: Private

    private let heroContainerView = UIView()
    private let heroBlurOverlay = UIVisualEffectView(effect: nil)
    private let heroDimOverlay = UIView()
    private let contentCardView = UIView()
    private let actionStackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let playerContainerView = UIView()
    private let heroGradientLayer = CAGradientLayer()

    private var isLoadingDates = false
    private var isLoadingSeats = false
    private var hasSetupUI = false
    private var playerViewController: AVPlayerViewController?
    private var hasInitializedPlayer = false
    private var lastLaidOutBoundsSize: CGSize = .zero

    private let heroBlurRampDistance: CGFloat = 180
    private let maxHeroDimAlpha: CGFloat = 0.80
    private let actionButtonHeight: CGFloat = 50
    private let actionButtonSpacing: CGFloat = 12
    private let actionButtonFontName = "HelveticaNeue-Medium"
    private let actionButtonFontSize: CGFloat = 16

    private var resolvedScreenId: String? {
        let id = screenScreenId ?? VenuesDataManager.shared.selectedVenue?.screenId
        guard let id, !id.isEmpty else { return nil }
        return id
    }

    private func populateSelectionContext() {
        if movieId == nil {
            movieId = MoviesDataManager.shared.selectedMovie?.movieId
        }
        if movieName == nil {
            movieName = MoviesDataManager.shared.selectedMovie?.name
        }
        if movieDetails == nil {
            movieDetails = MoviesDataManager.shared.selectedMovie?.detail
        }
        if selectLargePicture == nil {
            selectLargePicture = MoviesDataManager.shared.selectedMovie?.largePicture
        }
        if iMDB == nil {
            iMDB = MoviesDataManager.shared.selectedMovie?.imdbUrl
        }

        if selectVenueId == nil {
            selectVenueId = VenuesDataManager.shared.selectedVenue?.venuesId
        }
        if venueName == nil {
            venueName = VenuesDataManager.shared.selectedVenue?.name
        }
        if selectAddress == nil {
            selectAddress = VenuesDataManager.shared.selectedVenue?.address
        }
        if selectVenuesPicture == nil {
            selectVenuesPicture = VenuesDataManager.shared.selectedVenue?.venuesPicture
        }
        if screenScreenId == nil {
            screenScreenId = VenuesDataManager.shared.selectedVenue?.screenId
        }
        if locationId == nil {
            locationId = VenuesDataManager.shared.selectedVenue?.locationId ?? LocationsDataManager.shared.selectedLocationId
        }

        if let movieId,
           let movieName,
           let movieDetails,
           let selectLargePicture,
           let iMDB
        {
            MoviesDataManager.shared.selectedMovie = Movie(
                movieId: movieId,
                movieIdString: String(movieId),
                name: movieName,
                detail: movieDetails,
                largePicture: selectLargePicture,
                imdbUrl: iMDB
            )
        }

        if let selectVenueId,
           let venueName,
           let selectAddress,
           let screenId = screenScreenId,
           let locationId
        {
            VenuesDataManager.shared.selectedVenue = Venue(
                venuesId: selectVenueId,
                name: venueName,
                address: selectAddress,
                venuesPicture: selectVenuesPicture ?? "",
                screenId: screenId,
                locationId: locationId
            )
        }
    }

    // MARK: - Setup Methods

    private func setupScrollView() {
        view.backgroundColor = .white

        heroContainerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: heroHeight())
        heroContainerView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        heroContainerView.clipsToBounds = true
        heroContainerView.autoresizingMask = [.flexibleWidth]
        view.addSubview(heroContainerView)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = heroContainerView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        heroContainerView.addSubview(imageView)

        heroGradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.16).cgColor,
            UIColor.black.withAlphaComponent(0.45).cgColor,
        ]
        heroGradientLayer.locations = [0.0, 0.55, 1.0]
        heroContainerView.layer.addSublayer(heroGradientLayer)

        heroBlurOverlay.frame = heroContainerView.bounds
        heroBlurOverlay.alpha = 0
        heroBlurOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if #available(iOS 13.0, *) {
            heroBlurOverlay.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        } else {
            heroBlurOverlay.effect = UIBlurEffect(style: .dark)
        }
        heroContainerView.addSubview(heroBlurOverlay)

        heroDimOverlay.frame = heroContainerView.bounds
        heroDimOverlay.backgroundColor = .black
        heroDimOverlay.alpha = 0.08
        heroDimOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        heroContainerView.addSubview(heroDimOverlay)

        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)

        contentCardView.backgroundColor = .white
        contentCardView.layer.cornerRadius = 24
        contentCardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentCardView.layer.shadowColor = UIColor.black.cgColor
        contentCardView.layer.shadowOpacity = 0.10
        contentCardView.layer.shadowRadius = 18
        contentCardView.layer.shadowOffset = CGSize(width: 0, height: -4)
        scrollView.addSubview(contentCardView)

        applyTopNavigationButtonStyle(backButton, title: "‹ Back")
        backButton.addTarget(self, action: #selector(navigateBack), for: .touchUpInside)
        view.addSubview(backButton)
    }

    private func loadMovieImage() {
        guard let selectLargePicture = selectLargePicture else { return }
        let urlString = URLManager.image(selectLargePicture)

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let data = try await self.appServices.images.getData(urlString: urlString, realmCache: true)
                guard let image = UIImage(data: data) else { return }
                self.moviePicture = image
                self.setupMovieImageView()
            } catch {
                NSLog("loadMovieImage: %@", error.localizedDescription)
            }
        }
    }

    private func loadVenueImage() {
        if let selectVenuesPicture = selectVenuesPicture, !selectVenuesPicture.isEmpty {
            let urlString = URLManager.image(selectVenuesPicture)

            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let data = try await self.appServices.images.getData(urlString: urlString, realmCache: true)
                    guard let image = UIImage(data: data) else { return }
                    self.venuePicture = image
                    self.setupVenueImageView()
                } catch {
                    NSLog("loadVenueImage: %@", error.localizedDescription)
                }
            }
        } else {
            noPicture = ["NoPicture": "cat2"]
            venuePicture = UIImage(named: noPicture["NoPicture"]!) ?? UIImage()
            setupVenueImageView()
        }
    }

    private func setupMovieImageView() {
        imageView.removeFromSuperview()
        imageView.frame = heroContainerView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = moviePicture
        heroContainerView.insertSubview(imageView, at: 0)
    }

    private func setupVenueImageView() {
        venueImageView.removeFromSuperview()
        venueImageView.contentMode = .scaleAspectFill
        venueImageView.clipsToBounds = true
        venueImageView.image = venuePicture
        contentCardView.addSubview(venueImageView)
        if hasSetupUI {
            layoutContentSections()
        }
    }

    private func setupUI() {
        setupTextView()
        setupButtons()
        setupVenueImageView()
        setupPlayer()
        configureContentText()
        layoutRedesignedUIIfNeeded(force: true)
    }

    private func setupButtons() {
        if actionStackView.superview == nil {
            actionStackView.axis = .vertical
            actionStackView.spacing = actionButtonSpacing
            actionStackView.alignment = .fill
            actionStackView.distribution = .fillEqually
            contentCardView.addSubview(actionStackView)
        }

        for arrangedSubview in actionStackView.arrangedSubviews {
            actionStackView.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }

        let actions: [(String, String, Selector)] = [
            ("🎫", "Book", #selector(book)),
            ("📅", "Dates", #selector(dates)),
            ("🗺️", "Map", #selector(map)),
            ("🎬", "Movie Detail", #selector(movieDetail)),
            ("📆", "Calendar", #selector(selectCalendar)),
        ]

        for (icon, title, selector) in actions {
            let button = createActionButton(icon: icon, title: title)
            button.addTarget(self, action: selector, for: .touchUpInside)
            actionStackView.addArrangedSubview(button)
        }
    }

    private func setupTextView() {
        if titleLabel.superview == nil {
            titleLabel.numberOfLines = 0
            titleLabel.textColor = .black
            titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
            contentCardView.addSubview(titleLabel)
        }

        if subtitleLabel.superview == nil {
            subtitleLabel.numberOfLines = 0
            subtitleLabel.textColor = UIColor.black.withAlphaComponent(0.65)
            subtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
            contentCardView.addSubview(subtitleLabel)
        }

        if nameTextView == nil {
            nameTextView = UITextView(frame: .zero)
        }

        nameTextView?.isEditable = false
        nameTextView?.isScrollEnabled = false
        nameTextView?.textAlignment = .justified
        nameTextView?.backgroundColor = .white
        nameTextView?.textColor = .black
        nameTextView?.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        nameTextView?.layer.borderWidth = 1
        nameTextView?.layer.borderColor = UIColor.black.withAlphaComponent(0.12).cgColor
        nameTextView?.layer.cornerRadius = 14

        if let movieDetails {
            let bodyFont = UIFont(name: "Courier New", size: 13.0) ?? .monospacedSystemFont(ofSize: 13.0, weight: .regular)
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.black,
            ]
            nameTextView?.attributedText = NSAttributedString(string: movieDetails, attributes: textAttributes)
        }

        if nameTextView?.superview == nil, let nameTextView {
            contentCardView.addSubview(nameTextView)
        }
    }

    private func setupPlayer() {
        // Skip if already initialized to avoid audio subsystem churn
        if hasInitializedPlayer {
            return
        }
        hasInitializedPlayer = true

        guard let fileURL = Bundle.main.path(forResource: "garnier1", ofType: "mov") else {
            print("Player setup: File not found")
            return
        }

        // Lazy-load player: only set up once and reuse
        let url = NSURL.fileURL(withPath: fileURL)
        let playerItem = AVPlayerItem(asset: AVAsset(url: url), automaticallyLoadedAssetKeys: ["playable"])
        let player = AVPlayer(playerItem: playerItem)

        let pvc = AVPlayerViewController()
        pvc.player = player

        playerContainerView.frame = .zero
        playerContainerView.backgroundColor = .black
        playerContainerView.clipsToBounds = true
        playerContainerView.layer.cornerRadius = 16

        // Add player view to container with autoresizing
        pvc.view.frame = playerContainerView.bounds
        pvc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerContainerView.addSubview(pvc.view)

        addChild(pvc)
        contentCardView.addSubview(playerContainerView)
        pvc.didMove(toParent: self)

        playerViewController = pvc
    }

    // MARK: - Helper Methods

    private func getResizedImageDimensions(for image: UIImage, startY: CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        var width = image.size.width
        var height = image.size.height
        let aspectRatio = width / height

        if width > view.frame.width {
            width = view.frame.width * 0.9
            height = width / aspectRatio
        }

        let x = (view.frame.width - width) / 2
        return (width, height, x, startY)
    }

    private func createButton(title: String, y: CGFloat, x: CGFloat, width: CGFloat = 85) -> UIButton {
        let button = UIButton(frame: CGRect(x: x, y: y, width: width, height: 30))
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        // Use dynamic colors for background and title
        button.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        button.setTitleColor(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }, for: .normal)
        return button
    }

    private func createActionButton(icon: String, title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .black
        button.layer.cornerRadius = 14
        button.layer.masksToBounds = true
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let font = UIFont(name: actionButtonFontName, size: actionButtonFontSize) ?? .systemFont(ofSize: actionButtonFontSize, weight: .semibold)
        let attributedTitle = NSMutableAttributedString(
            string: "\(icon)  \(title)",
            attributes: [
                .font: font,
                .foregroundColor: UIColor.white,
            ]
        )
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.tintColor = .white
        return button
    }

    private func createUpperButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 40)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func configureContentText() {
        titleLabel.text = venueName?.isEmpty == false ? venueName : "Venue Details"

        let subtitleParts = [movieName, selectAddress]
            .compactMap { value -> String? in
                guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                return value
            }
        subtitleLabel.text = subtitleParts.isEmpty ? "Scroll up to bring actions into focus." : subtitleParts.joined(separator: "\n")
    }

    private func heroHeight() -> CGFloat {
        let proportionalHeight = view.bounds.height * 0.34
        return max(240, min(320, proportionalHeight))
    }

    private func applyHeroBlur(for offset: CGFloat) {
        let progress = max(0, min(1, offset / heroBlurRampDistance))
        heroBlurOverlay.alpha = 0.08 + (0.38 * progress)
        heroDimOverlay.alpha = 0.08 + (maxHeroDimAlpha * progress)
    }

    private func layoutRedesignedUIIfNeeded(force: Bool = false) {
        let boundsSize = view.bounds.size
        guard force || boundsSize != lastLaidOutBoundsSize else { return }
        lastLaidOutBoundsSize = boundsSize

        let topInset = view.safeAreaInsets.top
        let currentHeroHeight = heroHeight() + topInset

        heroContainerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: currentHeroHeight)
        heroGradientLayer.frame = heroContainerView.bounds
        heroBlurOverlay.frame = heroContainerView.bounds
        heroDimOverlay.frame = heroContainerView.bounds
        imageView.frame = heroContainerView.bounds

        scrollView.frame = view.bounds
        backButton.sizeToFit()
        backButton.frame = CGRect(
            x: 16,
            y: topInset + 12,
            width: backButton.bounds.width + 16,
            height: max(32, backButton.bounds.height)
        )

        layoutContentSections(heroHeight: currentHeroHeight)
        applyHeroBlur(for: scrollView.contentOffset.y)
    }

    private func layoutContentSections(heroHeight: CGFloat? = nil) {
        let resolvedHeroHeight = heroHeight ?? heroContainerView.bounds.height
        let overlap: CGFloat = 34
        let sideInset: CGFloat = 20
        let innerWidth = view.bounds.width - (sideInset * 2)
        var currentY: CGFloat = 26

        let cardOriginY = max(0, resolvedHeroHeight - overlap)
        contentCardView.frame = CGRect(x: 0, y: cardOriginY, width: view.bounds.width, height: 10)

        titleLabel.frame = CGRect(x: sideInset, y: currentY, width: innerWidth, height: 0)
        titleLabel.sizeToFit()
        titleLabel.frame.size.width = innerWidth
        currentY = titleLabel.frame.maxY + 10

        let subtitleSize = subtitleLabel.sizeThatFits(CGSize(width: innerWidth, height: .greatestFiniteMagnitude))
        subtitleLabel.frame = CGRect(x: sideInset, y: currentY, width: innerWidth, height: subtitleSize.height)
        currentY = subtitleLabel.frame.maxY + 18

        let textHeight = max(130, nameTextView?.sizeThatFits(CGSize(width: innerWidth, height: .greatestFiniteMagnitude)).height ?? 130)
        nameTextView?.frame = CGRect(x: sideInset, y: currentY, width: innerWidth, height: textHeight)
        currentY += textHeight + 20

        let buttonCount = CGFloat(actionStackView.arrangedSubviews.count)
        let stackHeight = buttonCount > 0
            ? (buttonCount * actionButtonHeight) + ((buttonCount - 1) * actionButtonSpacing)
            : 0
        actionStackView.frame = CGRect(x: sideInset, y: currentY, width: innerWidth, height: stackHeight)
        currentY += stackHeight + 20

        if venuePicture.size != .zero {
            let venueHeight = min(220, max(150, innerWidth * 0.56))
            venueImageView.frame = CGRect(x: sideInset, y: currentY, width: innerWidth, height: venueHeight)
            venueImageView.layer.cornerRadius = 16
            currentY += venueHeight + 20
        } else {
            venueImageView.frame = .zero
        }

        let playerHeight: CGFloat = 220
        playerContainerView.frame = CGRect(x: sideInset, y: currentY, width: innerWidth, height: playerHeight)
        if let playerView = playerViewController?.view {
            playerView.frame = playerContainerView.bounds
        }
        currentY += playerHeight + 28

        contentCardView.frame.size.height = currentY
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        scrollView.contentSize = CGSize(width: view.bounds.width, height: contentCardView.frame.maxY + 24)
    }

    @MainActor
    private func loadDatesData() async throws -> Bool {
        if isLoadingDates {
            return !DatesDataManager.shared.availableDates.isEmpty
        }
        isLoadingDates = true
        defer { isLoadingDates = false }

        let screenDates = try await DatesDataManager.shared.fetchDates(locationId: locationId, movieId: movieId)
        return !screenDates.isEmpty
    }
}
