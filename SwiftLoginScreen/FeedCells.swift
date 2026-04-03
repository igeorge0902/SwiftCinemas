//
//  FeedCells.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 13/09/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import Foundation
import UIKit

class FeedCells: UICollectionViewCell {
    var textLabel: UILabel?
    var profileImage: UIImageView?
    var QRCodeImage: UIImageView?
    var CancelImage: UIImageView?
    var statusText: UITextView?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.white

        profileImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        profileImage?.contentMode = .scaleAspectFit
        profileImage?.backgroundColor = UIColor.clear
        profileImage?.translatesAutoresizingMaskIntoConstraints = false

        QRCodeImage = UIImageView(frame: CGRect(x: frame.width * 0.8, y: 10, width: 75, height: 75))
        QRCodeImage?.contentMode = .scaleAspectFit
        QRCodeImage?.backgroundColor = UIColor.clear
        QRCodeImage?.translatesAutoresizingMaskIntoConstraints = false

        CancelImage = UIImageView(frame: CGRect(x: frame.width * 0.9, y: 160, width: 25, height: 25))
        CancelImage?.contentMode = .scaleAspectFit
        CancelImage?.backgroundColor = UIColor.clear
        CancelImage?.translatesAutoresizingMaskIntoConstraints = false

        textLabel = UILabel(frame: CGRect(x: frame.width * 0.2, y: 0, width: frame.size.width, height: 40))
        textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        textLabel?.textAlignment = .center
        textLabel?.isUserInteractionEnabled = false

        statusText = UITextView(frame: CGRect(x: 1, y: 60, width: frame.size.width * 0.8, height: 100))
        statusText?.font = UIFont.systemFont(ofSize: 14)
        statusText?.textAlignment = .left
        statusText?.isUserInteractionEnabled = false

        contentView.addSubview(statusText!)
        contentView.addSubview(profileImage!)
        contentView.addSubview(QRCodeImage!)
        contentView.addSubview(textLabel!)
        contentView.addSubview(CancelImage!)

        addConstraintswithFormat("H:|-8-[v0(44)]-8-[v1]-8-[v2(44)]-8-|", views: profileImage!, textLabel!, QRCodeImage!)
        addConstraintswithFormat("V:|-8-[v0(44)]", views: profileImage!)
        addConstraintswithFormat("V:|-8-[v0]", views: textLabel!)
        addConstraintswithFormat("V:|-8-[v0(44)]", views: QRCodeImage!)

        addConstraintswithFormat("H:|-4-[v0]-4-|", views: statusText!)
        addConstraintswithFormat("V:|-8-[v0(44)]-4-[v1(90)]", views: profileImage!, statusText!)
        addConstraintswithFormat("H:[v0(25)]-8-|", views: CancelImage!)
        //  addConstraintswithFormat("V:[v0(25)]-8-[v1]", views: CancelImage!, textLabel!)
        addConstraintswithFormat("V:[v0(25)]-8-|", views: CancelImage!)
    }

    func toggleSelected() {
        if isSelected {
            backgroundColor = UIColor.purple

        } else {
            backgroundColor = UIColor.white
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
