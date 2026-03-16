//
//  PopOver.swift (Crown Jewel)
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 13/07/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import CoreData
import SwiftyJSON
import UIKit

// import FacebookCore
// import Braintree

/**
 Stores Seat objects in Array.
 */
var SeatsData_: [SeatsData] = .init()
/**
 Stores returned Ticket objects in Array.
 */
var TicketsData_: [TicketsData] = .init()
var tickets = [String: String]()
/**
 Map to be used to handle seats to be reserved per screening. seatNumbers will be added to Seats Array to CheckOut.

 @Int: seatId

 @String: seatNumber
 */
var seatsToBeReserved = [Int: String]()
/**
 Stores seatId and screeningDateId to finalize reservation during the CheckOut.
 */
var Seats = [String: NSDictionary]()
var tableView_: UITableView?
class PopOver: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate {
    lazy var storedOffsets = [Int: CGFloat]()
    lazy var label = UILabel()

    // lazy var braintreeClient = BTAPIClient(authorization: "sandbox_dpdzm97y_j3ndqpzrhy4gp2p7")!

    deinit {
        seatsToBeReserved.removeAll()
        print(#function, "\(self)")
    }

    var refreshControl: UIRefreshControl!

    var ResponseText: String?
    var ResponseCode: String?
    var AuthCode: String?
    var Status: String?
    var movieName: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
    }

