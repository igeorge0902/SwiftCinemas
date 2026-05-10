import UIKit

class MovieCollectionViewCell: UICollectionViewCell {
    var imageView: UIImageView!
    var textLabel: UILabel!
    var categoryLabel: UILabel!
    var screeningDateLabel: UILabel!
    var chevronLabel: UILabel!
    var representedImagePath: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.black.withAlphaComponent(0.12).cgColor
        contentView.layer.masksToBounds = true

        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = UIColor(white: 0.93, alpha: 1)
        contentView.addSubview(imageView)

        textLabel = UILabel()
        textLabel.numberOfLines = 1
        textLabel.textColor = .black
        contentView.addSubview(textLabel)

        categoryLabel = UILabel()
        categoryLabel.numberOfLines = 1
        categoryLabel.textColor = UIColor(white: 0.50, alpha: 1)
        contentView.addSubview(categoryLabel)

        screeningDateLabel = UILabel()
        screeningDateLabel.numberOfLines = 1
        screeningDateLabel.textColor = UIColor(white: 0.50, alpha: 1)
        contentView.addSubview(screeningDateLabel)

        chevronLabel = UILabel()
        chevronLabel.text = "›"
        chevronLabel.textColor = UIColor(red: 0.76, green: 0.80, blue: 0.88, alpha: 1)
        chevronLabel.font = .systemFont(ofSize: 18, weight: .medium)
        contentView.addSubview(chevronLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        screeningDateLabel.translatesAutoresizingMaskIntoConstraints = false
        chevronLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 52),
            imageView.heightAnchor.constraint(equalToConstant: 52),

            chevronLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            chevronLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronLabel.widthAnchor.constraint(equalToConstant: 12),

            textLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            textLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: chevronLabel.leadingAnchor, constant: -8),

            categoryLabel.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 6),
            categoryLabel.leadingAnchor.constraint(equalTo: textLabel.leadingAnchor),
            categoryLabel.trailingAnchor.constraint(equalTo: textLabel.trailingAnchor),

            screeningDateLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 3),
            screeningDateLabel.leadingAnchor.constraint(equalTo: textLabel.leadingAnchor),
            screeningDateLabel.trailingAnchor.constraint(equalTo: textLabel.trailingAnchor),
            screeningDateLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        representedImagePath = nil
        imageView.image = nil
        textLabel.attributedText = nil
        categoryLabel.attributedText = nil
        screeningDateLabel.attributedText = nil
    }

    func configureRedesign(title: String, category: String, screeningDate: String, fontName: String = "HelveticaNeue-Medium", fontSize: CGFloat = 14) {
        let titleFont = UIFont(name: fontName, size: fontSize) ?? .systemFont(ofSize: fontSize, weight: .semibold)
        textLabel.attributedText = NSAttributedString(string: title, attributes: [
            .font: titleFont,
            .foregroundColor: UIColor.black,
        ])

        let metadataFont = UIFont(name: fontName, size: 12) ?? .systemFont(ofSize: 12, weight: .regular)
        categoryLabel.attributedText = NSAttributedString(string: category, attributes: [
            .font: metadataFont,
            .foregroundColor: UIColor(white: 0.5, alpha: 1),
        ])
        screeningDateLabel.attributedText = NSAttributedString(string: screeningDate, attributes: [
            .font: metadataFont,
            .foregroundColor: UIColor(white: 0.5, alpha: 1),
        ])
    }
}

final class TrendingCarouselCell: UICollectionViewCell {
    let posterImageView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor(white: 0.16, alpha: 0.95)
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.15
        contentView.layer.shadowRadius = 8
        contentView.layer.shadowOffset = CGSize(width: 0, height: 4)

        posterImageView.translatesAutoresizingMaskIntoConstraints = false
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.layer.cornerRadius = 8
        posterImageView.backgroundColor = UIColor(white: 0.22, alpha: 1.0)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.numberOfLines = 2

        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            posterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            posterImageView.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String) {
        titleLabel.text = title
        posterImageView.image = UIImage(systemName: "photo")
    }
}

final class TrendingListCell: UITableViewCell {
    let posterImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = UIColor(white: 0.12, alpha: 0.95)
        contentView.layer.cornerRadius = 0
        contentView.layer.shadowOpacity = 0

        posterImageView.translatesAutoresizingMaskIntoConstraints = false
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.layer.cornerRadius = 6
        posterImageView.backgroundColor = UIColor(white: 0.22, alpha: 1.0)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.numberOfLines = 1

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        descriptionLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        descriptionLabel.numberOfLines = 3
        descriptionLabel.lineBreakMode = .byTruncatingTail

        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            posterImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            posterImageView.widthAnchor.constraint(equalToConstant: 44),

            titleLabel.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, description: String) {
        titleLabel.text = title
        descriptionLabel.text = description
        posterImageView.image = UIImage(systemName: "photo")
    }
}
