//
//  Helpers.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 26/07/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import UIKit

func generateRandomData() -> [[UIColor]] {
    let numberOfRows = 20
    let numberOfItemsPerRow = 15

    // for all rows
    return (0 ..< numberOfRows).map { _ in

        // for any items in a row
        (0 ..< numberOfItemsPerRow).map { _ in

            UIColor.randomColor()
        }
    }
}

extension UIColor {
    class func randomColor() -> UIColor {
        let hue = CGFloat(arc4random() % 100) / 100
        let saturation = CGFloat(arc4random() % 100) / 100
        let brightness = CGFloat(arc4random() % 100) / 100

        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }
}
