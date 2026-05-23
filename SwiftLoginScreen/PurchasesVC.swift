// PurchasesVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import UIKit

class PurchasesVC: UIViewController, UITableViewDataSource, UITableViewDelegate, HasAppServices {
    // MARK: Lifecycle

    deinit {
        purchaseTableData.removeAll()
        print(#function, "\(self)")
    }

    // MARK: Internal

    var appServices: AppServices!
    var sortBy = "purchase"
    var purchaseTableData: [PurchaseSummaryModel] = []

    override func viewWillAppear(_: Bool) {
        super.viewWillAppear(true)
        addPurchasesData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        injectAppServicesIfNeeded()

        configureView()
        configureNavigation()
        configureSortButtons()
        configureTable()

        refresh()

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSNotification.Name(rawValue: "newDataNotif"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseDeletedFromTickets(_:)), name: Notifications.purchaseDeletedFromTickets, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        layoutTopNavigationButtons(navButtons, topOffset: 8)

        let topButtonBottom = navButtons.map { $0.frame.maxY }.max()
            ?? (view.safeAreaInsets.top + 42)

        let sortTop = topButtonBottom + 8

        let inset: CGFloat = 16
        let spacing: CGFloat = 10

        let sortWidth =
            (view.bounds.width - (inset * 2) - spacing) / 2

        sortButtons.first?.frame = CGRect(
            x: inset,
            y: sortTop,
            width: sortWidth,
            height: 34
        )

        sortButtons.dropFirst().first?.frame = CGRect(
            x: inset + sortWidth + spacing,
            y: sortTop,
            width: sortWidth,
            height: 34
        )

        label.frame = CGRect(
            x: inset,
            y: sortTop + 40,
            width: view.bounds.width - (inset * 2),
            height: 20
        )

        let tableTop = label.frame.maxY + 6

        let bottomInset =
            view.safeAreaInsets.bottom + 12

        tableCard.frame = CGRect(
            x: 12,
            y: tableTop,
            width: view.bounds.width - 24,
            height: view.bounds.height
                - tableTop
                - bottomInset
        )

        tableView.frame = tableCard.bounds

        view.bringSubviewToFront(refundBubbleLabel)
        view.bringSubviewToFront(purchaseDeletedToastLabel)
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_tickets" {
            // CheckoutDataManager.shared.selectedPurchaseId
        }
    }

    @objc func sortByPurchaseDate() {
        sortBy = "purchase"
        updateSortLabel()
        applySorting()
        tableView.reloadData()
    }

    @objc func sortByScreeningDate() {
        sortBy = "screening"
        updateSortLabel()
        applySorting()
        tableView.reloadData()
    }

    @objc func refresh() {
        purchaseTableData.removeAll()
        addPurchasesData()
    }

    @objc func navigateBack() {
        dismiss(animated: true, completion: nil)
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        if sortBy == "purchase" {
            purchaseTableData[section].purchaseDate
        } else {
            purchaseTableData[section].screeningDate
        }
    }

