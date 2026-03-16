//
//  MoviesData.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 18/06/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import Foundation
import SwiftyJSON

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
        var OnLogin: GeneralRequestManager?

        OnLogin = GeneralRequestManager(url: serverURL + "/mbooks-1/rest/book/movies/paging", errors: "", method: "GET", headers: nil, queryParameters: ["setFirstResult": String(0)], bodyParameters: nil, isCacheable: "1", contentType: "", bodyToPost: nil)

        OnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            if let list = json["movies"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        Data.imageFromUrl(urlString: serverURL + "/simple-service-webapp/webapi" + MoviesData(add: dataBlock).large_picture!)
                    }
                }
            }
        }
    }
}

extension Data {
    static func imageFromUrl(urlString: String) {
        if let url = URL(string: urlString) {
            // _ = try? Data(contentsOf: url)

            let request = URLRequest(url: url as URL)

            //   NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main) {
            //       (_: URLResponse?, _: Data?, _: Error?) -> Void in
            // }

            var loadPictures: GeneralRequestManager?
            loadPictures = GeneralRequestManager(url: urlString, errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: "1", contentType: "", bodyToPost: nil)

            loadPictures?.getData_ {
                (_: Data, _: NSError?) in
                // let image = UIImage(data: data)
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
