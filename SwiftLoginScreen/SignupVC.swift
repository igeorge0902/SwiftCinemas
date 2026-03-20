//
//  SignupVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 27/03/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import SwiftyJSON
import UIKit

class SignupVC: UIViewController {
    var imageView: UIImageView = .init()
    var backgroundDict: [String: String] = Dictionary()

    deinit {
        print(#function, "\(self)")
    }

    lazy var session = URLSession.sharedCustomSession
    var running = false

    @IBOutlet var txtVoucher: UITextField!
    @IBOutlet var txtEmail: UITextField!

    @IBOutlet var txtUsername: UITextField!
    @IBOutlet var txtPassword: UITextField!
    @IBOutlet var txtConfirmPassword: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundDict = ["Signup": "signup"]

        let view = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))

        self.view.addSubview(view)

        self.view.sendSubviewToBack(view)

        let backgroundImage: UIImage? = UIImage(named: backgroundDict["Signup"]!)

        imageView = UIImageView(frame: view.frame)

        imageView.image = backgroundImage

        view.addSubview(imageView)

        hideKeyboardWhenTappedAround()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func gotoLogin(_: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    let url: URL = .init(string: URLManager.login("/voucher"))!
    let urlR: URL = .init(string: URLManager.login("/register"))!

    typealias ServiceResponse = (JSON, NSError?) -> Void

    func dataTask(_ voucher: String, email: String, username: String, hash: String, deviceId: String, systemVersion: String, onCompletion _: @escaping ServiceResponse) {
        var requestV = URLRequest(url: url)
        var request = URLRequest(url: urlR)

        // post data. The server will use this data to reproduce the hash
        let post: NSString = "user=\(username)&email=\(email)&pswrd=\(hash)&deviceId=\(deviceId)&voucher_=\(voucher)&ios=\(systemVersion)" as NSString

        let postV: NSString = "voucher=\(voucher)" as NSString

        let postData: Data = post.data(using: String.Encoding.ascii.rawValue)!
        let postDataV: Data = postV.data(using: String.Encoding.ascii.rawValue)!

        // content length
        let postLength: NSString = String(postData.count) as NSString
        let postLengthV: NSString = String(postDataV.count) as NSString

        let time = zeroTime(0).getCurrentMillis()

        // hmac data
        let post_ = "/login/register:user=\(username)&email=\(email)&pswrd=\(hash)&deviceId=\(deviceId)&voucher_=\(voucher):\(time):\(post.length)"

        let hmacSHA512 = CryptoJS.hmacSHA512()

        // Create secret for "X-HMAC-HASH" header generation
        let hmacSec: NSString = hmacSHA512.hmac(username as String, secret: hash as String) as NSString

        // Create base64 encoded hmacHash for "X-HMAC-HASH" header
        let hmacHash: NSString = hmacSHA512.hmac(post_, secret: hmacSec as String) as NSString

        NSLog("hmacSecret: %@", hmacSec)
        NSLog("PostData: %@", post)
        NSLog("PostData: %@", postV)

        request.httpMethod = "POST"
        request.httpBody = postData
        request.setValue(postLength as String, forHTTPHeaderField: "Content-Length")

        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(hmacHash as String, forHTTPHeaderField: "X-HMAC-HASH")
        request.setValue(String(time), forHTTPHeaderField: "X-MICRO-TIME")

        requestV.httpMethod = "POST"
        requestV.httpBody = postDataV
        requestV.setValue(postLengthV as String, forHTTPHeaderField: "Content-Length")

        requestV.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        requestV.setValue("application/json", forHTTPHeaderField: "Accept")

        let taskV = session.dataTask(with: requestV, completionHandler: { _, response, sessionError in

            var error = sessionError

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                    let description = "HTTP response was \(httpResponse.statusCode)"

                    error = NSError(domain: "Custom", code: 0, userInfo: [NSLocalizedDescriptionKey: description])

                    NSLog(error!.localizedDescription)
                }

                if error != nil {
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 412 {
                            self.presentAlert(withTitle: "SignUp Failed!", message: "Voucher is already used! \(error!.localizedDescription)")

                        } else {
                            self.presentAlert(withTitle: "Connection Failure!", message: error!.localizedDescription)
                        }
                    } else {
                        self.presentAlert(withTitle: "Connection Failure!", message: error!.localizedDescription)
                    }

                } else {
                    switch httpResponse.statusCode {
                    case 200:

                        do {
                            self.dataTask(request, username: username, onCompletion: { (json, _: NSError?) in
                                print(json)
                            })
                        }

                    default:

                        self.presentAlert(withTitle: "SignUp Failed!", message: "Server error \(httpResponse.statusCode)")
                    }
                }
            }
        })

        taskV.resume()
    }

    func dataTask(_ request: URLRequest, username: String, onCompletion _: @escaping ServiceResponse) {
        let task = session.dataTask(with: request, completionHandler: { data, response, sessionError in

            var error = sessionError
            let json: JSON = try! JSON(data: data!)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                    let description = "HTTP response was \(httpResponse.statusCode)"

                    error = NSError(domain: "Custom", code: 0, userInfo: [NSLocalizedDescriptionKey: description])
                    NSLog(error!.localizedDescription)
                }
            }

            if error != nil {
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 502 {
                        let jsonData: NSDictionary = try! JSONSerialization.jsonObject(with: data!, options:

                            JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary

                        let message: NSString = jsonData.value(forKey: "Message") as! NSString

                        self.presentAlert(withTitle: "SignUp Failed!", message: "Error: \(message)")

                    } else {
                        self.presentAlert(withTitle: "Connection Failure!", message: error!.localizedDescription)
                    }
                }

            } else {
                // let json:JSON = JSON(data: data!)

                if let httpResponse = response as? HTTPURLResponse {
                    print("got some data")

                    switch httpResponse.statusCode {
                    case 200:

                        let prefs = UserDefaults.standard

                        let jsonData: NSDictionary = try! JSONSerialization.jsonObject(with: data!, options:

                            JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary

                        let success: NSInteger = jsonData.value(forKey: "success") as! NSInteger
                        let sessionID: NSString = jsonData.value(forKey: "JSESSIONID") as! NSString
                        let xtoken: NSString = jsonData.value(forKey: "X-Token") as! NSString

                        NSLog("sessionId ==> %@", sessionID)

                        NSLog("Success: %ld", success)

                        if success == 1 {
                            NSLog("Login SUCCESS")

                            prefs.set(username, forKey: "USERNAME")
                            prefs.set(1, forKey: "ISLOGGEDIN")
                            prefs.set(0, forKey: "ISWEBLOGGEDIN")
                            prefs.setValue(sessionID, forKey: "JSESSIONID")
                            prefs.setValue(deviceId, forKey: "deviceId")
                            prefs.setValue(xtoken, forKey: "X-Token")

                            prefs.synchronize()
                        }

                        NSLog("got a 200")
                        self.dismiss(animated: true, completion: nil)

                    default:

                        NSLog("Got an HTTP \(httpResponse.statusCode)")
                    }
                }
                //  onCompletion(json, error as NSError?)
            }
        })
        task.resume()
    }

    @IBAction func signupTapped(_: UIButton) {
        // let deviceId = UIDevice.currentDevice().identifierForVendor!.UUIDString
        NSLog("deviceId ==> %@", deviceId)
        let username: NSString = txtUsername.text! as NSString
        let password: NSString = txtPassword.text! as NSString
        let voucher: NSString = txtVoucher.text! as NSString
        let email: NSString = txtEmail.text! as NSString

        let systemVersion = UIDevice.current.systemVersion

        let SHA3 = CryptoJS.SHA3()

        let hash = SHA3.hash(password as String, outputLength: 512)

        let isUsername = username.isEqual(to: "")
        let isPassword = password.isEqual(to: "")
        let isEmail = email.isEqual(to: "")
        let isVoucher = voucher.isEqual(to: "")

        var ErrorData = [String]()

        if isUsername || isPassword || isEmail || isVoucher {
            let Message: NSDictionary = ["Username": isUsername, "Password": isPassword, "Email": isEmail, "Voucher": isVoucher]

            for (bookid, title) in Message {
                if (title as AnyObject).isEqual(to: 1) {
                    ErrorData.append(bookid as! String)
                }
            }

            presentAlert(withTitle: "SignUp Failed!", message: "Please enter \(ErrorData.minimalDescrption)!")

        } else {
            dataTask(voucher as String, email: email as String, username: username as String, hash: hash, deviceId: deviceId, systemVersion: systemVersion) {
                resultString, _ in

                // TODO: finish the login
                print(resultString)
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField!) -> Bool { // delegate method
        textField.resignFirstResponder()
        return true
    }
}
