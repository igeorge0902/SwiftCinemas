//
//  CustomTableViewCell.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2019. 11. 11..
//  Copyright © 2019. George Gaspar. All rights reserved.
//
import Foundation
import UIKit

class CustomTableViewCell: UITableViewCell {
    var textLabels: UILabel?
    var profileImage: UIImageView?
    var statusText: UITextView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.white

        profileImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        profileImage?.contentMode = .scaleAspectFit
        profileImage?.backgroundColor = UIColor.clear
        profileImage?.translatesAutoresizingMaskIntoConstraints = false

        textLabels = UILabel(frame: CGRect(x: frame.width * 0.2, y: 0, width: frame.size.width, height: 40))
        textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        textLabel?.textAlignment = .center

        statusText = UITextView(frame: CGRect(x: 20, y: 10, width: frame.size.width * 0.8, height: 50))
        statusText?.font = UIFont.systemFont(ofSize: 14)
        statusText?.textAlignment = .center

        contentView.addSubview(statusText!)
        contentView.addSubview(profileImage!)
        contentView.addSubview(textLabels!)

        addConstraintswithFormat("H:|-8-[v0(44)]-8-[v1]|", views: profileImage!, textLabels!)
        addConstraintswithFormat("V:|-12-[v0]", views: textLabels!)
        addConstraintswithFormat("V:|-8-[v0(44)]", views: profileImage!)
        addConstraintswithFormat("H:|-4-[v0]-4-|", views: statusText!)
        addConstraintswithFormat("V:|-8-[v0(44)]-4-[v1(90)]", views: profileImage!, statusText!)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
