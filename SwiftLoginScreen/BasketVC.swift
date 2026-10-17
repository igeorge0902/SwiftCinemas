// BasketVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import BraintreeCard
import BraintreeUIComponents
import Foundation
import SwiftUI
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

    /// Guards against duplicate checkout submissions: set when the checkout flow starts
    /// (client-token fetch) and cleared on cancel, error, or when the server checkout finishes.
    private(set) var isCheckoutInProgress = false

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
            guard !isCheckoutInProgress else { return }
            // postNonceToServer(nonce!)
            getClientToken()
        }
    }

    func getClientToken() {
        isCheckoutInProgress = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let token = try await CheckoutDataManager.shared.fetchClientToken()
                self.clientToken = token.clientToken
                self.showCardFields(clientTokenOrTokenizationKey: token.clientToken)
            } catch {
                NSLog("getClientToken: %@", error.localizedDescription)
                self.isCheckoutInProgress = false
                self.presentAlert(withTitle: "Payment error", message: error.localizedDescription)
            }
        }
    }

    /// Presents Braintree's SwiftUI `CardFields` (replacement for the deprecated Drop-in UI)
    /// in a `UIHostingController`. The resulting nonce is passed to the existing `postNonceToServer`.
    func showCardFields(clientTokenOrTokenizationKey: String) {
        var hostRef: UIViewController?

        let checkoutView = CardCheckoutView(
            authorization: clientTokenOrTokenizationKey,
            onNonce: { [weak self] nonce in
                hostRef?.dismiss(animated: true) {
                    self?.postNonceToServer(nonce)
                }
            },
            onError: { [weak self] error in
                NSLog("CardFields tokenization: %@", error.localizedDescription)
                hostRef?.dismiss(animated: true) {
                    self?.isCheckoutInProgress = false
                    self?.presentAlert(withTitle: "Payment error", message: error.localizedDescription)
                }
            },
            onCancel: { [weak self] in
                hostRef?.dismiss(animated: true) {
                    self?.isCheckoutInProgress = false
                }
            }
        )

        let host = UIHostingController(rootView: checkoutView)
        // Require explicit Cancel/Pay so the in-progress flag is always cleared.
        host.isModalInPresentation = true
        hostRef = host
        present(host, animated: true, completion: nil)
    }

    func postNonceToServer(_ paymentMethodNonce: String) {
        isCheckoutInProgress = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.isCheckoutInProgress = false }
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
                self.presentAlert(withTitle: "Payment error", message: error.localizedDescription)
            }
        }
    }

    // MARK: Private

    private var topNavigationButtons: [UIButton] = []
}

// MARK: - CardCheckoutView

/// SwiftUI card entry sheet built on Braintree `CardFields`.
/// `CardFields` has no submit button, so Pay is enabled only when the form is valid
/// and disabled while tokenization is in flight to prevent duplicate submission.
struct CardCheckoutView: View {
    let authorization: String
    let onNonce: (String) -> Void
    let onError: (Error) -> Void
    let onCancel: () -> Void

    @State private var isValid = false
    @State private var tokenize: (() -> Void)?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    CardFields(authorization: authorization, card: BTCard()) { nonce, error in
                        if let nonce {
                            onNonce(nonce.nonce)
                        } else {
                            isSubmitting = false
                            if let error {
                                onError(error)
                            }
                        }
                    }
                    .onValidityChange { valid, tokenizeAction in
                        isValid = valid
                        tokenize = tokenizeAction
                    }
                    .disabled(isSubmitting)

                    Button {
                        guard isValid, !isSubmitting, let tokenize else { return }
                        isSubmitting = true
                        tokenize()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Pay")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid || isSubmitting)
                    .accessibilityIdentifier("cardFieldsPayButton")
                }
                .padding()
            }
            .navigationTitle("Card payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .disabled(isSubmitting)
                        .accessibilityIdentifier("cardFieldsCancelButton")
                }
            }
        }
    }
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
