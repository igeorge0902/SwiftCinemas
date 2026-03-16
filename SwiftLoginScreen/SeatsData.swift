//
//  SeatsData.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 20/07/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import Foundation
import SwiftyJSON

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

        var errorOnLogin: GeneralRequestManager?

        errorOnLogin = GeneralRequestManager(url: serverURL + "/mbooks-1/rest/book/seats/" + myString, errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: nil, contentType: "", bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

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
        }
    }
}
