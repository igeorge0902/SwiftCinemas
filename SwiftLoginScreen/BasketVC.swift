// BasketVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import BraintreeDropIn
import Foundation
import UIKit

class BasketVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, HasAppServices {
    // MARK: Lifecycle

    deinit {
        tableView_?.reloadData()
        print(#function, "\(self)")
    }

    // MARK: Internal

    var appServices: AppServices!
    var collectionView: UICollectionView!
    var clientToken: String?

    lazy var layout = UICollectionViewFlowLayout()

    var values: [BasketItem] {
        [BasketItem](BasketDataManager.shared.basketItemsBySeatId.values.sorted { $0.movieName < $1.movieName })
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        injectAppServicesIfNeeded()

        layout.sectionInset = UIEdgeInsets(top: 12, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: view.frame.width * 0.9, height: view.frame.width * 0.5)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(FeedCells.self, forCellWithReuseIdentifier: "FeedCell")
        collectionView.backgroundColor = UIColor(white: 0.95, alpha: 1)

        view.addSubview(collectionView)
        view.sendSubviewToBack(collectionView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        topNavigationButtons = addTopNavigationButtons([
            (title: "‹ Back", action: #selector(BasketVC.navigateBack)),
            (title: "CheckOut", action: #selector(BasketVC.book)),
        ], topOffset: 12)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        layoutTopNavigationButtons(topNavigationButtons, topOffset: 12)

        let topContentY = (topNavigationButtons.first?.frame.maxY ?? (view.safeAreaInsets.top + 46)) + 10
        collectionView.frame = CGRect(
            x: 0,
            y: topContentY,
            width: view.bounds.width,
            height: max(0, view.bounds.height - topContentY)
        )
        layout.itemSize = CGSize(width: view.bounds.width * 0.9, height: view.bounds.width * 0.5)
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func navigateBack() {
        dismiss(animated: true, completion: nil)
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        1
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        if !BasketDataManager.shared.basketItemsBySeatId.isEmpty {
            return BasketDataManager.shared.basketItemsBySeatId.count
        }

        return 0
    }

    func collectionView(_: UICollectionView, shouldHighlightItemAt _: IndexPath) -> Bool {
        true
    }

    func collectionView(_: UICollectionView, shouldSelectItemAt _: IndexPath) -> Bool {
        true
    }

    func collectionView(_: UICollectionView, canPerformAction _: Selector, forItemAt _: IndexPath, withSender _: Any?) -> Bool {
        true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //   let cell = collectionView.cellForItem(at: indexPath)

        let seatId = values[indexPath.row].seatId
        let seatNr = values[indexPath.row].seatNumber
        let screeningDateId = values[indexPath.row].screeningDateId

        if let current = BasketDataManager.shared.seatsToReservePayloadByScreening[screeningDateId] {
            let updated = current.replacingOccurrences(of: seatNr + "-", with: "")
            if updated.isEmpty {
                BasketDataManager.shared.seatsToReservePayloadByScreening.removeValue(forKey: screeningDateId)
            } else {
                BasketDataManager.shared.seatsToReservePayloadByScreening[screeningDateId] = updated
            }
        }

        BasketDataManager.shared.basketItemsBySeatId.removeValue(forKey: seatId)
        SeatsDataManager.shared.selectedSeatIds.removeAll { $0 == seatId }
        SeatsDataManager.shared.selectedSeatNumbers.removeAll { $0 == seatNr }
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCell", for: indexPath) as! FeedCells

        cell.textLabel?.text = values[indexPath.row].movieName
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.translatesAutoresizingMaskIntoConstraints = false

        let paragrapStyle = NSMutableParagraphStyle()
        paragrapStyle.lineSpacing = 4

        let title = NSMutableAttributedString(string: (cell.textLabel?.text!)!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 14.0)!]))

        title.append(NSAttributedString(string: "\n\(values[indexPath.row].venueName)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 12.0)!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor(red: 155 / 255, green: 161 / 255, blue: 171 / 255, alpha: 1)])))

        title.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragrapStyle, range: NSMakeRange(0, title.string.count))

        // TODO: add map pointing to the venue
        let icon = NSTextAttachment()
        icon.image = UIImage(named: "Shit Hits Fan-25")
        icon.bounds = CGRect(x: 0, y: -2, width: 12, height: 12)

        title.append(NSAttributedString(attachment: icon))

        cell.textLabel?.attributedText = title

        /*
         if let urlMovie = URL(string: values[indexPath.row].movie_picture) {
             print(values[indexPath.row].movie_picture)
             if let movieImage = try? Data(contentsOf: urlMovie) {
                 cell.profileImage?.image = UIImage(data: movieImage)
             }
         }
         */
        let urlString = values[indexPath.row].moviePicture

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let data = try await self.appServices.images.getData(urlString: urlString, realmCache: true)
                let image = UIImage(data: data)
                cell.profileImage?.image = image
            } catch {
                NSLog("BasketVC image: %@", error.localizedDescription)
            }
        }

        let text = NSMutableAttributedString(string: "Ticket details: \n Seat Row: \(values[indexPath.row].seatRow), \n Seat Nr: \(values[indexPath.row].seatNumber), \nDate of Screening: \n\(values[indexPath.row].screeningDateText)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 14.0)!]))

        cell.statusText?.attributedText = text

        return cell
    }

    func collectionView(_: UICollectionView, willDisplay _: UICollectionViewCell, forItemAt _: IndexPath) {}

    /**
     Calls the func checkOutWithCards() to initiate the checking out process.

     @return
     */
    @objc func book() {
        if BasketDataManager.shared.basketItemsBySeatId.isEmpty {
            presentAlert(withTitle: "Warning!", message: "Select free seat(s) first!")

        } else {
            // postNonceToServer(nonce!)
            getClientToken()
        }
    }

    func getClientToken() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let token = try await CheckoutDataManager.shared.fetchClientToken()
                self.clientToken = token.clientToken
                self.showDropIn(clientTokenOrTokenizationKey: token.clientToken)
            } catch {
                NSLog("getClientToken: %@", error.localizedDescription)
            }
        }
    }

    func showDropIn(clientTokenOrTokenizationKey: String) {
        let request = BTDropInRequest()
        let dropIn = BTDropInController(authorization: clientTokenOrTokenizationKey, request: request) { controller, result, error in
            if error != nil {
                print("ERROR")
            } else if result?.isCanceled == true {
                print("CANCELLED")
            } else if let result {
                guard let nonce = result.paymentMethod?.nonce
                else {
                    controller.dismiss(animated: true, completion: nil)
                    return
                }
                self.postNonceToServer(nonce)
                // Use the BTDropInResult properties to update your UI
                // result.paymentOptionType
                // result.paymentMethod
                // result.paymentIcon
                // result.paymentDescription
            }
            controller.dismiss(animated: true, completion: nil)
        }
        present(dropIn!, animated: true, completion: nil)
    }

    func postNonceToServer(_ paymentMethodNonce: String) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let orderId = String(zeroTime(0).getCurrentMillis())
                let seatsPayload = try BasketDataManager.shared.makeSeatsToBeReservedPayload()
                let result = try await CheckoutDataManager.shared.checkout(
                    paymentMethodNonce: paymentMethodNonce,
                    orderId: orderId,
                    seatsToBeReserved: seatsPayload
                )

                SeatsDataManager.shared.allSeats = result.reservedSeats

                if result.isSuccess {
                    let ticketSummary = result.tickets.map(\.seatNumber).minimalDescrption
                    self.presentAlert(
                        withTitle: "Payment info:",
                        message: "ResponseText: \(result.responseText ?? "success"), Status: \(result.status ?? "success"), Amount: \(result.amount ?? ""), TaxAmount: \(result.taxAmount ?? ""), Seats: \(ticketSummary)"
                    )

                    BasketDataManager.shared.resetNavigationContext()
                    SeatsDataManager.shared.resetNavigationContext()
                    DatesDataManager.shared.resetNavigationContext()
                    self.collectionView.reloadData()
                } else if let failedTicket = result.failedTickets.first {
                    self.presentAlert(
                        withTitle: "Booking failed with payment info:",
                        message: "Failed tickets for movie: \(failedTicket.movieName), seats_seatNumber: \(failedTicket.seatNumber), ResponseText: \(result.errorMessage ?? "Payment failed")"
                    )
                } else {
                    self.presentAlert(
                        withTitle: "Booking failed with payment info:",
                        message: "Payment error: \(result.errorMessage ?? "Unknown error")"
                    )
                }
            } catch {
                NSLog("postNonceToServer: %@", error.localizedDescription)
            }
        }
    }

    // MARK: Private

    private var topNavigationButtons: [UIButton] = []
}

/// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

/// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    input.rawValue
}
