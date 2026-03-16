//
//  DatesData.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 08/09/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import Foundation
import SwiftyJSON

class DatesData: NSObject {
    var screeningDatesId: Int!
    var screeningDate: String!
    var movieId: Int!

    init(add: NSDictionary) {
        screeningDatesId = (add["screeningDatesId"] as! Int)
        screeningDate = (add["screeningDate"] as! String)
        movieId = (add["movieId"] as! Int)
    }

    class func addDatesData(_ screen_screenId: String) {
        ScreeningDates.removeAll()

        var errorOnLogin: GeneralRequestManager?

        errorOnLogin = GeneralRequestManager(url: serverURL + "/mbooks-1/rest/book/dates/" + screen_screenId, errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: nil, contentType: "", bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            if let list = json["dates"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        ScreeningDates.append(DatesData(add: dataBlock))
                    }
                }
            }
        }
    }
}
