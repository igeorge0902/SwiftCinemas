//
//  Time.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 28/12/15.
//  Copyright © 2015 George Gaspar. All rights reserved.
//

import Foundation
import UIKit

typealias zeroTime = Int64
typealias emptyString = String
// let currentTime = zeroTime(0).getCurrentMillis()

extension Int64 {
    func getCurrentMillis() -> Int64 {
        let time = Int64(Date().timeIntervalSince1970 * 1000)

        return time
    }
}

extension Sequence {
    var minimalDescrption: String {
        map { String(describing: $0) }.joined(separator: " ")
    }
}

extension UIViewController: @retroactive UIGestureRecognizerDelegate {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.delegate = self
        tap.cancelsTouchesInView = false // Ensures other touch events are still recognized
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    // Allow gesture recognizer to work while still allowing interaction with other UI elements
    public func gestureRecognizer(_: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !(touch.view is UIControl) // Prevents interfering with buttons, sliders, etc.
    }
}

extension String {
    func convertDateFormater(_ date: String, timeinterval: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent

        guard let date = dateFormatter.date(from: date) else {
            // assert(false, "no date from string")
            return ""
        }

        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        let timeStamp = dateFormatter.string(from: date.addingTimeInterval(timeinterval))

        return timeStamp
    }
}
