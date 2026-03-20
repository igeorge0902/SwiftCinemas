//
//  GeneralRequestManager.swift
//  MyFirstSwiftApp
//
//  Created by Gaspar Gyorgy on 18/07/15.
//  Copyright (c) 2015 Gaspar Gyorgy. All rights reserved.
//

import Foundation
import Realm
import SwiftyJSON

// import Kanna

enum contentType_: String {
    case json = "application/json"
    case urlEncoded = "application/x-www-form-urlencoded"
    case image = "image/jpeg"
}

protocol AlertProtocol {
    var alertPresentingVC: UIViewController? { get set }
}

protocol AlertViewProtocol {
    var alertViewPresentingVC: UIViewController? { get set }
}

class GeneralRequestManager: NSObject, AlertProtocol, AlertViewProtocol {
    var alertPresentingVC: UIViewController?
    var alertViewPresentingVC: UIViewController?

    fileprivate var urlResponse: URLResponse?

    var url: URL!
    var errors: String!
    var method: String!
    var queryParameters: [String: String]?
    var headers: [String: String]?
    var bodyParameters: [String: String]?
    var isCacheable: String?
    var contentType: String!
    var bodyToPost: Data?

    var prefs: UserDefaults = .standard

    init?(url: String, errors: String, method: String, headers: [String: String]?, queryParameters: [String: String]?, bodyParameters: [String: String]?, isCacheable: String?, contentType: String, bodyToPost: Data?) {
        super.init()
        self.url = URL(string: url)!
        self.errors = errors
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.bodyParameters = bodyParameters
        self.isCacheable = isCacheable
        self.contentType = contentType
        self.bodyToPost = bodyToPost
        if url.isEmpty {}
        if errors.isEmpty {}
    }

