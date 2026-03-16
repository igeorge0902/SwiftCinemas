//
//  UIViewExt.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2019. 11. 16..
//  Copyright © 2019. George Gaspar. All rights reserved.
//

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
