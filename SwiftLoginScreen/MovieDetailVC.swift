// MovieDetailVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import SafariServices
import SwiftyJSON
import UIKit

class MovieDetailVC: UIViewController, UIViewControllerTransitioningDelegate, UIScrollViewDelegate, HasAppServices {
    // MARK: Lifecycle

    deinit {
        veil = true
        shouldShowSearchResults = false
        print(#function, "\(self)")
    }

    // MARK: Internal

    var appServices: AppServices!
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
        if let selectedMovie = MoviesDataManager.shared.selectedMovie {
            movieId = selectedMovie.movieId
            movieName = selectedMovie.name
            selectLarge_picture = selectedMovie.largePicture
            selectDetails = selectedMovie.detail
            iMDB = selectedMovie.imdbUrl
        }

        if origin != "VenuesDetailsVC" {
            addTopNavigationButtons([
                (title: "Back", action: #selector(MovieDetailVC.navigateBack)),
                (title: "Venues", action: #selector(MovieDetailVC.Venues)),
            ])
        } else {
            addTopNavigationButtons([
                (title: "Back", action: #selector(MovieDetailVC.navigateBack)),
            ])
        }

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

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_venues2", movieId != nil {
            MoviesDataManager.shared.selectedMovie = Movie(
                movieId: movieId,
                movieIdString: String(movieId),
                name: movieName,
                detail: selectDetails,
                largePicture: selectLarge_picture,
                imdbUrl: iMDB
            )
        }
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

    func addData() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let metadata = try await MoviesDataManager.shared.fetchMovieMetadata(imdbURL: self.iMDB)
                self.nameTextView.text = metadata.title
                self.nameTextViewg.text = metadata.genre
            } catch {
                NSLog("MovieDetailVC RapidAPI: %@", error.localizedDescription)
            }
        }
    }

    // MARK: Private

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

/// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    input.rawValue
}

/// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
