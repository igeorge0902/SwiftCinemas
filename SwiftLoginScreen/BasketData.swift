//
//  BasketData.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2017. 04. 26..
//  Copyright © 2017. George Gaspar. All rights reserved.
//

import Foundation
import SwiftyJSON

class BasketData: NSObject {
    var movie_name: String!
    var seatId: Int!
    var seats_seatRow: String!
    var seats_seatNumber: String!
    var price: Int!
    var tax: Double!
    var screeningDateId: String!
    var movie_picture: String!
    var venue_picture: String!
    var venue_name: String!
    var screening_date: String!

    init(add: NSDictionary) {
        movie_name = (add["movie_name"] as! String)
        seatId = (add["seatId"] as! Int)
        seats_seatRow = (add["seats_seatRow"] as! String)
        seats_seatNumber = (add["seats_seatNumber"] as! String)
        price = (add["price"] as! Int)
        tax = (add["tax"] as! Double)
        screeningDateId = (add["screeningDateId"] as! String)
        movie_picture = (add["movie_picture"] as! String)
        venue_picture = (add["venue_picture"] as! String)
        venue_name = (add["venue_name"] as! String)
        screening_date = (add["screening_date"] as! String)
    }
}
