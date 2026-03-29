//
//  DatesData.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 08/09/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import Foundation
import SwiftyJSON
import UIKit

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

        Task { @MainActor in
            guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
            do {
                let data = try await app.services.mbooks.dates(screenId: screen_screenId)
                let json = try JSON(data: data)
                if let list = json["dates"].object as? NSArray {
                    for i in 0 ..< list.count {
                        if let dataBlock = list[i] as? NSDictionary {
                            ScreeningDates.append(DatesData(add: dataBlock))
                        }
                    }
                }
            } catch {
                NSLog("DatesData.addDatesData: %@", error.localizedDescription)
            }
        }
    }
}
