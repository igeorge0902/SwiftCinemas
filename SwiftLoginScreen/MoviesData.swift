//
//  MoviesData.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 18/06/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import Foundation
import SwiftyJSON
import UIKit

class MoviesData: NSObject {
    var movieId: Int!
    var movieId_: String!
    var detail: String!
    var name: String!
    var large_picture: String!
    var image: UIImage!
    var imdb: String!

    init(add: NSDictionary) {
        movieId_ = (add["movieId"] as! String)
        movieId = Int(movieId_)
        name = (add["name"] as! String)
        large_picture = (add["large_picture"] as! String)
        detail = (add["detail"] as! String)
        imdb = (add["iMDB_url"] as! String)
    }

    class func addData() {
        Task { @MainActor in
            guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
            do {
                let data = try await app.services.mbooks.moviesPaging(query: ["setFirstResult": String(0)])
                let json = try JSON(data: data)
                if let list = json["movies"].object as? NSArray {
                    for i in 0 ..< list.count {
                        if let dataBlock = list[i] as? NSDictionary {
                            Data.imageFromUrl(urlString: URLManager.image(MoviesData(add: dataBlock).large_picture!))
                        }
                    }
                }
            } catch {
                NSLog("MoviesData.addData: %@", error.localizedDescription)
            }
        }
    }
}

extension Data {
    static func imageFromUrl(urlString: String) {
        Task { @MainActor in
            guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
            do {
                _ = try await app.services.images.getData(urlString: urlString, realmCache: true)
            } catch {
                NSLog("imageFromUrl: %@", error.localizedDescription)
            }
        }
    }
}

extension UIAlertController {
    static func popUp(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)

        alertController.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))

        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}

extension String {
    static func formatDate(date: Date) -> String {
        let dateFormatter_ = DateFormatter()
        dateFormatter_.dateStyle = DateFormatter.Style.medium
        dateFormatter_.timeStyle = DateFormatter.Style.short
        dateFormatter_.timeZone = TimeZone.autoupdatingCurrent

        // US English Locale (en_US)
        dateFormatter_.locale = Locale(identifier: "en_US_POSIX")

        return dateFormatter_.string(from: date)
    }
}

extension Date {
    static func formatDate(dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent

        return dateFormatter.date(from: dateString)!
    }
}
