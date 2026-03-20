//
//  RestApiManager.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 27/03/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import Foundation
import SwiftyJSON

// import Kanna

typealias ServiceResponse = (JSON, NSError?) -> Void

class RestApiManager: NSObject, UIAlertViewDelegate, AlertViewProtocol {
    var alertViewPresentingVC: UIViewController?

    static let sharedInstance = RestApiManager()
    let baseURL = URLManager.login("/admin?JSESSIONID=")

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

    func getRandomUser(_ onCompletion: @escaping (JSON, NSError?) -> Void) {
        // let prefs: UserDefaults = UserDefaults.standard
        let route = baseURL

        makeHTTPGetRequest(route, onCompletion: { json, err in
            onCompletion(json as JSON, err)
        })
    }

    func makeHTTPGetRequest(_ path: String, onCompletion: @escaping ServiceResponse) {
        let prefs = UserDefaults.standard
        let xtoken = prefs.value(forKey: "X-Token")

        let request = URLRequest.requestWithURL(URL(string: path)!, method: "GET", queryParameters: nil, bodyParameters: nil, headers: ["Ciphertext": xtoken as? String ?? "none"], cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 20, isCacheable: nil, contentType: "", bodyToPost: nil)

        let session = URLSession.sharedCustomSession

        let task = session.dataTask(with: request, completionHandler: { data, response, sessionError in

            var error = sessionError

            if let httpResponse = response as? HTTPURLResponse {
                // TODO: check it on the server side
                if httpResponse.statusCode == 200 {
                    let json: JSON = try! JSON(data: data!)
                    onCompletion(json, error as NSError?)
                }

                if httpResponse.statusCode < 200 || httpResponse.statusCode > 300 {
                    let description = "HTTP response was \(httpResponse.statusCode)"

                    error = NSError(domain: "Custom", code: 0, userInfo: [NSLocalizedDescriptionKey: description])
                    var errorMsg = ""
                    if let json: JSON = try? JSON(data: data!) {
                        if let message_ = json["Error Details"].object as? NSDictionary {
                            errorMsg = message_.value(forKey: "Error Message:") as! String
                        }
                        errorMsg = ", " + errorMsg
                    }
                    self.alertViewPresentingVC = UIAlertController()
                    self.alertViewPresentingVC!.presentAlert(withTitle: "Error", message: error!.localizedDescription + errorMsg)
                    NSLog(error!.localizedDescription)
                }

                if httpResponse.statusCode == 300 {
                    let alertView = UIAlertView()

                    let jsonData: NSDictionary = try! JSONSerialization.jsonObject(with: data!, options:

                        JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary

                    let messageArray = jsonData.value(forKey: "Error Details") as? NSArray
                    let message_ = messageArray![0]
                    let messageObj = (message_ as AnyObject).value(forKey: "Error Details")
                    let message = (messageObj as AnyObject).value(forKey: "Activation")

                    alertView.title = "Activation is required! To send the activation email tap on the Okay button!"
                    alertView.message = "Voucher is active: \(message as! NSString)"
                    alertView.delegate = self
                    alertView.addButton(withTitle: "Okay")
                    alertView.addButton(withTitle: "Cancel")
                    alertView.cancelButtonIndex = 1
                    alertView.show()

                    let json: JSON = try! JSON(data: data!)
                    onCompletion(json, error as NSError?)
                }

                if error != nil {
                    let alertView = UIAlertView()
                    if httpResponse.statusCode == 503 {
                        if let result = NSString(data: data!, encoding: String.Encoding.ascii.rawValue) as String? {
                            UIAlertController.popUp(title: "Error: \(httpResponse.statusCode)", message: result)
                        }
                    }

                    if httpResponse.statusCode == 502 {
                        let json: JSON = try! JSON(data: data!)
                        let prefs = UserDefaults.standard
                        prefs.set(0, forKey: "ISLOGGEDIN")
                        print(json)
                        onCompletion(json, error as NSError?)
                    }

                    if httpResponse.statusCode == 500 {
                        // assumes the Exception handler servlet is on
                        // let json: JSON = try! JSON(data: data!)
                        UIAlertController.popUp(title: "Error: \(httpResponse.statusCode)", message: "Server erro 500. See the logs for more details")
                    }
                }

            } else {
                do {
                    // TODO: check it on the server side
                    let json: JSON = try JSON(data: data!)
                    onCompletion(json, error as NSError?)
                } catch {
                    UIAlertController.popUp(title: "Error: ", message: "no response")
                }
            }
        })
        task.resume()
    }
}
