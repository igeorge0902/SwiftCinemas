//
//  AllTicketsData.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2017. 04. 13..
//  Copyright © 2017. George Gaspar. All rights reserved.
//

import Foundation
import SwiftyJSON

class AllTicketsData: NSObject {
    var movie_name: String!
    var movie_picture: String!
    var venue_name: String!
    var seats_seatRow: String!
    var seats_seatNumber: String!
    var price: Int!
    var tax: Double!
    var screen_screenId: String!
    var screening_date: String!
    var ticketId: Int!

    // TODO: add venue details, pictures
    init(add: NSDictionary) {
        movie_name = (add["movie_name"] as! String)
        movie_picture = (add["movie_picture"] as! String)
        venue_name = (add["venue_name"] as! String)
        seats_seatRow = (add["seats_seatRow"] as! String)
        seats_seatNumber = (add["seats_seatNumber"] as! String)
        price = (add["price"] as! Int)
        tax = (add["tax"] as! Double)
        screening_date = (add["screening_date"] as! String)
        screen_screenId = (add["screen_screenId"] as! String)
        ticketId = (add["ticketId"] as! Int)
    }
}
