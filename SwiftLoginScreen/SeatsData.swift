//
//  SeatsData.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 20/07/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import Foundation
import SwiftyJSON
import UIKit

class SeatsData: NSObject {
    var seatId: Int!
    var seatNumber: String!
    var seatRow: String!
    var isReserved: String!
    var price: Int!
    var tax: Double!
    var image: UIImageView!

    init(add: NSDictionary) {
        seatId = (add["seatId"] as! Int)
        seatNumber = (add["seatNumber"] as! String)
        seatRow = (add["seatRow"] as! String)
        isReserved = (add["isReserved"] as! String)
        price = (add["price"] as! Int)
        tax = (add["tax"] as! Double)
    }

    class func addData(_ screeningDateId: Int) {
        let myString = String(screeningDateId)

        SeatsData_.removeAll()

        Task { @MainActor in
            guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
            do {
                let data = try await app.services.mbooks.seats(screeningDateId: myString)
                let json = try JSON(data: data)
                if let list = json["seatsforscreen"].object as? NSArray {
                    for i in 0 ..< list.count {
                        if let dataBlock = list[i] as? NSDictionary {
                            SeatsData_.append(SeatsData(add: dataBlock))

                            for i in 0 ..< SeatsData_.count {
                                if !numberOfRows.contains(SeatsData_[i].seatRow) {
                                    numberOfRows.append(SeatsData_[i].seatRow)
                                }
                            }

                            tableView_?.reloadData()
                        }
                    }
                }
            } catch {
                NSLog("SeatsData.addData: %@", error.localizedDescription)
            }
        }
    }
}
