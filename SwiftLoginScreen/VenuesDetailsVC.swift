//
//  VenuesDetailsVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 27/03/16.
//  Copyright © 2016 George Gaspar. All rights reserved.

import Contacts
import CoreData

import AVKit

// import FacebookShare
// import FacebookLogin
// import FacebookCore
import EventKit
import SwiftyJSON
import UIKit
import WebKit

var selectedCalendar: String?
class VenuesDetailsVC: UIViewController, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, UIViewControllerTransitioningDelegate {
    deinit {
        screeningDateId = nil
        ScreeningDates.removeAll()
        // NotificationCenter.default.post(name: NSNotification.Name(rawValue: "navigateBack"), object: nil)
        mapview_ = nil
        print(#function, "\(self)")
    }

    // MARK: - Properties

    lazy var noPicture: [String: String] = [:]
    let pickerData: NSDictionary = ["screeningDatesId": 0, "screeningDate": "Select date", "movieId": 0]

    var nameTextView: UITextView?
    var selectVenues_picture: String?
    var selectLarge_picture: String?
    var selectVenueId: Int?
    var venueName: String?
    var selectAddress: String?
    var movieId: Int!
    var movieName: String?
    var movieDetails: String?
    var screen_screenId: String?
    var locationId: Int!
    var iMDB: String?

    var startY: CGFloat!
    var imageHeight: CGFloat!
    var popOverY: CGFloat!

    lazy var imageView = UIImageView()
    lazy var venueImageView = UIImageView()
    var scrollView: UIScrollView!

    lazy var icons: [String: String] = [
        "Calendar-icon": "calendar-icon",
        "iCal-icon": "ical",
        "FBShare": "facebook_share",
    ]

    lazy var googleCalendar = UIImageView()
    lazy var ical = UIImageView()
    lazy var fbShare = UIImageView()

    lazy var moviePicture = UIImage()
    lazy var venuePicture = UIImage()

    lazy var google = UIImage()
    lazy var ios = UIImage()
    lazy var fb = UIImage()

    var calendars: [EKCalendar]?
    let eventStore = EKEventStore()
    var playerItemContext = 0

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        addDatesData()
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
        guard let selectLargePicture = selectLarge_picture else { return }
        let urlString = serverURL + "/simple-service-webapp/webapi" + selectLargePicture

        var loadPictures: GeneralRequestManager?
        loadPictures = GeneralRequestManager(url: urlString, errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: "1", contentType: "", bodyToPost: nil)

        loadPictures?.getData_ {
            (data: Data, _: NSError?) in
            let image = UIImage(data: data)
            self.moviePicture = image!
            self.setupMovieImageView()
        }
    }

    private func loadVenueImage() {
        if let selectVenuesPicture = selectVenues_picture, !selectVenuesPicture.isEmpty {
            let urlString = serverURL + "/simple-service-webapp/webapi" + selectVenuesPicture

            var loadPictures: GeneralRequestManager?
            loadPictures = GeneralRequestManager(url: urlString, errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: "1", contentType: "", bodyToPost: nil)

            loadPictures?.getData_ {
                (data: Data, _: NSError?) in
                let image = UIImage(data: data)
                self.venuePicture = image!
                self.setupVenueImageView()
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
            let nextSegue = segue.destination as? MapViewController
            nextSegue?.selectVenueId = selectVenueId
            nextSegue?.map2 = true
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

        if screeningDateId == nil {
            let alertView = UIAlertView()

            alertView.title = "Warning!"
            alertView.message = "Select dates first!"
            alertView.delegate = self
            alertView.addButton(withTitle: "OK")
            alertView.show()

        } else {
            SelectMovieName = movieName
            SelectVenueForMovie = selectAddress
            SelectVenueName = venueName
            SelectMoviePicture = serverURL + "/simple-service-webapp/webapi" + selectLarge_picture!

            SeatsData.addData(Int(screeningDateId!)!)

            let popOver = PopOver()
            popOver.modalPresentationStyle = UIModalPresentationStyle.popover
            popOver.preferredContentSize = CGSize(width: view.frame.width * 0.90, height: view.frame.height / 2)

            let popoverMenuViewController = popOver.popoverPresentationController
            popoverMenuViewController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)

            popoverMenuViewController?.delegate = self
            popoverMenuViewController?.sourceView = view
            popoverMenuViewController!.sourceRect = CGRect(
                x: view.frame.width * 0.50,
                y: popOverY,
                width: 0,
                height: 0
            )

            present(
                popOver,
                animated: true,
                completion: {
                    //   let frameM = CGRect(x: self.scrollView.frame.width * 0.35, y: 0, width: 44, height: 20)

                    //   self.scrollView.scrollRectToVisible(frameM, animated: true)
                }
            )
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

        let popOver = PopOverDates()
        popOver.modalPresentationStyle = UIModalPresentationStyle.popover
        popOver.preferredContentSize = CGSize(width: view.frame.width * 0.90, height: view.frame.height / 5)

        let popoverMenuViewController = popOver.popoverPresentationController
        popoverMenuViewController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)

        popoverMenuViewController?.delegate = self
        popoverMenuViewController?.sourceView = view
        popoverMenuViewController!.sourceRect = CGRect(
            x: view.frame.width * 0.50,
            y: popOverY,
            width: 0,
            height: 0
        )

        present(
            popOver,
            animated: true,
            completion: nil
        )
    }

    @objc func selectCalendar(_: UIButton) {
        if screeningDateId == nil {
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

                    SelectMovieName = self.movieName
                    SelectVenueForMovie = self.selectAddress

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
        var errorOnLogin: GeneralRequestManager?

        // TODO: check it on the server side
        errorOnLogin = GeneralRequestManager(url: serverURL + "/mbooks-1/rest/book/dates/" + String(locationId) + "/" + String(movieId), errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: nil, contentType: "", bodyToPost: nil)

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

    @objc func selectCalendar_(sender _: UIButton /* , event: UIEvent */ ) {
        if screeningDateId == nil {
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

                    SelectMovieName = self.movieName
                    SelectVenueForMovie = self.selectAddress
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

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
