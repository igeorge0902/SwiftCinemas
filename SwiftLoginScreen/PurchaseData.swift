//
//  PurchaseData.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2017. 09. 16..
//  Copyright © 2017. George Gaspar. All rights reserved.
//

import Foundation

class PurchaseData: NSObject {
    var orderId: String!
    var purchaseId: String!
    var movie_name: String!
    var venue_name: String!
    var movie_picture: String!
    var screeningDate: String!
    var purchaseDate: String!

    init(add: NSDictionary) {
        orderId = (add["orderId"] as! String)
        purchaseId = (add["purchaseId"] as! String)
        movie_name = (add["movie_name"] as! String)
        venue_name = (add["venue_name"] as! String)
        movie_picture = (add["movie_picture"] as! String)
        purchaseDate = (add["purchaseDate"] as! String)
        screeningDate = (add["screeningDate"] as! String)
    }
}
