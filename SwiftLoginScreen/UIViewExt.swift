// UIViewExt.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import UIKit

extension UIView {
    func addConstraintswithFormat(_ format: String, views: UIView...) {
        var ViewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            ViewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ViewsDictionary))
    }
}
