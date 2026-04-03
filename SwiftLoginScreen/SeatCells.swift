//
//  SeatCells.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 16/07/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import Foundation
import UIKit

class SeatCells: UICollectionViewCell {
    var textLabel: UILabel!
    var priceLabel: UILabel!

    var profileImage: UIImageView!
    var text: UITextView!

    override init(frame: CGRect) {
        super.init(frame: frame)

        textLabel = UILabel(frame: CGRect(x: frame.width * 0.1, y: 5, width: frame.size.width, height: 14))
        textLabel.font = UIFont.boldSystemFont(ofSize: UIFont.smallSystemFontSize)
        textLabel.textAlignment = .left

        priceLabel = UILabel(frame: CGRect(x: frame.width * 0.1, y: frame.size.height / 2, width: frame.size.width, height: 14))
        priceLabel.font = UIFont.boldSystemFont(ofSize: UIFont.smallSystemFontSize)
        priceLabel.textAlignment = .left

        contentView.addSubview(textLabel)
        contentView.addSubview(priceLabel)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
