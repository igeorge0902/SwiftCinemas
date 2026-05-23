// Time.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import UIKit

typealias zeroTime = Int64
typealias emptyString = String
// let currentTime = zeroTime(0).getCurrentMillis()

extension Int64 {
    func getCurrentMillis() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
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

    /// Allow gesture recognizer to work while still allowing interaction with other UI elements
    public func gestureRecognizer(_: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !(touch.view is UIControl) // Prevents interfering with buttons, sliders, etc.
    }

    func makeTopNavigationButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        applyTopNavigationButtonStyle(button, title: title)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    func applyTopNavigationButtonStyle(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .black
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.layer.cornerRadius = 14
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }

    @discardableResult
    func addTopNavigationButtons(_ specs: [(title: String, action: Selector)], topOffset: CGFloat = 8) -> [UIButton] {
        let tagBase = 9080
        for subview in view.subviews where subview.tag >= tagBase && subview.tag < tagBase + 10 {
            subview.removeFromSuperview()
        }

        let buttons = specs.enumerated().map { index, spec -> UIButton in
            let button = makeTopNavigationButton(title: spec.title, action: spec.action)
            button.tag = tagBase + index
            view.addSubview(button)
            return button
        }
        layoutTopNavigationButtons(buttons, topOffset: topOffset)
        return buttons
    }

    func layoutTopNavigationButtons(_ buttons: [UIButton], topOffset: CGFloat = 8) {
        guard !buttons.isEmpty else { return }

        let safeTop = view.safeAreaInsets.top
        let topY = safeTop + topOffset
        let horizontalInset: CGFloat = 16
        let spacing: CGFloat = 10
        let buttonHeight: CGFloat = 34

        if buttons.count == 1 {
            let button = buttons[0]
            button.sizeToFit()
            let width = min(max(120, button.bounds.width + 16), view.bounds.width - (horizontalInset * 2))
            button.frame = CGRect(x: horizontalInset, y: topY, width: width, height: buttonHeight)
            return
        }

        let width = (view.bounds.width - (horizontalInset * 2) - spacing) / CGFloat(buttons.count)
        for (index, button) in buttons.enumerated() {
            let x = horizontalInset + (CGFloat(index) * (width + spacing))
            button.frame = CGRect(x: x, y: topY, width: width, height: buttonHeight)
        }
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
        return dateFormatter.string(from: date.addingTimeInterval(timeinterval))
    }
}
