// SeatCells.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import UIKit

class SeatCells: UICollectionViewCell {
    // MARK: Lifecycle

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

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var textLabel: UILabel!
    var priceLabel: UILabel!

    var profileImage: UIImageView!
    var text: UITextView!
}
