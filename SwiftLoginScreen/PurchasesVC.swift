//
//  PurchasesVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2017. 09. 15..
//  Copyright © 2017. George Gaspar. All rights reserved.
//

import Foundation
import SwiftyJSON
import UIKit

var TableData: [PurchaseData] = .init()
@available(iOS 15.0, *)
class PurchasesVC: UIViewController, UITableViewDataSource, UITableViewDelegate, HasAppServices {
    var appServices: AppServices!
    deinit {
        TableData.removeAll()
        print(#function, "\(self)")
    }

    lazy var label = UILabel()
    var sortBy = "purchase"
    var refreshControl: UIRefreshControl!
    var tableView: UITableView?

    var ResponseText: String?
    var ResponseCode: String?
    var AuthCode: String?
    var Status: String?
    var Amount: String?
    var TaxAmount: String?
    var movieName: String?
    var purchaseId: String?

    lazy var layout = UICollectionViewFlowLayout()

    override func viewWillAppear(_: Bool) {
        super.viewWillAppear(true)

        let frame = CGRect(x: 0, y: 100, width: view.frame.width, height: view.frame.height - 100)
        tableView = UITableView(frame: frame)
        tableView?.dataSource = self
        tableView?.delegate = self

        view.addSubview(tableView!)

        addPurchasesData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        injectAppServicesIfNeeded()

        tableView?.delegate = self
        tableView?.dataSource = self
        refreshControl = UIRefreshControl()
        tableView?.addSubview(refreshControl)

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.showsTouchWhenHighlighted = true
        btnNav.setTitle("Back", for: UIControl.State.normal)
        btnNav.addTarget(self, action: #selector(PurchasesVC.navigateBack), for: UIControl.Event.touchUpInside)

        let btnSortPurchase = UIButton(frame: CGRect(x: view.frame.width / 2, y: 50, width: view.frame.width / 2, height: 20))
        btnSortPurchase.backgroundColor = UIColor.black
        btnSortPurchase.showsTouchWhenHighlighted = true
        btnSortPurchase.setTitle("By Purchase", for: UIControl.State.normal)
        btnSortPurchase.addTarget(self, action: #selector(PurchasesVC.sortByPurchaseDate), for: UIControl.Event.touchUpInside)

        let btnSortScreening = UIButton(frame: CGRect(x: 0, y: 50, width: view.frame.width / 2, height: 20))
        btnSortScreening.backgroundColor = UIColor.black
        btnSortScreening.showsTouchWhenHighlighted = true
        btnSortScreening.setTitle("By Screening", for: UIControl.State.normal)
        btnSortScreening.addTarget(self, action: #selector(PurchasesVC.sortByScreeningDate), for: UIControl.Event.touchUpInside)
        /*
         let btnData = UIButton(frame: CGRect(x: view.frame.width / 2, y: 25, width: view.frame.width / 2, height: 20))
         btnData.backgroundColor = UIColor.black
         btnData.setTitle("CheckOut", for: UIControl.State())
         btnData.showsTouchWhenHighlighted = true
         btnData.addTarget(self, action: #selector(BasketVC.book), for: UIControl.Event.touchUpInside)
         view.addSubview(btnData)
         */
        view.addSubview(btnNav)
        view.addSubview(btnSortPurchase)
        view.addSubview(btnSortScreening)

        let frame2 = CGRect(x: view.frame.width * 0.10, y: 75, width: view.frame.width, height: 20)

        label = UILabel(frame: frame2)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left

        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailText = NSMutableAttributedString(string: sortBy, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

        label.attributedText = detailText

        view.addSubview(label)

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSNotification.Name(rawValue: "newDataNotif"), object: nil)
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
    }

    @objc func sortByPurchaseDate() {
        TableData.sort { ($0.purchaseDate ?? "") > ($1.purchaseDate ?? "") }
        sortBy = "purchase"
        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailText = NSMutableAttributedString(string: sortBy, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

        label.attributedText = detailText

        tableView?.reloadData()
    }

    @objc func sortByScreeningDate() {
        TableData.sort { ($0.screeningDate ?? "") > ($1.screeningDate ?? "") }
        sortBy = "screening"
        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailText = NSMutableAttributedString(string: sortBy, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

        label.attributedText = detailText

        tableView?.reloadData()
    }

    @objc func refresh() {
        TableData.removeAll()
        addPurchasesData()
    }

    @objc func navigateBack() {
        dismiss(animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_tickets" {
            let nextSegue = segue.destination as? TicketsVC
            nextSegue?.purchaseId = purchaseId
        }
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        if sortBy == "purchase" {
            TableData[section].purchaseDate
        } else {
            TableData[section].screeningDate
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "CELL") as UITableViewCell?

        if cell == nil {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "CELL")
        }

        if sortBy == "purchase" {
            TableData.sort { ($0.purchaseDate ?? "") > ($1.purchaseDate ?? "") }
        }
        if sortBy == "screening" {
            TableData.sort { ($0.screeningDate ?? "") > ($1.screeningDate ?? "") }
        }

        let data = TableData[indexPath.section]

        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailText = NSMutableAttributedString(string: data.movie_name, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

        detailText.append(NSAttributedString(string: "\n\(TableData[indexPath.section].screeningDate!)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 12.0)!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor(red: 155 / 255, green: 161 / 255, blue: 171 / 255, alpha: 1)])))

        cell!.textLabel?.numberOfLines = 5
        // cell!.textLabel?.translatesAutoresizingMaskIntoConstraints = false

        cell!.textLabel?.attributedText = detailText

        let urlMovie = URLManager.image(TableData[indexPath.section].movie_picture)

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let imgData = try await self.appServices.images.getData(urlString: urlMovie, realmCache: true)
                let image = UIImage(data: imgData)
                cell!.imageView?.image = image
                if let updatedCell = tableView.cellForRow(at: indexPath) {
                    updatedCell.imageView?.image = image
                    updatedCell.setNeedsLayout()
                }
            } catch {
                NSLog("PurchasesVC image: %@", error.localizedDescription)
            }
        }

        return cell!
    }

    func numberOfSections(in _: UITableView) -> Int {
        TableData.count
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        75
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        purchaseId = TableData[indexPath.section].purchaseId
        performSegue(withIdentifier: "goto_tickets", sender: self)
    }

    func tableView(_: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        // Write action code for the trash
        let TrashAction = UIContextualAction(style: .normal, title: "Trash", handler: { (_: UIContextualAction, _: UIView, success: (Bool) -> Void) in
            self.purchaseId = TableData[indexPath.section].purchaseId
            let post: NSString = "purchaseId=\(self.purchaseId!)" as NSString
            let postData: Data = post.data(using: String.Encoding.ascii.rawValue)!

            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let data = try await self.appServices.loginGateway.postManagePurchases(body: postData)
                    let json = try JSON(data: data)
                    if json["Success"].string == "true" {
                        TableData.remove(at: indexPath.section)
                        self.presentAlert(withTitle: "Info", message: "Purchase was refunded")
                    }
                    self.tableView?.reloadData()
                } catch {
                    NSLog("delete purchase: %@", error.localizedDescription)
                }
            }

            print("Update action ...")
            success(true)
        })
        TrashAction.backgroundColor = .red

        // Write action code for the More
        let MoreAction = UIContextualAction(style: .normal, title: "More", handler: { (_: UIContextualAction, _: UIView, success: (Bool) -> Void) in
            print("Update action ...")
            success(true)
        })
        MoreAction.backgroundColor = .gray

        return UISwipeActionsConfiguration(actions: [TrashAction, MoreAction])
    }

    func addPurchasesData() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let data = try await self.appServices.loginGateway.getAllPurchases()
                let json = try JSON(data: data)
                if let list = json["purchases"].object as? NSArray {
                    TableData.removeAll()

                    for i in 0 ..< list.count {
                        if let dataBlock = list[i] as? NSDictionary {
                            TableData.append(PurchaseData(add: dataBlock))
                        }
                    }
                    self.tableView?.reloadData()
                }
            } catch {
                NSLog("addPurchasesData: %@", error.localizedDescription)
                self.presentAlert(withTitle: "Error", message: error.localizedDescription)
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