    func tableView(
        _: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        let container = UIView()

        let label = UILabel()

        label.font = .systemFont(
            ofSize: 14,
            weight: .semibold
        )

        label.textColor = UIColor(
            white: 0.45,
            alpha: 1
        )

        label.text =
            sortBy == "purchase"
                ? purchaseTableData[section].purchaseDate
                : purchaseTableData[section].screeningDate

        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(
                equalTo: container.leadingAnchor,
                constant: 12
            ),

            label.bottomAnchor.constraint(
                equalTo: container.bottomAnchor,
                constant: -4
            ),
        ])

        return container
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PurchaseRowCell", for: indexPath) as? PurchaseRowCell else {
            return UITableViewCell()
        }

        let data = purchaseTableData[indexPath.section]

        cell.titleText.text = data.movieName
        cell.subtitleLabel.text = data.screeningDate

        if refundArmedSection == indexPath.section {
            cell.refundLabel.text = "Swipe left to refund"
            cell.pillLabel.text = "REFUND"

        } else {
            cell.refundLabel.text = "Tickets purchased"
            cell.pillLabel.text = "PAID"
        }

        let urlMovie = URLManager.image(data.moviePicture)

        Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let imgData = try await self.appServices.images.getData(urlString: urlMovie, realmCache: true)
                let image = UIImage(data: imgData)
                if let updatedCell = tableView.cellForRow(at: indexPath) as? PurchaseRowCell {
                    updatedCell.movieImageView.image = image
                }

            } catch {
                NSLog(
                    "PurchasesVC image: %@",
                    error.localizedDescription
                )
            }
        }

        return cell
    }

    func numberOfSections(in _: UITableView) -> Int {
        purchaseTableData.count
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if refundArmedSection == indexPath.section {
            return 122
        }
        return 82
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        CheckoutDataManager.shared.selectedPurchaseId = purchaseTableData[indexPath.section].purchaseId
        performSegue(withIdentifier: "goto_tickets", sender: self)
    }

    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard refundArmedSection == indexPath.section else {
            return nil
        }

        let confirmAction = UIContextualAction(style: .destructive, title: "Confirm") { [weak self] _, _, success in
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let purchaseId = self.purchaseTableData[indexPath.section].purchaseId
                    let movieName = self.purchaseTableData[indexPath.section].movieName
                    if try await CheckoutDataManager.shared.refundPurchase(purchaseId: purchaseId) {
                        self.purchaseTableData.remove(at: indexPath.section)
                        self.refundedEntries.insert("#\(purchaseId) \(movieName)", at: 0)
                        self.refundArmedSection = nil
                        self.updateRefundBubble()
                        self.tableView.reloadData()
                    }
                } catch {
                    NSLog("delete purchase: %@", error.localizedDescription)
                }
            }
            success(true)
        }
        confirmAction.backgroundColor = .systemRed

        let cancelAction = UIContextualAction(style: .normal, title: "Cancel") { [weak self] _, _, success in
            self?.showRefundHint(for: indexPath.section)
            self?.tableView.reloadRows(at: [indexPath], with: .none)
            success(true)
        }
        cancelAction.backgroundColor = .systemGray

        let config = UISwipeActionsConfiguration(actions: [confirmAction, cancelAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    func addPurchasesData() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                self.purchaseTableData = try await CheckoutDataManager.shared.fetchAllPurchases()
                self.tableView.reloadData()
            } catch {
                NSLog("addPurchasesData: %@", error.localizedDescription)
                self.presentAlert(withTitle: "Error", message: error.localizedDescription)
            }
        }
    }

    // MARK: Private

    private enum Notifications {
        static let purchaseDeletedFromTickets = Notification.Name("purchaseDeletedFromTickets")
    }

    private lazy var tableCard = createTableCard()
    private var label = UILabel()
    private var tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private var navButtons: [UIButton] = []
    private var sortButtons: [UIButton] = []
    private var refundArmedSection: Int?
    private var refundedEntries: [String] = []

    private lazy var purchaseDeletedToastLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.numberOfLines = 2
        label.backgroundColor = UIColor(red: 238 / 255, green: 243 / 255, blue: 1, alpha: 1)
        label.textColor = UIColor(red: 43 / 255, green: 79 / 255, blue: 147 / 255, alpha: 1)
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textAlignment = .left
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var refundBubbleLabel: UILabel = {
        let view = UILabel()

        view.isHidden = true
        view.numberOfLines = 0
        view.isUserInteractionEnabled = false

        view.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        view.textColor = .black

        view.font = UIFont(name: "Courier New", size: 12) ?? .monospacedSystemFont(ofSize: 12, weight: .regular)

        view.layer.cornerRadius = 14
        view.layer.masksToBounds = false

        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.12
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 4)

        view.textAlignment = .left
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private func createTableCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(white: 0.86, alpha: 1).cgColor
        card.clipsToBounds = true
        return card
    }

    private func configureView() {
        view.backgroundColor = UIColor(white: 0.95, alpha: 1)

        view.addSubview(label)
        view.addSubview(tableCard)
        view.addSubview(refundBubbleLabel)
        view.addSubview(purchaseDeletedToastLabel)
        view.bringSubviewToFront(refundBubbleLabel)
        view.bringSubviewToFront(purchaseDeletedToastLabel)

        NSLayoutConstraint.activate([
            refundBubbleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 16
            ),

            refundBubbleLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -16
            ),

            refundBubbleLabel.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -12
            ),

            purchaseDeletedToastLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 50
            ),

            purchaseDeletedToastLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 12
            ),

            purchaseDeletedToastLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -12
            ),
        ])
    }

    private func configureTable() {
        tableCard.clipsToBounds = false

        tableView.dataSource = self
        tableView.delegate = self
        tableView.clipsToBounds = false
        tableView.rowHeight = 82
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 16, right: 0)
        tableView.register(PurchaseRowCell.self, forCellReuseIdentifier: "PurchaseRowCell")
        tableCard.addSubview(tableView)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))

        tableView.addGestureRecognizer(longPress)
        tableView.refreshControl = refreshControl
    }

    private func applySorting() {
        switch sortBy {
        case "screening":
            purchaseTableData.sort {
                $0.screeningDate > $1.screeningDate
            }

        default:
            purchaseTableData.sort {
                $0.purchaseDate > $1.purchaseDate
            }
        }
    }

    private func configureNavigation() {
        navButtons = addTopNavigationButtons([
            (title: "Back", action: #selector(navigateBack)),
        ])
    }

    private func configureSortButtons() {
        let screeningButton = makeControlButton(
            title: "By Screening",
            action: #selector(sortByScreeningDate)
        )

        let purchaseButton = makeControlButton(
            title: "By Purchase",
            action: #selector(sortByPurchaseDate)
        )

        sortButtons = [screeningButton, purchaseButton]
        sortButtons.forEach(view.addSubview)

        label.textColor = .black
        label.font = UIFont(
            name: "Courier New",
            size: 13
        )

        updateSortLabel()
    }

    private func updateSortLabel() {
        label.text = "Sorted by \(sortBy)"
    }

    @objc private func handlePurchaseDeletedFromTickets(_ notification: Notification) {
        let purchaseId = notification.userInfo?["purchaseId"] as? String ?? ""
        let suffix = purchaseId.isEmpty ? "" : " #\(purchaseId)."
        purchaseDeletedToastLabel.text = "  Purchase deleted (all tickets cancelled).\n  Navigated back from Tickets\(suffix)"
        purchaseDeletedToastLabel.alpha = 1
        purchaseDeletedToastLabel.isHidden = false
        refresh()

        UIView.animate(withDuration: 0.2, delay: 2.8, options: [.curveEaseOut], animations: {
            self.purchaseDeletedToastLabel.alpha = 0
        }, completion: { _ in
            self.purchaseDeletedToastLabel.alpha = 1
            self.purchaseDeletedToastLabel.isHidden = true
        })
    }

    private func makeControlButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        stylePrimaryButton(button, fontSize: 13)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func stylePrimaryButton(_ button: UIButton, fontSize: CGFloat) {
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: fontSize, weight: .semibold)
        button.layer.cornerRadius = 14
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let indexPath = tableView.indexPathForRow(
            at: gesture.location(in: tableView)
        ) else {
            return
        }

        let previousSection = refundArmedSection
        refundArmedSection = indexPath.section

        var reloads: [IndexPath] = [indexPath]
        if let previousSection, previousSection != indexPath.section {
            reloads.append(
                IndexPath(
                    row: 0,
                    section: previousSection
                )
            )
        }

        tableView.reloadRows(
            at: reloads,
            with: .automatic
        )

        tableView.beginUpdates()
        tableView.endUpdates()

        tableView.scrollToRow(
            at: indexPath,
            at: .middle,
            animated: true
        )

        UIImpactFeedbackGenerator(
            style: .light
        ).impactOccurred()

        showRefundHint(for: indexPath.section)
    }

    private func updateRefundBubble() {
        guard !refundedEntries.isEmpty else {
            refundBubbleLabel.isHidden = true
            refundBubbleLabel.text = nil
            return
        }

        let maxEntries = 4
        let visibleEntries = refundedEntries.prefix(maxEntries)
        refundBubbleLabel.text = "  Refunded\n  " + visibleEntries.joined(separator: "\n  ")
        refundBubbleLabel.isHidden = false
    }

    private func showRefundHint(for section: Int) {
        guard purchaseTableData.indices.contains(section) else { return }
        let purchase = purchaseTableData[section]
        let header = "  Refund armed for #\(purchase.purchaseId) \(purchase.movieName)\n  Swipe left and tap Refund"
        let history = refundedEntries.prefix(3)
        let historyText = history.isEmpty ? "" : "\n  \n  Refunded\n  " + history.joined(separator: "\n  ")
        refundBubbleLabel.text = header + historyText
        refundBubbleLabel.isHidden = false
    }
}
