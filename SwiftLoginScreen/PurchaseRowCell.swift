// PurchaseRowCell.swift
// Created by Gyorgy Gaspar on 2026.05.23.

//
//  PurchaseCell.swift
//  SwiftCinemas
//
//  Created by GYORGY GASPAR on 2026. 05. 22..
//  Copyright © 2026 George Gaspar. All rights reserved.
//
import UIKit

final class PurchaseRowCell: UITableViewCell {
    // MARK: Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = false
        contentView.clipsToBounds = false

        buildHierarchy()
        configureStacks()
        buildConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let movieImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 6
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let titleText: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.textAlignment = .left
        label.isUserInteractionEnabled = false
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 11)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        return subtitleLabel
    }()

    let refundLabel: UILabel = {
        let refundLabel = UILabel()
        refundLabel.font = .systemFont(ofSize: 10)
        return refundLabel
    }()

    let pillLabel: UILabel = {
        let pillLabel = UILabel()
        pillLabel.font = .systemFont(ofSize: 11)
        pillLabel.textAlignment = .center
        pillLabel.textColor = .black
        pillLabel.backgroundColor = UIColor(
            white: 0.96,
            alpha: 1
        )

        pillLabel.layer.cornerRadius = 999
        pillLabel.layer.borderWidth = 1
        pillLabel.layer.borderColor = UIColor(
            white: 0.85,
            alpha: 1
        ).cgColor

        pillLabel.clipsToBounds = true
        pillLabel.setContentCompressionResistancePriority(
            .required,
            for: .horizontal
        )
        pillLabel.translatesAutoresizingMaskIntoConstraints = false
        return pillLabel
    }()

    func configureCell(with image: UIImage?, title: String) {
        movieImageView.image = image
        titleText.text = title
    }

    // MARK: Private

    private let textStack = UIStackView()
    private let leftStack = UIStackView()

    private let cardView: UIView = {
        let cardView = UIView()
        cardView.layer.cornerRadius = 10
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor(
            red: 229 / 255,
            green: 229 / 255,
            blue: 232 / 255,
            alpha: 1
        ).cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .white
        return cardView
    }()

    private func buildHierarchy() {
        contentView.addSubview(cardView)

        cardView.addSubview(leftStack)
        cardView.addSubview(pillLabel)

        leftStack.addArrangedSubview(movieImageView)
        leftStack.addArrangedSubview(textStack)

        textStack.addArrangedSubview(titleText)
        textStack.addArrangedSubview(subtitleLabel)
        textStack.addArrangedSubview(refundLabel)
    }

    private func configureStacks() {
        leftStack.axis = .horizontal
        leftStack.alignment = .center
        leftStack.spacing = 10
        leftStack.translatesAutoresizingMaskIntoConstraints = false

        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
    }

    private func buildConstraints() {
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            leftStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            leftStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            pillLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            pillLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            leftStack.trailingAnchor.constraint(lessThanOrEqualTo: pillLabel.leadingAnchor, constant: -8),

            movieImageView.widthAnchor.constraint(equalToConstant: 38),
            movieImageView.heightAnchor.constraint(equalToConstant: 54),
        ])
    }
}
