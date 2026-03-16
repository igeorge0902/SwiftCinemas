//
//  HomeVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 27/03/16.
//  Copyright © 2016 George Gaspar. All rights reserved.

import CoreData
import SwiftyJSON
import UIKit
import WebKit

@available(iOS 9.0, *)
class HomeVC: UIViewController, UIViewControllerTransitioningDelegate {
    
    /* , WebSocketDelegate */
    deinit {
        print(#function, "\(self)")
    }

    var imageView: UIImageView!
    var backgroundDict: [String: String] = Dictionary()

    lazy var session = URLSession.sharedCustomSession
    var url: URL?

    var running = false
    var beenViewed = false
    var isConnected: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        UIApplication.shared.isNetworkActivityIndicatorVisible = false

        backgroundDict = ["Background1": "background1"]
        let backgroundImage: UIImage? = UIImage(named: backgroundDict["Background1"]!)

        imageView = UIImageView(frame: view.bounds)
        imageView.image = backgroundImage
        view.addSubview(imageView)
        MoviesData.addData()
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)

        UIApplication.shared.isNetworkActivityIndicatorVisible = false

        let prefs = UserDefaults.standard
        let isLoggedIn: Int = prefs.integer(forKey: "ISLOGGEDIN") as Int

        if isLoggedIn != 1 {
            dismiss(animated: true, completion: nil)
            performSegue(withIdentifier: "goto_login", sender: self)

        } else {}
    }

    // TODO: finish
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_map" {
            let nextSegue = segue.destination as? MapViewController
            nextSegue?.map2 = false
        }
    }

    typealias ServiceResponse = (JSON, NSError?) -> Void

    func dataTask(_: ServiceResponse) {
        url = URL(string: serverURL + "/login/logout")!

        var request = URLRequest(url: url!)

        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("", forHTTPHeaderField: "Referer")

        let task = session.dataTask(with: request, completionHandler: { data, response, sessionError in

            var error = sessionError

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                    let description = "HTTP response was \(httpResponse.statusCode)"

                    error = NSError(domain: "Custom", code: 0, userInfo: [NSLocalizedDescriptionKey: description])
                    NSLog(error!.localizedDescription)
                }
            }

            if error != nil {
                let alertView = UIAlertView()

                alertView.title = "Error!"
                alertView.message = "Connection Failure: \(error!.localizedDescription)"
                alertView.delegate = self
                alertView.addButton(withTitle: "OK")
                alertView.show()

            } else {
                if let httpResponse = response as? HTTPURLResponse {
                    NSLog("got some data")

                    switch httpResponse.statusCode {
                    case 200:

                        NSLog("got a " + String(httpResponse.statusCode) + " response code")

                        let jsonData: NSDictionary = (try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)) as! NSDictionary

                        let success: NSString = jsonData.value(forKey: "Success") as! NSString

                        if success == "true" {
                            NSLog("LogOut SUCCESS")

                            let appDomain = Bundle.main.bundleIdentifier
                            UserDefaults.standard.removePersistentDomain(forName: appDomain!)
                        }
                        self.performSegue(withIdentifier: "goto_login", sender: self)

                    default:

                        NSLog("Got an HTTP \(httpResponse.statusCode)")
                    }
                }

                self.running = false
            }
        })

        running = true
        task.resume()
    }

    @IBAction func basket(_: UIButton) {
        if BasketData_.count < 1 {
            UIAlertController.popUp(title: "Warning!", message: "No free seat(s) to be reserved!")

        } else {
            let storyboard = UIStoryboard(name: "Storyboard", bundle: nil)
            let pvc = storyboard.instantiateViewController(withIdentifier: "Basket")

            pvc.modalPresentationStyle = UIModalPresentationStyle.custom
            pvc.transitioningDelegate = self
            present(pvc, animated: true, completion: nil)
        }
    }

    @IBAction func logoutTapped(_: UIButton) {
        dataTask {
            resultString, error in

            print(error!)
            print(resultString)
        }
    }

    @IBAction func NearbyVenues(_: UIButton) {
        performSegue(withIdentifier: "goto_map", sender: self)
    }

    @IBAction func Navigation(_: UIButton) {
        // Create the AlertController
        let actionSheetController = UIAlertController(title: "Action Sheet", message: "Choose an option!", preferredStyle: .actionSheet)

        // Create and add the Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)

        // Create and add first option action
        let goToMenu = UIAlertAction(title: "Go to Menu", style: .default) { _ in

            self.performSegue(withIdentifier: "goto_menu", sender: self)
        }
        actionSheetController.addAction(goToMenu)

        // Create and add a second option action
        let goToLogin = UIAlertAction(title: "Go to Login Screen", style: .default) { _ in
            let prefs = UserDefaults.standard
            prefs.set(0, forKey: "ISLOGGEDIN")
            self.dismiss(animated: true, completion: nil)
            self.performSegue(withIdentifier: "goto_login", sender: self)
        }
        actionSheetController.addAction(goToLogin)
        // Present the AlertController
        // self.present(actionSheetController, animated: false, completion: nil)
        DispatchQueue.main.async {
            let topViewController = UIApplication.shared.keyWindow?.rootViewController
            topViewController?.present(actionSheetController, animated: true, completion: nil)
        }
    }

    @IBAction func WebView(_: UIButton) {
        // Dismiss the Old
        if let presented = presentedViewController {
            presented.removeFromParent()
        }
        performSegue(withIdentifier: "goto_webview", sender: self)
    }

    @IBAction func Movies(_: UIButton) {
        performSegue(withIdentifier: "goto_movies", sender: self)
    }

    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
        guard let input else { return nil }
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
    }

    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
        input.rawValue
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension UIViewController {
    func presentAlert(withTitle title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { _ in
        }
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }

    func presentAlertWithFunction(withTitle title: String, message: String, function: String) {
        var OKAction: UIAlertAction?

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if function == "sendEmail" {
            OKAction = UIAlertAction(title: "OK", style: .default, handler: { _ in

                let prefs = UserDefaults.standard
                let user = prefs.value(forKey: "USERNAME")

                var errorOnLogin: GeneralRequestManager?
                errorOnLogin = GeneralRequestManager(url: serverURL + "/login/activation", errors: "", method: "POST", headers: nil, queryParameters: nil, bodyParameters: ["deviceId": deviceId as String, "user": user as! String], isCacheable: nil, contentType: "", bodyToPost: nil)

                errorOnLogin?.getResponse {
                    resultString, error in

                    print(resultString)
                    print(error as Any)
                }
            })
        }
        if function.isEmpty {
            OKAction = UIAlertAction(title: "OK", style: .default) { _ in
            }
        }
        alertController.addAction(OKAction!)
        present(alertController, animated: true, completion: nil)
    }
}
