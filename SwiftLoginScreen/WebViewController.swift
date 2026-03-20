//
//  WebViewController.swift
//
//
//  Created by Gaspar Gyorgy on 27/03/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    lazy var webView: WKWebView = .init()
    var response: URLResponse!
    var httpresponse: HTTPURLResponse!

    override func viewDidLoad() {
        super.viewDidLoad()

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.setTitle("Back", for: UIControl.State())
        btnNav.addTarget(self, action: #selector(WebViewController.navigateBack), for: UIControl.Event.touchUpInside)

        let btnReload = UIButton(frame: CGRect(x: view.frame.width / 2, y: 25, width: view.frame.width / 2, height: 20))
        btnReload.backgroundColor = UIColor.black
        btnReload.setTitle("Reload", for: UIControl.State())
        btnReload.showsTouchWhenHighlighted = true
        btnReload.addTarget(self, action: #selector(WebViewController.reloadPage), for: UIControl.Event.touchUpInside)

        view.addSubview(btnNav)
        view.addSubview(btnReload)

        // let config = WKWebViewConfiguration()
        // config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.frame = CGRect(x: 0, y: 60, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        definesPresentationContext = true
        webView.scrollView.bounces = true
        view.addSubview(webView)

        let requestURL = URL(string: URLManager.login("/index.html"))
        let urlrequest = URLRequest(url: requestURL!)

        let cookieStorage = HTTPCookieStorage.shared
        if let cookies_ = cookieStorage.cookies {
            for cookie in cookies_ {
                cookieStorage.deleteCookie(cookie)
            }
        }
        webView.load(urlrequest)
    }

    @objc func navigateBack() {
        dismiss(animated: true, completion: nil)
    }

    @objc func reloadPage() {
        webView.reload()
    }

    func webView(_ webView: WKWebView, didCommit _: WKNavigation!) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in

            for cookie in cookies {
                let cookieStorage = HTTPCookieStorage.shared

                cookieStorage.setCookie(cookie)

                if cookie.name == "X-Token" {
                    let prefs = UserDefaults.standard
                    prefs.setValue(cookie.value, forKey: "X-Token")
                }
            }

            print("cookis: \(cookies)")
        }
    }

    func webView(_ webView: WKWebView, shouldStartLoadWith request: URLRequest, navigationType _:
        WKNavigationType) -> Bool
    {
        let request = URLRequest(url: request.url!)

        let mutableRequest = request as! NSMutableURLRequest
        let ciphertext = cipherText.getCipherText(deviceId)
        mutableRequest.setValue(ciphertext, forHTTPHeaderField: "M-Device")
        mutableRequest.setValue("M", forHTTPHeaderField: "M")

        webView.load(request)

        return true
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        let path = webView.url?.relativePath ?? ""
        if path == "/login/tabularasa.html" || path == "/login/tabularasa.jsp" {
            dismiss(animated: true, completion: nil)
        }
    }

    func webView(_: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let cred = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, cred)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
