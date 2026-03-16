//
//  Admin_ScreenData.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2021. 05. 20..
//  Copyright © 2021. George Gaspar. All rights reserved.
//

import Foundation

class Admin_ScreenData: NSObject {
    var movie: String!
    var movieId: String!
    var date: String!
    var venue: String!
    var venueId: String!
    var ScreeningId: String!

    var category: String!
    var screeningDatesId: String!

    init(add: NSDictionary) {
        movie = (add["movie"] as! String)
        movieId = (add["movieId"] as! String)
        date = (add["date"] as! String)
        venue = (add["venue"] as! String)
        venueId = (add["venueId"] as! String)
        ScreeningId = (add["ScreeningId"] as! String)
        category = (add["category"] as! String)
        screeningDatesId = (add["screeningDatesId"] as! String)
    }
}
