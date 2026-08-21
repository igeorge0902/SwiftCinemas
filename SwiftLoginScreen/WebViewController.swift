// WebViewController.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import UIKit
import WebKit

@MainActor
class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    lazy var webView: WKWebView = .init()
    private var authCheckTimer: Timer?
    private var didHandleLogin = false

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

        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.frame = CGRect(x: 0, y: 60, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        definesPresentationContext = true
        webView.scrollView.bounces = true
        view.addSubview(webView)

        let requestURL = URL(string: URLManager.baseURL + URLManager.login("/film-review/#/login"))!
        webView.load(URLRequest(url: requestURL))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        authCheckTimer?.invalidate()
        authCheckTimer = nil
    }

    @objc func navigateBack() {
        authCheckTimer?.invalidate()
        authCheckTimer = nil
        dismiss(animated: true, completion: nil)
    }

    @objc func reloadPage() {
        webView.reload()
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        startAuthPolling()
    }

    private func startAuthPolling() {
        authCheckTimer?.invalidate()
        authCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            self?.checkAuthStateAndDismiss()
        }
        checkAuthStateAndDismiss()
    }

    private func checkAuthStateAndDismiss() {
        if didHandleLogin { return }

        let script = "JSON.stringify({hash: window.location.hash || '', user: localStorage.filmReviewUser || ''})"
        webView.evaluateJavaScript(script) { [weak self] result, _ in
            guard let self else { return }
            guard let jsonString = result as? String,
                  let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
            else { return }

            let hash = json["hash"] ?? ""
            let localUser = json["user"] ?? ""
            guard hash == "#/movies" else { return }

            self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                var cookieToken: String?
                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                    if cookie.name == "X-Token" {
                        cookieToken = cookie.value
                    }
                }

                if let token = cookieToken, !token.isEmpty {
                    UserDefaults.standard.setValue(token, forKey: "X-Token")
                    SecureStore.set(token, for: "X-Token")
                }
                if !localUser.isEmpty {
                    UserDefaults.standard.set(localUser, forKey: "USERNAME")
                    UserDefaults.standard.set(1, forKey: "ISLOGGEDIN")
                    UserDefaults.standard.set(1, forKey: "ISWEBLOGGEDIN")
                }

                self.didHandleLogin = true
                self.authCheckTimer?.invalidate()
                self.authCheckTimer = nil
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    func webView(_: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust
        {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
