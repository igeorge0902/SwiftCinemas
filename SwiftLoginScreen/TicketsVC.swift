// TicketsVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import PDFKit
import UIKit

/**
 Displays ticket data for completed purchases.
 */
class TicketsVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, HasAppServices {
    // MARK: Lifecycle

    deinit {
        purchaseId = nil
        collectionData.removeAll()
        print(#function, "\(self)")
    }

    // MARK: Internal

    var appServices: AppServices!
    var collectionView: UICollectionView!

    var ResponseText: String?
    var ResponseCode: String?
    var AuthCode: String?
    var Status: String?
    var Amount: String?
    var TaxAmount: String?
    var movieName: String?
    var purchaseId: String!

    var pdfURL_: URL?
    var pdfNameFromUrl: String?

    lazy var filter = CIFilter(name: "CIQRCodeGenerator")

    var collectionData: [TicketDetailModel] = []
    lazy var layout = UICollectionViewFlowLayout()

    override func viewDidLoad() {
        super.viewDidLoad()

        injectAppServicesIfNeeded()

        navButtons = addTopNavigationButtons([
            (title: "Back", action: #selector(TicketsVC.navigateBack)),
            (title: "Pdf", action: #selector(TicketsVC.generatePdf)),
        ])

        title = "Tickets"

        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: view.frame.width * 0.9, height: view.frame.width * 0.5)

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(FeedCells.self, forCellWithReuseIdentifier: "FeedCell")
        collectionView.backgroundColor = UIColor(white: 0.95, alpha: 1)

        view.addSubview(collectionView)
        view.sendSubviewToBack(collectionView)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPress)

        configureRefreshToast()

        addData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutTopNavigationButtons(navButtons, topOffset: 8)
        let topButtonBottom = navButtons.map { $0.frame.maxY }.max() ?? (view.safeAreaInsets.top + 42)
        collectionView.frame = CGRect(
            x: 0,
            y: topButtonBottom + 8,
            width: view.bounds.width,
            height: max(0, view.bounds.height - topButtonBottom - 8)
        )
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func navigateBack() {
        dismiss(animated: false, completion: nil)
    }

    /// Close PDF View Function
    @objc func closePdfView() {
        pdfPreviewController = nil
        dismiss(animated: true, completion: nil)
    }

    @objc func generatePdf() {
        guard let pdfURL = createPDF(from: collectionView, filename: "tickets") else {
            print("Failed to create PDF")
            return
        }

        pdfURL_ = pdfURL // Store the PDF URL

        let pdfView = PDFView(frame: view.bounds)
        pdfView.autoScales = true
        if let document = PDFDocument(url: pdfURL) {
            pdfView.document = document
        }

        let pdfViewController = UIViewController()
        pdfViewController.view.backgroundColor = .white
        pdfViewController.view.addSubview(pdfView)
        pdfViewController.modalPresentationStyle = .fullScreen
        pdfPreviewController = pdfViewController

        // Create Share Button
        let shareButton = UIButton(frame: CGRect(x: 0, y: 50, width: view.frame.width / 2, height: 34))
        shareButton.setTitle("Share", for: UIControl.State.normal)
        stylePdfActionButton(shareButton)
        shareButton.addTarget(self, action: #selector(sharePdf), for: .touchUpInside)
        pdfViewController.view.addSubview(shareButton)

        // Create Close Button
        let closeButton = UIButton(frame: CGRect(x: view.frame.width / 2, y: 50, width: view.frame.width / 2, height: 34))
        closeButton.setTitle("Close", for: UIControl.State.normal)
        stylePdfActionButton(closeButton)
        closeButton.addTarget(self, action: #selector(closePdfView), for: .touchUpInside)
        pdfViewController.view.addSubview(closeButton)

        present(pdfViewController, animated: true, completion: nil)
    }

    @objc func sharePdf() {
        guard let pdfURL = pdfURL_, presentedViewController === pdfPreviewController else {
            presentAlert(withTitle: "Info", message: "Open PDF preview first to share.")
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { [weak self] _, completed, _, _ in
            guard let self, completed else { return }
            self.pdfPreviewController?.dismiss(animated: true)
            self.pdfPreviewController = nil
            self.addData()
            self.showTicketsRefreshedToast()
        }
        pdfPreviewController?.present(activityViewController, animated: true, completion: nil)
    }

    func createPDF(from collectionView: UICollectionView, filename: String) -> URL? {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, nil)

        for i in 0 ..< collectionView.numberOfItems(inSection: 0) {
            // Create a PDF page for each cell
            UIGraphicsBeginPDFPage()
            if let cell = collectionView.cellForItem(at: IndexPath(item: i, section: 0)) {
                if let image = cell.snapshot() {
                    let pdfPageFrame = CGRect(x: 0, y: 200, width: image.size.width, height: image.size.height)
                    image.draw(in: pdfPageFrame)
                }
            }
        }

        UIGraphicsEndPDFContext()

        let resourceDocPath = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last! as URL
        pdfNameFromUrl = "YourTickets-\(filename).pdf"
        let actualPath = resourceDocPath.appendingPathComponent(pdfNameFromUrl!)
        do {
            try pdfData.write(to: actualPath, options: .atomic)
            print("pdf successfully saved!")
            return actualPath
        } catch {
            print("Pdf could not be saved")
            return nil
        }
    }

    func addData() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let purchaseId = self.resolvedPurchaseId else {
                self.presentAlert(withTitle: "Warning!", message: "No purchase selected")
                return
            }
            do {
                self.collectionData = try await CheckoutDataManager.shared.fetchTickets(purchaseId: purchaseId)
                self.collectionData.sort { $0.seatNumber < $1.seatNumber }
                self.collectionView?.reloadData()
            } catch {
                NSLog("TicketsVC addData: %@", error.localizedDescription)
            }
        }
    }

    /**
     Method to delete tickets one by one
     */
    @objc func cancelTicket(button: UIButton, event _: UIEvent) {
        guard deleteArmedTicketIndex == button.tag else {
            presentAlert(withTitle: "Info", message: "Long-press a ticket first to reveal delete.")
            return
        }
        guard let purchaseId = resolvedPurchaseId else {
            presentAlert(withTitle: "Warning!", message: "No purchase selected")
            return
        }
        let ticketId = collectionData[button.tag].ticketId

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                if try await CheckoutDataManager.shared.cancelTickets(purchaseId: purchaseId, ticketIds: [ticketId]) {
                    self.collectionData.remove(at: button.tag)
                    self.deleteArmedTicketIndex = nil
                    self.collectionView.reloadData()
                    if self.collectionData.isEmpty {
                        NotificationCenter.default.post(
                            name: Notifications.purchaseDeletedFromTickets,
                            object: nil,
                            userInfo: ["purchaseId": purchaseId]
                        )
                        self.dismiss(animated: false, completion: nil)
                    }
                }
            } catch {
                NSLog("cancelTicket: %@", error.localizedDescription)
            }
        }
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        1
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        if collectionData.count > 0 {
            return collectionData.count
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

    func collectionView(_: UICollectionView, didSelectItemAt _: IndexPath) {}

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCell", for: indexPath) as! FeedCells

        cell.textLabel?.text = collectionData[indexPath.row].movieName
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.translatesAutoresizingMaskIntoConstraints = false

        let paragrapStyle = NSMutableParagraphStyle()
        paragrapStyle.lineSpacing = 4

        let title = NSMutableAttributedString(string: (cell.textLabel?.text!)!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 14.0)!]))

        title.append(NSAttributedString(string: "\n\(collectionData[indexPath.row].movieName)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 12.0)!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor(red: 155 / 255, green: 161 / 255, blue: 171 / 255, alpha: 1)])))

        title.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragrapStyle, range: NSMakeRange(0, title.string.count))
        cell.textLabel?.attributedText = title

        let urlMovie = URLManager.image(collectionData[indexPath.row].moviePicture)

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let imgData = try await self.appServices.images.getData(urlString: urlMovie, realmCache: true)
                let image = UIImage(data: imgData)
                cell.profileImage?.image = image
                cell.setNeedsLayout()
            } catch {
                NSLog("TicketsVC image: %@", error.localizedDescription)
            }
        }

        let text = NSMutableAttributedString(string: "Ticket details: \n Seat Row: \(collectionData[indexPath.row].seatRow), \n Seat Nr: \(collectionData[indexPath.row].seatNumber), \nDate of Screening: \n\(collectionData[indexPath.row].screeningDate), \n Venue: \(collectionData[indexPath.row].venueName)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 14.0)!]))

        cell.statusText?.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .gray : .white
        }
        cell.statusText?.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .black
        }
        cell.statusText?.attributedText = text

        cell.contentView.subviews.compactMap { $0 as? UIButton }.forEach { $0.removeFromSuperview() }
        let btn = UIButton(type: UIButton.ButtonType.custom) as UIButton
        btn.frame = cell.CancelImage!.frame
        btn.addTarget(self, action: #selector(TicketsVC.cancelTicket), for: .touchUpInside)
        btn.tag = indexPath.row
        btn.setImage(UIImage(named: "trash"), for: .normal)
        btn.isHidden = deleteArmedTicketIndex != indexPath.row
        cell.contentView.addSubview(btn)

        guard let filter,
              let data = collectionData[indexPath.row].seatNumber.data(using: .isoLatin1, allowLossyConversion: false)
        else {
            return cell
        }

        filter.setValue(data, forKey: "inputMessage")

        if let ciImage = filter.outputImage {
            let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            let uiImage = UIImage(ciImage: transformedImage)
            cell.QRCodeImage?.image = uiImage
        }
        return cell
    }

    func collectionView(_: UICollectionView, willDisplay _: UICollectionViewCell, forItemAt _: IndexPath) {}

    // MARK: Private

    private enum Notifications {
        static let purchaseDeletedFromTickets = Notification.Name("purchaseDeletedFromTickets")
    }

    private var navButtons: [UIButton] = []
    private var deleteArmedTicketIndex: Int?
    private weak var pdfPreviewController: UIViewController?
    private let ticketsRefreshedToast = UILabel()

    private var resolvedPurchaseId: String? {
        purchaseId ?? CheckoutDataManager.shared.selectedPurchaseId
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let location = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: location) else { return }
        deleteArmedTicketIndex = indexPath.row
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        collectionView.reloadData()
    }

    private func configureRefreshToast() {
        ticketsRefreshedToast.translatesAutoresizingMaskIntoConstraints = false
        ticketsRefreshedToast.isHidden = true
        ticketsRefreshedToast.backgroundColor = UIColor(red: 238 / 255, green: 243 / 255, blue: 1, alpha: 1)
        ticketsRefreshedToast.textColor = UIColor(red: 43 / 255, green: 79 / 255, blue: 147 / 255, alpha: 1)
        ticketsRefreshedToast.layer.cornerRadius = 10
        ticketsRefreshedToast.layer.masksToBounds = true
        ticketsRefreshedToast.font = .systemFont(ofSize: 12, weight: .regular)
        ticketsRefreshedToast.textAlignment = .center
        ticketsRefreshedToast.text = "PDF shared. Tickets screen refreshed."
        view.addSubview(ticketsRefreshedToast)

        NSLayoutConstraint.activate([
            ticketsRefreshedToast.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            ticketsRefreshedToast.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ticketsRefreshedToast.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ticketsRefreshedToast.heightAnchor.constraint(equalToConstant: 34),
        ])
    }

    private func showTicketsRefreshedToast() {
        ticketsRefreshedToast.alpha = 1
        ticketsRefreshedToast.isHidden = false
        UIView.animate(withDuration: 0.2, delay: 1.6, options: [.curveEaseOut], animations: {
            self.ticketsRefreshedToast.alpha = 0
        }, completion: { _ in
            self.ticketsRefreshedToast.isHidden = true
            self.ticketsRefreshedToast.alpha = 1
        })
    }

    private func stylePdfActionButton(_ button: UIButton) {
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.layer.cornerRadius = 12
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

extension UICollectionViewCell {
    func snapshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
