//
//  TicketsVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2017. 09. 16..
//  Copyright © 2017. George Gaspar. All rights reserved.
//

import Foundation
import PDFKit
import SwiftyJSON
import UIKit

/**
 Stores BasketData objects representing basket items.
 */
class TicketsVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, HasAppServices {
    var appServices: AppServices!
    deinit {
        purchaseId = nil
        CollectionData.removeAll()
        print(#function, "\(self)")
    }

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

    var CollectionData: [AllTicketsData] = .init()
    lazy var layout = UICollectionViewFlowLayout()

    override func viewDidLoad() {
        super.viewDidLoad()

        injectAppServicesIfNeeded()

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.showsTouchWhenHighlighted = true
        btnNav.setTitle("Back", for: UIControl.State.normal)
        btnNav.addTarget(self, action: #selector(TicketsVC.navigateBack), for: UIControl.Event.touchUpInside)

        view.addSubview(btnNav)

        let btnPdf = UIButton(frame: CGRect(x: view.frame.width / 2, y: 25, width: view.frame.width / 2, height: 20))
        btnPdf.backgroundColor = UIColor.black
        btnPdf.showsTouchWhenHighlighted = true
        btnPdf.setTitle("Pdf", for: UIControl.State.normal)
        btnPdf.addTarget(self, action: #selector(TicketsVC.generatePdf), for: UIControl.Event.touchUpInside)

        view.addSubview(btnPdf)

        layout.sectionInset = UIEdgeInsets(top: 55, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: view.frame.width * 0.9, height: view.frame.width * 0.5)

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(FeedCells.self, forCellWithReuseIdentifier: "FeedCell")
        collectionView.backgroundColor = UIColor(white: 0.95, alpha: 1)

        view.addSubview(collectionView)
        view.sendSubviewToBack(collectionView)

        addData()
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
    }

    @objc func navigateBack() {
        dismiss(animated: false, completion: nil)
    }

    // Close PDF View Function
    @objc func closePdfView() {
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
        pdfViewController.view.addSubview(pdfView)
        pdfViewController.modalPresentationStyle = .fullScreen

        // Create Share Button
        let shareButton = UIButton(frame: CGRect(x: 0, y: 50, width: view.frame.width / 2, height: 20))
        shareButton.backgroundColor = UIColor.black
        shareButton.showsTouchWhenHighlighted = true
        shareButton.setTitle("Share", for: UIControl.State.normal)
        shareButton.addTarget(self, action: #selector(sharePdf), for: .touchUpInside)
        pdfViewController.view.addSubview(shareButton)

        // Create Close Button
        let closeButton = UIButton(frame: CGRect(x: view.frame.width / 2, y: 50, width: view.frame.width / 2, height: 20))
        closeButton.backgroundColor = UIColor.black
        closeButton.showsTouchWhenHighlighted = true
        closeButton.setTitle("Close", for: UIControl.State.normal)
        closeButton.addTarget(self, action: #selector(closePdfView), for: .touchUpInside)
        pdfViewController.view.addSubview(closeButton)

        present(pdfViewController, animated: true, completion: nil)
    }

    @objc func sharePdf() {
        do {
            let docURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let contents = try FileManager.default.contentsOfDirectory(at: docURL, includingPropertiesForKeys: [.fileResourceTypeKey], options: .skipsHiddenFiles)
            for url in contents {
                if url.description.contains(pdfNameFromUrl!) {
                    let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

                    DispatchQueue.main.async {
                        if let topVC = UIApplication.shared.connectedScenes
                            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                            .first
                        {
                            // ✅ Find the topmost view controller
                            if let topVC = self.topMostViewController() {
                                topVC.present(activityViewController, animated: true, completion: nil)
                            } else {
                                print("❌ Unable to find top view controller")
                            }
                        }
                    }
                }
            }
        } catch {
            print("could not locate pdf file !!!!!!!")
        }
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

        // ✅ Save in Documents Directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("\(filename).pdf")

        let resourceDocPath = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last! as URL
        pdfNameFromUrl = "YourTickets-\(filename).pdf"
        let actualPath = resourceDocPath.appendingPathComponent(pdfNameFromUrl!)
        do {
            try pdfData.write(to: actualPath, options: .atomic)
            print("pdf successfully saved!")
            return fileURL
        } catch {
            print("Pdf could not be saved")
            return nil
        }
    }

    func addData() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let data = try await self.appServices.loginGateway.getManagePurchases(purchaseId: self.purchaseId)
                let json = try JSON(data: data)
                if let list = json["tickets"].object as? NSArray {
                    for i in 0 ..< list.count {
                        if let dataBlock = list[i] as? NSDictionary {
                            self.CollectionData.append(AllTicketsData(add: dataBlock))
                            self.CollectionData.sort { ($0.seats_seatNumber ?? "") < ($1.seats_seatNumber ?? "") }
                        }
                    }
                }
                self.collectionView?.reloadData()
            } catch {
                NSLog("TicketsVC addData: %@", error.localizedDescription)
            }
        }
    }

    /*
     Method to delete tickets one by one
     */
    @objc func cancelTicket(button: UIButton, event _: UIEvent) {
        let ticketId = CollectionData[button.tag].ticketId
        var ticketIds = [Int]()
        ticketIds.append(ticketId!)
        let data: NSDictionary = ["ticketIds": ticketIds]
        let jsonData: Data = try! JSONSerialization.data(withJSONObject: data, options: [])
        let prepareDataToPost = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String

        let post: NSString = "purchaseId=\(purchaseId!)&ticketsToBeCancelled=\(prepareDataToPost)" as NSString
        let postData: Data = post.data(using: String.Encoding.ascii.rawValue)!

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let data = try await self.appServices.loginGateway.postManagePurchases(body: postData)
                let json = try JSON(data: data)
                if json["Success"].string == "true" {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newDataNotif"), object: nil)
                }
            } catch {
                NSLog("cancelTicket: %@", error.localizedDescription)
            }
        }

        CollectionData.remove(at: button.tag)
        collectionView.reloadData()
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        1
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        if CollectionData.count > 0 {
            return CollectionData.count
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

        cell.textLabel?.text = CollectionData[indexPath.row].movie_name
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.translatesAutoresizingMaskIntoConstraints = false

        let paragrapStyle = NSMutableParagraphStyle()
        paragrapStyle.lineSpacing = 4

        let title = NSMutableAttributedString(string: (cell.textLabel?.text!)!, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 14.0)!]))

        title.append(NSAttributedString(string: "\n\(CollectionData[indexPath.row].movie_name!)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 12.0)!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor(red: 155 / 255, green: 161 / 255, blue: 171 / 255, alpha: 1)])))

        title.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragrapStyle, range: NSMakeRange(0, title.string.count))
        cell.textLabel?.attributedText = title

        let urlMovie = URLManager.image(CollectionData[indexPath.row].movie_picture)

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

        let text = NSMutableAttributedString(string: "Ticket details: \n Seat Row: \(CollectionData[indexPath.row].seats_seatRow!), \n Seat Nr: \(CollectionData[indexPath.row].seats_seatNumber!), \nDate of Screening: \n\(CollectionData[indexPath.row].screening_date!), \n Venue: \(CollectionData[indexPath.row].venue_name!)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 14.0)!]))

        cell.statusText?.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .gray : .white
        }
        cell.statusText?.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .black
        }
        cell.statusText?.attributedText = text

        let btn = UIButton(type: UIButton.ButtonType.custom) as UIButton
        btn.frame = cell.CancelImage!.frame
        btn.addTarget(self, action: #selector(TicketsVC.cancelTicket), for: .touchUpInside)
        btn.tag = indexPath.section
        btn.setImage(UIImage(named: "trash"), for: .normal)
        cell.contentView.addSubview(btn)

        guard let filter,
              let data = CollectionData[indexPath.row].seats_seatNumber!.data(using: .isoLatin1, allowLossyConversion: false)
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Helper function to get the topmost view controller
    func topMostViewController() -> UIViewController? {
        guard let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }).first
        else {
            return nil
        }

        var topVC = keyWindow.rootViewController
        while let presentedVC = topVC?.presentedViewController {
            topVC = presentedVC
        }
        return topVC
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
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
