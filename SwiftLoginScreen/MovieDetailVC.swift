//
//  MovieDetailVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2019. 12. 25..
//  Copyright © 2019. George Gaspar. All rights reserved.
//

import Foundation
import SafariServices
import SwiftyJSON
import UIKit

class MovieDetailVC: UIViewController, UIViewControllerTransitioningDelegate, UIScrollViewDelegate, HasAppServices {
    var appServices: AppServices!
    deinit {
        veil = true
        shouldShowSearchResults = false
        print(#function, "\(self)")
    }

    var iMDB: String!
    var movieId: Int!
    var movieName: String!
    var selectLarge_picture: String!
    var selectDetails: String!
    var selectVenues_picture: String!

    var origin: String!

    var scrollView: UIScrollView!
    var nameTextView: UITextView!
    var nameTextViewT: UITextView!
    var nameTextViewG: UITextView!
    var nameTextViewg: UITextView!

    lazy var titles = NSMutableArray()
    lazy var session = URLSession.sharedCustomSession
    lazy var url = URL(string: URLManager.login("/logout"))

    var running = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_: Bool) {
        injectAppServicesIfNeeded()

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.showsTouchWhenHighlighted = true
        btnNav.setTitle("Back", for: UIControl.State())
        btnNav.addTarget(self, action: #selector(MovieDetailVC.navigateBack), for: UIControl.Event.touchUpInside)

        let btnVenue = UIButton(frame: CGRect(x: view.frame.width / 2, y: 25, width: view.frame.width / 2, height: 20))
        btnVenue.backgroundColor = UIColor.black
        btnVenue.setTitle("Venues", for: UIControl.State())
        btnVenue.showsTouchWhenHighlighted = true
        btnVenue.addTarget(self, action: #selector(MovieDetailVC.Venues), for: UIControl.Event.touchUpInside)

        if origin != "VenuesDetailsVC" {
            view.addSubview(btnVenue)
        }
        view.addSubview(btnNav)

        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.frame = view.bounds
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = UIColor.white
        scrollView.contentSize = CGSize(width: view.frame.width, height: view.frame.height)
        scrollView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 55.0, right: 0.0)

        // title
        nameTextViewT = UITextView(frame: CGRect(x: view.frame.size.height * 0.05, y: view.frame.height * 0.15, width: view.frame.size.width * 0.8, height: view.frame.height / 7))
        nameTextViewT?.isEditable = false
        let myTextAttributeT = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier-Bold", size: 13.0)!]
        let detailTextT = NSMutableAttributedString(string: "Title", attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttributeT))
        nameTextViewT?.attributedText = detailTextT
        nameTextViewT?.textAlignment = NSTextAlignment.justified
        nameTextViewT?.alwaysBounceVertical = true

        // title text
        nameTextView = UITextView(frame: CGRect(x: view.frame.size.height * 0.05, y: view.frame.height * 0.18, width: view.frame.size.width * 0.8, height: view.frame.height / 7))
        nameTextView?.isEditable = false
        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailText = NSMutableAttributedString(string: "title", attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))
        nameTextView?.attributedText = detailText
        nameTextView?.textAlignment = NSTextAlignment.justified
        nameTextView?.alwaysBounceVertical = true

        // genre
        nameTextViewG = UITextView(frame: CGRect(x: view.frame.size.height * 0.05, y: view.frame.height * 0.24, width: view.frame.size.width * 0.8, height: view.frame.height / 7))
        nameTextViewG?.isEditable = false
        let myTextAttributeG = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier-Bold", size: 13.0)!]
        let detailTextG = NSMutableAttributedString(string: "Genre", attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttributeG))
        nameTextViewG?.attributedText = detailTextG
        nameTextViewG?.textAlignment = NSTextAlignment.justified
        nameTextViewG?.alwaysBounceVertical = true

        // genre text
        nameTextViewg = UITextView(frame: CGRect(x: view.frame.size.height * 0.05, y: view.frame.height * 0.27, width: view.frame.size.width * 0.8, height: view.frame.height / 7))
        nameTextViewg?.isEditable = false
        let myTextAttributeg = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailTextg = NSMutableAttributedString(string: "genre", attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttributeg))
        nameTextViewg?.attributedText = detailTextg
        nameTextViewg?.textAlignment = NSTextAlignment.justified
        nameTextViewg?.alwaysBounceVertical = true

        scrollView.addSubview(nameTextViewT!)
        scrollView.addSubview(nameTextView!)
        scrollView.addSubview(nameTextViewG!)
        scrollView.addSubview(nameTextViewg!)
        view.addSubview(scrollView)
        view.sendSubviewToBack(scrollView)

        addData()
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)

        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    @objc func navigateBack() {
        dismiss(animated: false, completion: nil)
    }

    @objc func Venues() {
        if VenuesFeatureFlags.shouldUseMigration() {
            presentVenuesMigration()
        } else {
            performSegue(withIdentifier: "goto_venues2", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_venues2" {
            let nextSegue = segue.destination as? VenuesVC

            nextSegue!.movieId = movieId
            nextSegue!.movieName = movieName
            nextSegue!.selectDetails = selectDetails
            nextSegue!.selectLarge_picture = selectLarge_picture
            nextSegue!.imdb = iMDB
        }
    }

    func addData() {
        let index = iMDB.index(iMDB.startIndex, offsetBy: 26)
        let mySubstring = String(iMDB[index...])

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let data = try await self.appServices.rapidMovieDatabase.imdbTitle(imdbId: mySubstring, realmCache: true)
                let json = try JSON(data: data)
                print(json)
                if let responseText = json["Title"].string {
                    self.nameTextView.text = responseText
                }
                if let responseText = json["Genre"].string {
                    self.nameTextViewg.text = responseText
                }
            } catch {
                NSLog("MovieDetailVC RapidAPI: %@", error.localizedDescription)
            }
        }
    }

    private func presentVenuesMigration() {
        injectAppServicesIfNeeded()

        let input = VenuesInput(
            movieId: movieId,
            movieName: movieName,
            selectLargePicture: selectLarge_picture,
            selectDetails: selectDetails,
            imdb: iMDB,
            mode: .standard
        )

        let migrationVC = VenuesMigrationFactory.make(input: input, mode: .standard, appServices: appServices)
        migrationVC.modalPresentationStyle = .fullScreen
        present(migrationVC, animated: true)
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
