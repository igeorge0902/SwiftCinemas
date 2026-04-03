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
        label.textColor = .label
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Constraints that differ between compact (text-only) and full (image+text) layouts
    private var compactConstraints: [NSLayoutConstraint] = []
    private var fullConstraints: [NSLayoutConstraint] = []
    private var sharedConstraints: [NSLayoutConstraint] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemBackground

        contentView.addSubview(movieImageView)
        contentView.addSubview(titleText)

        buildConstraints()
        // Default: full layout
        applyFullLayout()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildConstraints() {
        // ── Shared: image width/position ──
        sharedConstraints = [
            movieImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            movieImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8),
        ]

        // ── Full (180pt, image on top, label below) ──
        fullConstraints = [
            contentView.heightAnchor.constraint(equalToConstant: 180),
            movieImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            movieImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 120),
            movieImageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            titleText.topAnchor.constraint(equalTo: movieImageView.bottomAnchor, constant: 8),
            titleText.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleText.widthAnchor.constraint(equalTo: movieImageView.widthAnchor),
            titleText.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ]

        // ── Compact (60pt, label only, image hidden) ──
        compactConstraints = [
            titleText.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleText.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleText.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ]

        NSLayoutConstraint.activate(sharedConstraints)
    }

    /// Call with `true` for admin/update rows (text-only, 60pt height).
    func configureLayout(compact: Bool) {
        if compact {
            NSLayoutConstraint.deactivate(fullConstraints)
            NSLayoutConstraint.activate(compactConstraints)
            movieImageView.isHidden = true
            titleText.textAlignment = .left
        } else {
            NSLayoutConstraint.deactivate(compactConstraints)
            NSLayoutConstraint.activate(fullConstraints)
            movieImageView.isHidden = false
            titleText.textAlignment = .center
        }
        setNeedsLayout()
    }

    private func applyFullLayout() {
        NSLayoutConstraint.activate(fullConstraints)
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

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 180)
    }
}