    deinit {
        NSLog("\(url!) is being deinitialized")
        NSLog("\(errors!) is being deinitialized")
        NSLog(#function, "\(self)")
    }

    lazy var session: URLSession = .sharedCustomSession

    func getData_(_ onCompletion: @escaping (Data, NSError?) -> Void) {
        if isCacheable == "1" {
            if let localResponse = cachedResponseForCurrentRequest(), let data = localResponse.data {
                if localResponse.timestamp.addingTimeInterval(3600) > Date() {
                    var headerFields: [String: String] = [:]

                    headerFields["Content-Length"] = String(format: "%d", data.count)

                    if let mimeType = localResponse.mimeType {
                        headerFields["Content-Type"] = mimeType as String
                    }

                    headerFields["Content-Encoding"] = localResponse.encoding!
                    let err = NSError()

                    // let json: JSON = try! JSON(data: data)
                    DispatchQueue.main.async {
                        onCompletion(data as Data, err)
                    }
                } else {
                    dataTask_ { data, err in
                        DispatchQueue.main.async {
                            onCompletion(data as Data, err)
                        }
                    }
                    saveCachedResponse(data)
                }

            } else {
                dataTask_ { data, err in

                    self.saveCachedResponse(data)
                    DispatchQueue.main.async {
                        onCompletion(data as Data, err)
                    }
                }
            }

        } else {
            dataTask_ { data, err in
                DispatchQueue.main.async {
                    onCompletion(data as Data, err)
                }
            }
        }
        /*
         dataTask_ { data, err in

             onCompletion(data as Data, err)
         }
         */
    }

    func getData(_ onCompletion: @escaping (JSON, NSError?) -> Void) {
        if isCacheable == "1" {
            if let localResponse = cachedResponseForCurrentRequest(), let data = localResponse.data {
                if localResponse.timestamp.addingTimeInterval(3600) > Date() {
                    var headerFields: [String: String] = [:]

                    headerFields["Content-Length"] = String(format: "%d", data.count)

                    if let mimeType = localResponse.mimeType {
                        headerFields["Content-Type"] = mimeType as String
                    }

                    headerFields["Content-Encoding"] = localResponse.encoding!
                    let err = NSError()

                    let json: JSON = try! JSON(data: data)
                    DispatchQueue.main.async {
                        onCompletion(json as JSON, err)
                    }

                } else {
                    dataTask { json, err in
                        DispatchQueue.main.async {
                            onCompletion(json as JSON, err)
                        }
                    }

                    let realm = RLMRealm.default()
                    realm.beginWriteTransaction()
                    realm.delete(localResponse)

                    do {
                        try realm.commitWriteTransaction()
                    } catch {
                        print("Something went wrong!")
                    }
                }

            } else {
                dataTask { json, err in
                    DispatchQueue.main.async {
                        onCompletion(json as JSON, err)
                    }
                }
            }

        } else {
            dataTask { json, err in
                DispatchQueue.main.async {
                    onCompletion(json as JSON, err)
                }
            }
        }
    }

    func getResponse(_ onCompletion: @escaping (JSON, NSError?) -> Void) {
        if isCacheable == "1" {
            if let localResponse = cachedResponseForCurrentRequest(), let data = localResponse.data {
                if localResponse.timestamp.addingTimeInterval(3600) > Date() {
                    var headerFields: [String: String] = [:]

                    headerFields["Content-Length"] = String(format: "%d", data.count)

                    if let mimeType = localResponse.mimeType {
                        headerFields["Content-Type"] = mimeType as String
                    }

                    headerFields["Content-Encoding"] = localResponse.encoding!
                    let err = NSError()

                    let json: JSON = try! JSON(data: data)

                    DispatchQueue.main.async {
                        onCompletion(json as JSON, err)
                    }

                } else {
                    dataTask { json, err in

                        DispatchQueue.main.async {
                            onCompletion(json as JSON, err)
                        }
                    }

                    let realm = RLMRealm.default()
                    realm.beginWriteTransaction()
                    realm.delete(localResponse)

                    do {
                        try realm.commitWriteTransaction()
                    } catch {
                        print("Something went wrong!")
                    }
                }

            } else {
                dataTask { json, err in
                    DispatchQueue.main.async {
                        onCompletion(json as JSON, err)
                    }
                }
            }

        } else {
            dataTask { json, err in
                DispatchQueue.main.async {
                    onCompletion(json as JSON, err)
                }
            }
        }
    }

    // for testing
    func dataTask_(_ onCompletion: @escaping (Data, NSError?) -> Void) {
        let request = URLRequest.requestWithURL(url, method: method, queryParameters: queryParameters, bodyParameters: bodyParameters as NSDictionary?, headers: headers, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30, isCacheable: isCacheable, contentType: contentType, bodyToPost: bodyToPost)

        let task = session.dataTask(with: request, completionHandler: { data, _, sessionError in

            // let json: JSON = try! JSON(data: data!)
            DispatchQueue.main.async {
                onCompletion(data!, sessionError as NSError?)
            }
        })
        task.resume()
    }

    // INFO: use this class for every dataTask operation
    func dataTask(_ onCompletion: @escaping ServiceResponses) {
        // TODO: temp solution; refactor webservice header auth to block unauth access
        var xtoken = prefs.value(forKey: "X-Token")
        if xtoken == nil {
            xtoken = ""
        }
        if url.absoluteString.contains(URLManager.baseURL) {
            headers = ["Ciphertext": xtoken as! String, "X-Token": "client-secret", "X-Device": deviceId as String]
        }

        let request = URLRequest.requestWithURL(url, method: method, queryParameters: queryParameters, bodyParameters: bodyParameters as NSDictionary?, headers: headers, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30, isCacheable: "", contentType: contentType, bodyToPost: bodyToPost)

        let task = session.dataTask(with: request, completionHandler: { data, response, sessionError in
            var error = sessionError

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                    let description = "HTTP response was \(httpResponse.statusCode)"

                    error = NSError(domain: "Custom", code: 0, userInfo: [NSLocalizedDescriptionKey: description])

                    //  self.alertViewPresentingVC = UIViewController()
                    //  self.alertViewPresentingVC!.presenAlertView(withTitle: "Error:", message: error!.localizedDescription)

                    self.alertPresentingVC = UIViewController()
                    self.alertPresentingVC!.presentAlert(withTitle: "Error:", message: error!.localizedDescription)
                    NSLog(error!.localizedDescription)
                }
            }

            if error != nil {
                if data == nil {
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 300 {
                            let jsonData: NSDictionary = try! JSONSerialization.jsonObject(with: data!, options:

                                JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary

                            guard let message_ = jsonData.value(forKey: "Error Details"),
                                  let message = (message_ as AnyObject).value(forKey: "Activation") else { return }

                            let alertView = UIAlertView()
                            alertView.title = "Activation is required! To send the activation email tap on the Okay button!"
                            alertView.message = "Voucher is active: \(message)"
                            alertView.delegate = self
                            alertView.addButton(withTitle: "Okay")
                            alertView.addButton(withTitle: "Cancel")
                            alertView.cancelButtonIndex = 1
                            alertView.show()

                            let json: JSON = try! JSON(data: data!)
                            DispatchQueue.main.async {
                                onCompletion(json, error as NSError?)
                            }
                        } else {
                            self.alertViewPresentingVC = UIViewController()
                            self.alertViewPresentingVC!.presentAlert(withTitle: "Error:", message: error!.localizedDescription)
                        }
                    } else {
                        UIAlertController.popUp(title: "Error:", message: error!.localizedDescription)
                    }

                } else {
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 503 {
                            if let result = NSString(data: data!, encoding: String.Encoding.ascii.rawValue) as String? {
                                self.alertViewPresentingVC = UIViewController()
                                self.alertViewPresentingVC!.presentAlert(withTitle: "Error:", message: result)
                                // if let doc = Kanna.HTML(html: result, encoding: String.Encoding.ascii) {
                                //        UIAlertController.popUp(title: "Error:", message: doc.title!)
                                //     }
                            }
                        }

                        if httpResponse.statusCode == 404 {
                            if let result = NSString(data: data!, encoding: String.Encoding.ascii.rawValue) as String? {
                                self.alertViewPresentingVC = UIViewController()
                                self.alertViewPresentingVC!.presentAlert(withTitle: "Error:", message: "The endpoint is not reachable")
                            }
                        }

                    } else {
                        self.alertViewPresentingVC = UIViewController()
                        self.alertViewPresentingVC!.presentAlert(withTitle: "Error:", message: error!.localizedDescription)
                    }
                }

            } else {
                // let json: AnyObject! = try?NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
                if let httpResponse = response as? HTTPURLResponse {
                    NSLog("got a " + String(httpResponse.statusCode) + " response code")
                    if let json: JSON = try? JSON(data: data!) {
                        if self.isCacheable == "1" {
                            self.saveCachedResponse(data!)
                        }

                        if json["Email was sent to:"].string != nil {
                            UIAlertController.popUp(title: "Hello!", message: json.rawString()!)

                        } else {
                            NSLog("Hey, You, what's that sound?")
                        }
                        DispatchQueue.main.async {
                            onCompletion(json, error as NSError?)
                        }
                    }
                }
            }
        })

        task.resume()
    }

    func alertView(_: UIAlertView, clickedButtonAt buttonIndex: Int) {
        switch buttonIndex {
        case 0:

            let prefs = UserDefaults.standard
            let user = prefs.value(forKey: "USERNAME")

            var errorOnLogin: GeneralRequestManager?
            errorOnLogin = GeneralRequestManager(url: URLManager.login("/activation"), errors: "", method: "POST", headers: nil, queryParameters: nil, bodyParameters: ["deviceId": deviceId as String, "user": user as! String], isCacheable: nil, contentType: "", bodyToPost: nil)

            errorOnLogin?.getResponse {
                resultString, error in

                print(resultString)
                print(error as Any)
            }

        default: break
        }
    }

    /**
     Save the current response in local storage for use when offline.
     */
    fileprivate func saveCachedResponse(_ data: Data) {
        let realm = RLMRealm.default()
        realm.beginWriteTransaction()

        var cachedResponse = cachedResponseForCurrentRequest()

        if cachedResponse == nil {
            cachedResponse = CachedResponse()
        }

        cachedResponse!.data = data

        if let url: URL? = url, let absoluteString = url?.absoluteString, let query = queryParameters?.keys.contains("setFirstResult") {
            let queries = queryParameters?.keys.count
            if queries == 1 {
                cachedResponse!.query = queryParameters?.filter { $0.key == "setFirstResult" }.values.first
                cachedResponse!.url = absoluteString
            }
        }

        if let url: URL? = url, let absoluteString = url?.absoluteString {
            if absoluteString.contains("images") {
                cachedResponse!.url = absoluteString
            }
        }

        cachedResponse!.timestamp = Date()
        if let response = urlResponse {
            if let mimeType = response.mimeType {
                cachedResponse!.mimeType = mimeType as NSString?
            }

            if let encoding = response.textEncodingName {
                cachedResponse!.encoding = encoding
            }
        }

        realm.add(cachedResponse!)

        do {
            try realm.commitWriteTransaction()
        } catch {
            print("Something went wrong!")
        }
    }

    /**
     Gets a cached response from local storage if there is any.

     :returns: A CachedResponse optional object.
     */
    func cachedResponseForCurrentRequest() -> CachedResponse? {
        if let url: URL? = url, let absoluteString = url?.absoluteString, let query = queryParameters?.keys.contains("setFirstResult") {
            let queries = queryParameters?.keys.count
            if queries == 1 {
                let queryValue = queryParameters?.values.first
                let p = NSPredicate(format: "query == %@", argumentArray: [queryValue!])

                // Query
                let results = CachedResponse.objects(with: p)
                if results.count > 0 {
                    return results.object(at: 0) as? CachedResponse
                }
            }
        } else if let url: URL? = url, let absoluteString = url?.absoluteString {
            let p = NSPredicate(format: "url == %@", argumentArray: [absoluteString])

            // Query
            let results = CachedResponse.objects(with: p)
            if results.count > 0 {
                return results.object(at: 0) as? CachedResponse
            }
        }

        return nil
    }
}
