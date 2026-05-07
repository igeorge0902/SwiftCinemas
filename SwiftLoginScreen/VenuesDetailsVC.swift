//
//  VenuesDetailsVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 27/03/16.
//  Copyright © 2016 George Gaspar. All rights reserved.

import AVKit

// import FacebookShare
// import FacebookLogin
// import FacebookCore
import EventKit
import UIKit

class VenuesDetailsVC: UIViewController, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, UIViewControllerTransitioningDelegate, HasAppServices {
    var appServices: AppServices!
    deinit {
        DatesDataManager.shared.resetNavigationContext()
        // NotificationCenter.default.post(name: NSNotification.Name(rawValue: "navigateBack"), object: nil)
        LocationsDataManager.shared.activeMapView = nil
        print(#function, "\(self)")
    }

    // MARK: - Properties

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
    private var isLoadingDates = false

    private var resolvedScreenId: String? {
        let id = screenScreenId ?? VenuesDataManager.shared.selectedVenue?.screenId
        guard let id, !id.isEmpty else { return nil }
        return id
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        injectAppServicesIfNeeded()
        populateSelectionContext()
        setupScrollView()
        addDatesData()
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
           let iMDB {
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
           let locationId {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMovieImage()
        loadVenueImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    // MARK: - Setup Methods

    private func setupScrollView() {
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .white
        scrollView.contentSize = CGSize(width: view.frame.width, height: view.frame.height)
        view.addSubview(scrollView)
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
        let (width, height, x, y) = getResizedImageDimensions(for: moviePicture, startY: view.frame.height * 0.15)
        imageView.frame = CGRect(x: x, y: y, width: width, height: height)
        imageView.image = moviePicture
        scrollView.addSubview(imageView)
    }

    private func setupVenueImageView() {
        let (width, height, x, y) = getResizedImageDimensions(for: venuePicture, startY: view.frame.height * 0.85)
        venueImageView.frame = CGRect(x: x, y: y, width: width, height: height)
        venueImageView.image = venuePicture
        scrollView.addSubview(venueImageView)
    }

    private func setupUI() {
        setupButtons()
        setupTextView()
        setupPlayer()
    }

    private func setupButtons() {
        let buttonTitlesFirstRow = [("Book", #selector(book)), ("Dates", #selector(dates)), ("Map", #selector(map))]

        let buttonTitlesSecondRow = [("Movie Detail", #selector(movieDetail)), ("Calendar", #selector(selectCalendar))]

        let yOffset = imageView.frame.height + (view.frame.height / 6) + 150 // Adjust vertical position
        let buttonWidth: CGFloat = 100 // Set button width
        let spacing: CGFloat = 20 // Space between buttons
        let maxButtons = max(buttonTitlesFirstRow.count, buttonTitlesSecondRow.count)

        // Calculate total width needed for the row
        let totalWidth = (buttonWidth * CGFloat(maxButtons)) + (spacing * CGFloat(maxButtons - 1))
        let startX = (view.frame.width - totalWidth) / 2 // Center the buttons horizontally

        var xOffset = startX // Ensure both rows start at the same X position

        // First row
        for (title, selector) in buttonTitlesFirstRow {
            let button = createButton(title: title, y: yOffset, x: xOffset, width: buttonWidth)
            button.addTarget(self, action: selector, for: .touchUpInside)
            scrollView.addSubview(button)
            xOffset += buttonWidth + spacing
        }

        // Second row (directly below, properly aligned)
        let secondRowYOffset = yOffset + 50
        // Calculate total width needed for the row
        let totalWidth2 = (buttonWidth * CGFloat(maxButtons - 1)) + (spacing * CGFloat(maxButtons - 1))
        let startX2 = (view.frame.width - totalWidth2) / 2 // Center the buttons horizontally
        xOffset = startX2 // Reset xOffset for proper alignment

        for (title, selector) in buttonTitlesSecondRow {
            let button = createButton(title: title, y: secondRowYOffset, x: xOffset, width: buttonWidth)
            button.addTarget(self, action: selector, for: .touchUpInside)
            scrollView.addSubview(button)
            xOffset += buttonWidth + spacing
        }

        let btnNav = createUpperButton(title: "Back", action: #selector(navigateBack))
        view.addSubview(btnNav)
    }

    private func setupTextView() {
        let textViewFrame = CGRect(x: view.frame.size.width * 0.1, y: imageView.frame.height + 150, width: view.frame.size.width * 0.8, height: view.frame.height / 7)
        nameTextView = UITextView(frame: textViewFrame)
        nameTextView?.isEditable = false
        nameTextView?.textAlignment = .justified
        nameTextView?.alwaysBounceVertical = true
        nameTextView?.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .gray : .white
        }
        nameTextView?.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .black
        }
        nameTextView?.layer.borderWidth = 1

        if let movieDetails {
            let textAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Courier New", size: 13.0)!]
            nameTextView?.attributedText = NSAttributedString(string: movieDetails, attributes: textAttributes)
        }

        scrollView.addSubview(nameTextView!)
    }

    private func setupPlayer() {
        guard let fileURL = Bundle.main.path(forResource: "garnier1", ofType: "mov") else {
            print("File not found")
            return
        }

        let url = NSURL.fileURL(withPath: fileURL)
        let playerItem = AVPlayerItem(asset: AVAsset(url: url), automaticallyLoadedAssetKeys: ["playable"])
        let player = AVPlayer(playerItem: playerItem)

        let playerFrame = CGRect(x: 20, y: view.frame.height * 1.2, width: view.frame.width * 0.9, height: 300)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.view.frame = playerFrame
        addChild(playerViewController)

        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 55, right: 0)
        scrollView.contentSize.height = view.frame.height * 1.2 + 300

        scrollView.addSubview(playerViewController.view)
        playerViewController.didMove(toParent: self)
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

    private func createUpperButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 40)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
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
                    self.presentAlert(withTitle: "Error", message: error.localizedDescription)
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

    class HalfSizePresentationController: UIPresentationController {
        override var frameOfPresentedViewInContainerView: CGRect {
            CGRect(x: 0, y: 200, width: containerView!.bounds.width, height: containerView!.bounds.height)
        }
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

