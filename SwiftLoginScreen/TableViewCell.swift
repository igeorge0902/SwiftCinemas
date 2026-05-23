// TableViewCell.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import SwiftyJSON
import UIKit

class TableViewCell: UITableViewCell, UICollectionViewDelegateFlowLayout {
    // MARK: Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize.height = bounds.height * 0.9

        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        layout.itemSize = CGSize(width: 75.0, height: 65.0)

        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        collectionView.register(SeatCells.self, forCellWithReuseIdentifier: "SeatCells")
        collectionView.backgroundColor = UIColor.clear

        contentView.addSubview(collectionView)
        // addSubview(collectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: Internal

    var collectionView: UICollectionView!
    var cell: SeatCells!

    override func layoutSubviews() {
        super.layoutSubviews()
        // collectionView.delegate = self
        collectionView.frame = contentView.bounds
    }
}
