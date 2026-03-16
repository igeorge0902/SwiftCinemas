//
//  ScreenData.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2020. 10. 01..
//  Copyright © 2020. George Gaspar. All rights reserved.
//

import Foundation
import SwiftyJSON

class ScreenData: NSObject {
    var movie: String!
    var date: String!
    var venue: String!
    var ScreeningId: String!

    var category: String?
    var screeningDatesId: String?

    // TODO: add venue details, pictures
    init(add: NSDictionary) {
        movie = (add["movie"] as! String)
        date = (add["date"] as! String)
        venue = (add["venue"] as! String)
        ScreeningId = (add["ScreeningId"] as! String)

        //  category = (add["category"] as! String)
        //  screeningDatesId = (add["screeningDatesId"] as! String)
    }
}
