import UIKit

class ListViewCell: UITableViewCell {
    let movieImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let titleText: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white

        // Add subviews
        contentView.addSubview(movieImageView)
        contentView.addSubview(titleText)

        // Set up constraints
        setupConstraints()
        addShadow()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Ensure the cell always stays 180 in height
            contentView.heightAnchor.constraint(equalToConstant: 180),

            // ImageView constraints
            movieImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            movieImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            movieImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8),
            movieImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 120),
            movieImageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            // TitleLabel constraints (centered and placed below image)
            titleText.topAnchor.constraint(equalTo: movieImageView.bottomAnchor, constant: 8),
            titleText.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleText.widthAnchor.constraint(equalTo: movieImageView.widthAnchor),
            titleText.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    func configureCell(with image: UIImage?, title: String) {
        movieImageView.image = image
        titleText.text = title
    }

    private func addShadow() {
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.3
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.layer.masksToBounds = false
    }

    // Ensure the cell does not shrink below 180 height
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 180)
    }
}
