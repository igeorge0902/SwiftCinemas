// TableViewCellExt.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import UIKit

extension TableViewCell {
    func setCollectionViewDataSourceDelegate(dataSourceDelegate: some UICollectionViewDataSource & UICollectionViewDelegate, forRow row: Int) {
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = row

        // Stops collection view if it was scrolling.
        collectionView.setContentOffset(collectionView.contentOffset, animated: true)
        collectionView.reloadData()
    }

    var collectionViewOffset: CGFloat {
        set {
            collectionView.contentOffset.x = newValue
        }
        get {
            collectionView.contentOffset.x
        }
    }
}