    override func viewWillAppear(_: Bool) {
        let frame2 = CGRect(x: view.frame.width * 0.10, y: 55, width: view.frame.width, height: 20)

        label = UILabel(frame: frame2)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left

        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailText = NSMutableAttributedString(string: String.formatDate(date: Date.formatDate(dateString: String(myDateString!.first!))), attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

        label.attributedText = detailText

        view.addSubview(label)
        // FIX: size
        let frame = CGRect(x: 0, y: 90, width: view.frame.width, height: view.frame.height - 120)
        tableView_ = UITableView(frame: frame)
        tableView_?.delegate = self
        tableView_?.dataSource = self
        tableView_?.rowHeight = 75
        // tableView_?.allowsSelection = false

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.setTitle("Clear", for: UIControl.State())
        btnNav.showsTouchWhenHighlighted = true
        btnNav.addTarget(self, action: #selector(PopOver.clearSeatsToBeReserved), for: UIControl.Event.touchUpInside)

        let btnData = UIButton(frame: CGRect(x: view.frame.width / 2, y: 25, width: view.frame.width / 2, height: 20))
        btnData.backgroundColor = UIColor.black
        btnData.setTitle("Basket", for: UIControl.State())
        btnData.showsTouchWhenHighlighted = true
        btnData.addTarget(self, action: #selector(PopOver.openBasket), for: UIControl.Event.touchUpInside)

        view.addSubview(btnNav)
        view.addSubview(btnData)

        tableView_!.register(TableViewCell.self, forCellReuseIdentifier: "TableViewCell")
        // tableView_!.register(UITableViewCell.self, forCellReuseIdentifier: "NormalCell")

        view.addSubview(tableView_!)
    }

    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        numberOfRows.count
    }

    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? TableViewCell else { return }

        tableViewCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
        tableViewCell.collectionViewOffset = storedOffsets[indexPath.row] ?? 0
    }

    func tableView(_: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? TableViewCell else { return }

        storedOffsets[indexPath.row] = tableViewCell.collectionViewOffset
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell

        cell.backgroundColor = UIColor.groupTableViewBackground
        //  self.cellDelegate = self
        return cell
    }

    @objc func clearSeatsToBeReserved() {
        Seats.removeValue(forKey: screeningDateId!)

        for seats in SeatsData_ {
            BasketData_.removeValue(forKey: seats.seatId)
            seatsToBeReserved.removeValue(forKey: seats.seatId)
        }

        tableView_?.reloadData()
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
    }

    @objc func openBasket() {
        if BasketData_.count < 1 {
            presentAlert(withTitle: "Warning!", message: "No free seat(s) to be reserved!")

        } else {
            let storyboard = UIStoryboard(name: "Storyboard", bundle: nil)
            let pvc = storyboard.instantiateViewController(withIdentifier: "Basket")

            pvc.modalPresentationStyle = UIModalPresentationStyle.custom
            pvc.transitioningDelegate = self
            // pvc.view.backgroundColor = UIColor.groupTableViewBackgroundColor()

            present(pvc, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension PopOver: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        for j in 0 ..< numberOfRows.count {
            if collectionView.tag == j {
                return SeatsData_.filter {
                    $0.seatRow == String(j + 1)
                }.count
            }
        }
        return 6
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SeatCells = collectionView.dequeueReusableCell(withReuseIdentifier: "SeatCells", for: indexPath) as! SeatCells
        // cell.cellDelegate = self

        for j in 0 ..< numberOfRows.count {
            if collectionView.tag == j {
                let filteredAttendees = SeatsData_.filter {
                    $0.seatRow == String(j + 1)
                }

                for i in 0 ..< filteredAttendees.count {
                    // cell.backgroundColor = self.model[collectionView.tag][indexPath.item]
                    if indexPath.item == i {
                        let total = Double(filteredAttendees[i].price) * filteredAttendees[i].tax
                        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
                        let detailText = NSMutableAttributedString(string: filteredAttendees[i].seatNumber, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

                        let myTextAttribute_ = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "CourierNewPS-BoldMT", size: 11.0)!]
                        let priceTag = NSMutableAttributedString(string: String(total).appending(" Ft"), attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute_))

                        cell.textLabel.attributedText = detailText
                        cell.priceLabel.attributedText = priceTag

                        cell.layer.borderColor = UIColor.gray.cgColor
                        cell.layer.borderWidth = 1
                        cell.layer.cornerRadius = 5

                        if filteredAttendees[i].isReserved == "1" {
                            cell.backgroundColor = UIColor.darkGray

                        } else {
                            cell.backgroundColor = UIColor.lightGray
                        }
                    }
                }
            }
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)

        return true
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let filteredAttendees = SeatsData_.filter {
            $0.seatRow == String(collectionView.tag + 1)
        }

        let seatId = filteredAttendees[indexPath.row].seatId
        // let seatNumber = filteredAttendees[indexPath.row].seatNumber

        let seatIds = [Int](seatsToBeReserved.keys.sorted(by: { $0 < $1 }))
        if seatIds.contains(seatId!) {
            cell.layer.borderWidth = 4
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? SeatCells

        cell?.layer.borderWidth = 4
        // cell?.layer.borderColor = UIColor.black.cgColor

        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)

        let filteredAttendees = SeatsData_.filter {
            $0.seatRow == String(collectionView.tag + 1)
        }

        let seatId = filteredAttendees[indexPath.row].seatId
        let seatNumber = filteredAttendees[indexPath.row].seatNumber

        let seatIds = [Int](seatsToBeReserved.keys.sorted(by: { $0 < $1 }))
        if !seatIds.contains(seatId!), filteredAttendees[indexPath.row].isReserved == "0" {
            seatsToBeReserved.updateValue(seatNumber!, forKey: seatId!)

            let date_ = Date.formatDate(dateString: String(myDateString!.first!))

            let basketItem: NSDictionary = ["movie_name": SelectMovieName!, "seatId": seatId!, "seats_seatRow": filteredAttendees[indexPath.row].seatRow!, "seats_seatNumber": seatNumber as Any, "price": filteredAttendees[indexPath.row].price!, "tax": filteredAttendees[indexPath.row].tax!, "screeningDateId": screeningDateId!, "movie_picture": SelectMoviePicture!, "venue_picture": "", "venue_name": SelectVenueName!, "screening_date": String.formatDate(date: date_)]

            BasketData_.updateValue(BasketData(add: basketItem), forKey: seatId!)

            var string = ""
            for seats in seatsToBeReserved.values {
                string += seats + "-"
            }

            let seat = ["screeningDateId": screeningDateId!, "seat": string]

            Seats.updateValue(seat as NSDictionary, forKey: screeningDateId!)

            NSLog("SeatId is: \(seatNumber!)")

        } else {
            cell?.layer.borderWidth = 1

            seatsToBeReserved.removeValue(forKey: seatId!)

            var string = ""
            for seats in seatsToBeReserved.values {
                string += seats + "-"
            }

            let seat = ["screeningDateId": screeningDateId!, "seat": string]

            Seats.updateValue(seat as NSDictionary, forKey: screeningDateId!)

            BasketData_.removeValue(forKey: seatId!)

            NSLog("SeatId is: \(seatNumber!) is already added!")
        }

        print("Collection view at row \(collectionView.tag) selected index path \(indexPath), section is \(indexPath.section), \(indexPath.row)")
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        let filteredAttendees = SeatsData_.filter {
            $0.seatRow == String(collectionView.tag + 1)
        }

        let seatId = filteredAttendees[indexPath.row].seatId

        seatsToBeReserved.removeValue(forKey: seatId!)

        var string = ""
        for seats in seatsToBeReserved.values {
            string += seats + "-"
        }

        let seat = ["screeningDateId": screeningDateId!, "seat": string]

        Seats.updateValue(seat as NSDictionary, forKey: screeningDateId!)

        BasketData_.removeValue(forKey: seatId!)

        return true
    }

    // do something when user touches cell
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)

        // cell?.layer.borderColor = UIColor.black.cgColor
        cell?.layer.borderWidth = 4
    }

    // do something when user releases touch
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)

        cell?.layer.borderWidth = 1
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
