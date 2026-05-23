// AdminUIStyle.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import UIKit

extension UIButton {
    func applyAdminPrimaryButtonStyle(fontSize: CGFloat = 13, cornerRadius: CGFloat = 14) {
        backgroundColor = .black
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: fontSize, weight: .semibold)
        layer.cornerRadius = cornerRadius
    }

    func applyAdminDestructiveButtonStyle(fontSize: CGFloat = 13, cornerRadius: CGFloat = 14) {
        backgroundColor = UIColor(red: 215 / 255, green: 0, blue: 21 / 255, alpha: 1)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: fontSize, weight: .semibold)
        layer.cornerRadius = cornerRadius
    }

    func applyAdminSelectButtonStyle() {
        backgroundColor = UIColor(white: 0.91, alpha: 1)
        setTitleColor(UIColor(white: 0.12, alpha: 1), for: .normal)
        titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        layer.cornerRadius = 6
    }
}
