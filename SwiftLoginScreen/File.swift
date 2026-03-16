//
//  File.swift
//  Browser
//
//  Created by Joyce Echessa on 1/6/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import UIKit
import WebKit

class WV2: UIViewController, WKNavigationDelegate {
    var webView: WKWebView?

    /* Start the network activity indicator when the web view is loading */
    func webView(webView _: WKWebView,
                 didStartProvisionalNavigation _: WKNavigation)
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }

    /* Stop the network activity indicator when the loading finishes */
    func webView(webView _: WKWebView,
                 didFinishNavigation _: WKNavigation)
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    func webView(webView _: WKWebView,
                 decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse,
                 decisionHandler: (WKNavigationResponsePolicy) -> Void)
    {
        print(navigationResponse.response.MIMEType)

        decisionHandler(.Allow)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        /* Create our preferences on how the web page should be loaded */
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true

        /* Create a configuration for our preferences */
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences

        /* Now instantiate the web view */
        webView = WKWebView(frame: view.bounds, configuration: configuration)

        if let theWebView = webView {
            /* Load a web page into our web view */
            let url = NSURL(string: "https://milo.crabdance.com/javascript/mainpage.html")
            let urlRequest = NSURLRequest(URL: url!)
            theWebView.loadRequest(urlRequest)
            theWebView.navigationDelegate = self
            view.addSubview(theWebView)
        }
    }
}
