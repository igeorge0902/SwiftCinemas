//
//  HomeVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 27/03/16.
//  Copyright © 2016 George Gaspar. All rights reserved.

import CoreData
import SwiftyJSON
import UIKit
import WebKit

class HomeVC: UIViewController, UIViewControllerTransitioningDelegate, HasAppServices,
    UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
    UITableViewDataSource, UITableViewDelegate /* , WebSocketDelegate */ {

    deinit { print(#function, "\(self)") }

    var imageView: UIImageView!
    var appServices: AppServices!

    // MARK: - Trending state

    enum TrendingDisplayMode { case carousel, list }

    struct TrendingMovie {
        let movieId: Int
        let name: String
        let thumbnailPicture: String
        let largePicture: String
        let bookedTickets: Int
        let lastBookingTime: String?
        let descriptionText: String
    }

    private var trendingMovies: [TrendingMovie] = []
    private var displayMode: TrendingDisplayMode = .carousel
    private var isLoadingTrending = false
    private var trendingErrorMessage: String?

    // MARK: - Trending views

    private let trendingSectionContainer = UIView()
    private let trendingTitleLabel = UILabel()
    private let trendingStatusLabel = UILabel()
    private let restoreCarouselButton = UIButton(type: .system)
    private let trendingActivity = UIActivityIndicatorView(style: .medium)
    private let trendingContentContainer = UIView()
    private var carouselCollectionView: UICollectionView!
    private let trendingListTableView = UITableView(frame: .zero, style: .plain)
    private var trendingCollapsedHeightConstraint: NSLayoutConstraint?
    private var trendingExpandedBottomConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        injectAppServicesIfNeeded()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false

        imageView = UIImageView(frame: view.bounds)
        imageView.image = UIImage(named: "background1")
        view.addSubview(imageView)

        setupTrendingSectionUI()
        setupTrendingGestures()
        fetchTrendingMovies(days: 10000)
        MoviesData.addData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        if UserDefaults.standard.integer(forKey: "ISLOGGEDIN") != 1 {
            dismiss(animated: true)
            performSegue(withIdentifier: "goto_login", sender: self)
        }
    }

    // MARK: - Trending UI setup

    private func setupTrendingSectionUI() {
        trendingSectionContainer.translatesAutoresizingMaskIntoConstraints = false
        trendingSectionContainer.backgroundColor = UIColor(white: 0.08, alpha: 0.92)
        trendingSectionContainer.layer.cornerRadius = 14
        trendingSectionContainer.layer.shadowColor = UIColor.black.cgColor
        trendingSectionContainer.layer.shadowOpacity = 0.2
        trendingSectionContainer.layer.shadowRadius = 10
        trendingSectionContainer.layer.shadowOffset = CGSize(width: 0, height: 6)

        trendingTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        trendingTitleLabel.text = "Trending Movies"
        trendingTitleLabel.textColor = .white
        trendingTitleLabel.font = UIFont.boldSystemFont(ofSize: 20)

        trendingStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        trendingStatusLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        trendingStatusLabel.font = UIFont.systemFont(ofSize: 14)
        trendingStatusLabel.numberOfLines = 2
        trendingStatusLabel.isHidden = true
        trendingStatusLabel.isUserInteractionEnabled = true
        trendingStatusLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTrendingRetryTap)))

        restoreCarouselButton.translatesAutoresizingMaskIntoConstraints = false
        restoreCarouselButton.setTitle("Collapse", for: .normal)
        restoreCarouselButton.setImage(UIImage(systemName: "chevron.up.circle.fill"), for: .normal)
        restoreCarouselButton.tintColor = .white
        restoreCarouselButton.backgroundColor = UIColor(white: 0.22, alpha: 1.0)
        restoreCarouselButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        restoreCarouselButton.layer.cornerRadius = 14
        restoreCarouselButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        restoreCarouselButton.semanticContentAttribute = .forceLeftToRight
        restoreCarouselButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
        restoreCarouselButton.isHidden = true
        restoreCarouselButton.addTarget(self, action: #selector(handleRestoreCarouselTap), for: .touchUpInside)

        trendingActivity.translatesAutoresizingMaskIntoConstraints = false
        trendingActivity.color = UIColor(white: 0.9, alpha: 1.0)
        trendingActivity.hidesWhenStopped = true

        trendingContentContainer.translatesAutoresizingMaskIntoConstraints = false
        trendingContentContainer.backgroundColor = .clear

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 8

        carouselCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        carouselCollectionView.translatesAutoresizingMaskIntoConstraints = false
        carouselCollectionView.backgroundColor = .clear
        carouselCollectionView.showsHorizontalScrollIndicator = false
        carouselCollectionView.dataSource = self
        carouselCollectionView.delegate = self
        carouselCollectionView.register(TrendingCarouselCell.self, forCellWithReuseIdentifier: "TrendingCarouselCell")

        trendingListTableView.translatesAutoresizingMaskIntoConstraints = false
        trendingListTableView.backgroundColor = .clear
        trendingListTableView.separatorStyle = .singleLine
        trendingListTableView.separatorColor = UIColor(white: 0.32, alpha: 1.0)
        trendingListTableView.estimatedRowHeight = 113
        trendingListTableView.rowHeight = 113
        trendingListTableView.dataSource = self
        trendingListTableView.delegate = self
        trendingListTableView.register(TrendingListCell.self, forCellReuseIdentifier: "TrendingListCell")
        trendingListTableView.isHidden = true

        view.addSubview(trendingSectionContainer)
        trendingSectionContainer.addSubview(trendingTitleLabel)
        trendingSectionContainer.addSubview(restoreCarouselButton)
        trendingSectionContainer.addSubview(trendingStatusLabel)
        trendingSectionContainer.addSubview(trendingActivity)
        trendingSectionContainer.addSubview(trendingContentContainer)
        trendingContentContainer.addSubview(carouselCollectionView)
        trendingContentContainer.addSubview(trendingListTableView)

        let safe = view.safeAreaLayoutGuide
        trendingCollapsedHeightConstraint = trendingSectionContainer.heightAnchor.constraint(equalToConstant: 286)
        trendingExpandedBottomConstraint = trendingSectionContainer.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -12)

        NSLayoutConstraint.activate([
            trendingSectionContainer.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 12),
            trendingSectionContainer.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -12),
            trendingSectionContainer.topAnchor.constraint(equalTo: safe.topAnchor, constant: 84),

            trendingTitleLabel.leadingAnchor.constraint(equalTo: trendingSectionContainer.leadingAnchor, constant: 16),
            trendingTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: restoreCarouselButton.leadingAnchor, constant: -8),
            trendingTitleLabel.topAnchor.constraint(equalTo: trendingSectionContainer.topAnchor, constant: 14),

            restoreCarouselButton.trailingAnchor.constraint(equalTo: trendingSectionContainer.trailingAnchor, constant: -12),
            restoreCarouselButton.centerYAnchor.constraint(equalTo: trendingTitleLabel.centerYAnchor),
            restoreCarouselButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 28),

            trendingStatusLabel.leadingAnchor.constraint(equalTo: trendingSectionContainer.leadingAnchor, constant: 16),
            trendingStatusLabel.trailingAnchor.constraint(equalTo: trendingSectionContainer.trailingAnchor, constant: -16),
            trendingStatusLabel.topAnchor.constraint(equalTo: trendingTitleLabel.bottomAnchor, constant: 6),

            trendingActivity.centerXAnchor.constraint(equalTo: trendingSectionContainer.centerXAnchor),
            trendingActivity.centerYAnchor.constraint(equalTo: trendingSectionContainer.centerYAnchor, constant: 10),

            trendingContentContainer.leadingAnchor.constraint(equalTo: trendingSectionContainer.leadingAnchor, constant: 12),
            trendingContentContainer.trailingAnchor.constraint(equalTo: trendingSectionContainer.trailingAnchor, constant: -12),
            trendingContentContainer.bottomAnchor.constraint(equalTo: trendingSectionContainer.bottomAnchor, constant: -12),
            trendingContentContainer.topAnchor.constraint(equalTo: trendingStatusLabel.bottomAnchor, constant: 8),

            carouselCollectionView.leadingAnchor.constraint(equalTo: trendingContentContainer.leadingAnchor),
            carouselCollectionView.trailingAnchor.constraint(equalTo: trendingContentContainer.trailingAnchor),
            carouselCollectionView.topAnchor.constraint(equalTo: trendingContentContainer.topAnchor),
            carouselCollectionView.bottomAnchor.constraint(equalTo: trendingContentContainer.bottomAnchor),

            trendingListTableView.leadingAnchor.constraint(equalTo: trendingContentContainer.leadingAnchor),
            trendingListTableView.trailingAnchor.constraint(equalTo: trendingContentContainer.trailingAnchor),
            trendingListTableView.topAnchor.constraint(equalTo: trendingContentContainer.topAnchor),
            trendingListTableView.bottomAnchor.constraint(equalTo: trendingContentContainer.bottomAnchor)
        ])

        setDisplayMode(.carousel, animated: false)
    }

    private func setupTrendingGestures() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleTrendingSwipeDown))
        swipeDown.direction = .down
        swipeDown.delegate = self
        trendingContentContainer.addGestureRecognizer(swipeDown)
    }

    // MARK: - Trending actions

    @objc private func handleTrendingSwipeDown() {
        guard !trendingMovies.isEmpty else { return }
        print("HomeVC.trending mode switch: carousel -> list")
        setDisplayMode(.list, animated: true)
    }

    @objc private func handleRestoreCarouselTap() {
        guard !trendingMovies.isEmpty else { return }
        print("HomeVC.trending mode switch: list -> carousel")
        setDisplayMode(.carousel, animated: true)
    }

    @objc private func handleTrendingRetryTap() {
        guard !isLoadingTrending else { return }
        fetchTrendingMovies()
    }

    // MARK: - Trending data

    private func fetchTrendingMovies(days: Int? = nil) {
        guard appServices != nil else { return }
        isLoadingTrending = true
        trendingErrorMessage = nil
        updateTrendingStateUI()

        let started = Date()
        print("HomeVC.trending request start days=\(days.map(String.init) ?? "default") limit=5")

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let data = try await self.appServices.mbooks.trendingMovies(limit: 5, days: days)
                self.trendingMovies = self.parseTrendingMovies(from: data)
                self.isLoadingTrending = false
                self.trendingErrorMessage = nil
                print("HomeVC.trending ok count=\(self.trendingMovies.count) ms=\(Int(Date().timeIntervalSince(started) * 1000))")
                self.carouselCollectionView.reloadData()
                self.trendingListTableView.reloadData()
                self.setDisplayMode(.carousel, animated: false)
                self.updateTrendingStateUI()
            } catch {
                self.isLoadingTrending = false
                self.trendingMovies.removeAll()
                self.trendingErrorMessage = "Could not load trending movies. Tap to retry."
                print("HomeVC.trending failed ms=\(Int(Date().timeIntervalSince(started) * 1000)) error=\(error)")
                self.carouselCollectionView.reloadData()
                self.trendingListTableView.reloadData()
                self.updateTrendingStateUI()
            }
        }
    }

    private func parseTrendingMovies(from data: Data) -> [TrendingMovie] {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let list = root["trendingMovies"] as? [[String: Any]]
        else { return [] }

        return list.map { row in
            let name = (row["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let bookedTickets = row["bookedTickets"] as? Int ?? 0
            let rawDesc = (row["description"] as? String ?? row["overview"] as? String ?? row["plot"] as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let description = rawDesc.isEmpty
                ? (bookedTickets > 0 ? "Popular pick with \(bookedTickets) ticket(s) recently booked." : "Trending now.")
                : rawDesc
            return TrendingMovie(
                movieId: row["movieId"] as? Int ?? 0,
                name: name.isEmpty ? "Untitled" : name,
                thumbnailPicture: row["thumbnail_picture"] as? String ?? "",
                largePicture: row["large_picture"] as? String ?? "",
                bookedTickets: bookedTickets,
                lastBookingTime: row["lastBookingTime"] as? String,
                descriptionText: description
            )
        }
    }

    private func updateTrendingStateUI() {
        if isLoadingTrending {
            trendingStatusLabel.text = "Loading trending movies..."
            trendingStatusLabel.isHidden = false
            trendingContentContainer.isHidden = true
            trendingActivity.startAnimating()
            return
        }
        trendingActivity.stopAnimating()
        if let msg = trendingErrorMessage {
            trendingStatusLabel.text = msg
            trendingStatusLabel.isHidden = false
            trendingContentContainer.isHidden = true
            return
        }
        if trendingMovies.isEmpty {
            trendingStatusLabel.text = "No trending movies available."
            trendingStatusLabel.isHidden = false
            trendingContentContainer.isHidden = true
            return
        }
        trendingStatusLabel.isHidden = true
        trendingContentContainer.isHidden = false
    }

    private func setDisplayMode(_ mode: TrendingDisplayMode, animated: Bool) {
        displayMode = mode
        let isCarousel = mode == .carousel

        NSLayoutConstraint.deactivate([trendingCollapsedHeightConstraint, trendingExpandedBottomConstraint].compactMap { $0 })
        NSLayoutConstraint.activate([(isCarousel ? trendingCollapsedHeightConstraint : trendingExpandedBottomConstraint)].compactMap { $0 })

        restoreCarouselButton.isHidden = isCarousel

        let updates = {
            self.carouselCollectionView.isHidden = !isCarousel
            self.trendingListTableView.isHidden = isCarousel
            self.view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseInOut, animations: updates)
        } else {
            updates()
        }
    }

    // MARK: - Image loading

    private func loadImage(from url: URL, into imageView: UIImageView) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let data = try await self.appServices.images.getData(urlString: url.absoluteString, realmCache: true)
                if let image = UIImage(data: data) { imageView.image = image }
            } catch {
                NSLog("HomeVC.loadImage: %@", error.localizedDescription)
            }
        }
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        trendingMovies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrendingCarouselCell", for: indexPath) as? TrendingCarouselCell else {
            return UICollectionViewCell()
        }
        let movie = trendingMovies[indexPath.item]
        cell.configure(title: movie.name)
        if let url = URL(string: URLManager.image(movie.largePicture)) {
            loadImage(from: url, into: cell.posterImageView)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 122, height: max(160, collectionView.bounds.height - 8))
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        trendingMovies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TrendingListCell", for: indexPath) as? TrendingListCell else {
            return UITableViewCell()
        }
        let movie = trendingMovies[indexPath.row]
        cell.configure(title: movie.name, description: movie.descriptionText)
        if let url = URL(string: URLManager.image(movie.largePicture)) {
            loadImage(from: url, into: cell.posterImageView)
        }
        return cell
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_map" {
            (segue.destination as? MapViewController)?.map2 = false
        }
    }

    @IBAction func basket(_: UIButton) {
        guard BasketData_.count > 0 else {
            UIAlertController.popUp(title: "Warning!", message: "No free seat(s) to be reserved!")
            return
        }
        let pvc = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewController(withIdentifier: "Basket")
        pvc.modalPresentationStyle = .custom
        pvc.transitioningDelegate = self
        present(pvc, animated: true)
    }

    @IBAction func NearbyVenues(_: UIButton) {
        performSegue(withIdentifier: "goto_map", sender: self)
    }

    @IBAction func Navigation(_: UIButton) {
        let sheet = UIAlertController(title: "Action Sheet", message: "Choose an option!", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheet.addAction(UIAlertAction(title: "Go to Menu", style: .default) { [weak self] _ in
            self?.performSegue(withIdentifier: "goto_menu", sender: self)
        })
        sheet.addAction(UIAlertAction(title: "Go to Login Screen", style: .default) { [weak self] _ in
            UserDefaults.standard.set(0, forKey: "ISLOGGEDIN")
            self?.dismiss(animated: true)
            self?.performSegue(withIdentifier: "goto_login", sender: self)
        })
        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController?.present(sheet, animated: true)
        }
    }

    @IBAction func WebView(_: UIButton) {
        presentedViewController?.removeFromParent()
        performSegue(withIdentifier: "goto_webview", sender: self)
    }

    @IBAction func Movies(_: UIButton) {
        performSegue(withIdentifier: "goto_movies", sender: self)
    }
}

extension UIViewController {
    func presentAlert(withTitle title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func presentAlertWithFunction(withTitle title: String, message: String, function: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action: UIAlertAction
        if function == "sendEmail" {
            action = UIAlertAction(title: "OK", style: .default) { _ in
                let user = UserDefaults.standard.value(forKey: "USERNAME")
                Task { @MainActor in
                    guard let app = UIApplication.shared.delegate as? AppDelegate,
                          let userStr = user as? String else { return }
                    do {
                        let data = try await app.services.loginGateway.postActivation(deviceId: deviceId, user: userStr)
                        print(String(data: data, encoding: .utf8) ?? "")
                    } catch { print(error) }
                }
            }
        } else {
            action = UIAlertAction(title: "OK", style: .default)
        }
        alert.addAction(action)
        present(alert, animated: true)
    }
}
