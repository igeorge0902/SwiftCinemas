//
//  CustomListTableViewCell.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2020. 04. 29..
//  Copyright © 2020. George Gaspar. All rights reserved.
//

import Foundation
import UIKit

class CustomListTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let padding = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        bounds = bounds.inset(by: padding)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
