//
//  PurchasesVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2017. 09. 15..
//  Copyright © 2017. George Gaspar. All rights reserved.
//

import Foundation
import UIKit

class PurchasesVC: UIViewController, UITableViewDataSource, UITableViewDelegate, HasAppServices {
    private enum Notifications {
        static let purchaseDeletedFromTickets = Notification.Name("purchaseDeletedFromTickets")
    }

    var appServices: AppServices!
    deinit {
        purchaseTableData.removeAll()
        print(#function, "\(self)")
    }

    lazy var label = UILabel()
    var sortBy = "purchase"
    var refreshControl: UIRefreshControl!
    var tableView: UITableView?
    var purchaseTableData: [PurchaseSummaryModel] = []
    private var navButtons: [UIButton] = []
    private var sortButtons: [UIButton] = []
    private var refundArmedSection: Int?
    private var refundPendingSection: Int?
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
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.24)
        view.textColor = .black
        view.font = UIFont(name: "Courier New", size: 12) ?? .monospacedSystemFont(ofSize: 12, weight: .regular)
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.textAlignment = .left
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var ResponseText: String?
    var ResponseCode: String?
    var AuthCode: String?
    var Status: String?
    var Amount: String?
    var TaxAmount: String?
    var movieName: String?
    var purchaseId: String?

    lazy var layout = UICollectionViewFlowLayout()

    override func viewWillAppear(_: Bool) {
        super.viewWillAppear(true)
        purchaseTableData.removeAll()
        addPurchasesData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        injectAppServicesIfNeeded()

        view.backgroundColor = UIColor(white: 0.95, alpha: 1)
        configureStaticUI()

        refreshControl = UIRefreshControl()
        tableView?.addSubview(refreshControl)

        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left

        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailText = NSMutableAttributedString(string: sortBy, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

        label.attributedText = detailText

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSNotification.Name(rawValue: "newDataNotif"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseDeletedFromTickets(_:)), name: Notifications.purchaseDeletedFromTickets, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutTopNavigationButtons(navButtons, topOffset: 8)

        let topButtonBottom = navButtons.map { $0.frame.maxY }.max() ?? (view.safeAreaInsets.top + 42)
        let sortTop = topButtonBottom + 8
        let inset: CGFloat = 16
        let spacing: CGFloat = 10
        let sortWidth = (view.bounds.width - (inset * 2) - spacing) / 2
        sortButtons.first?.frame = CGRect(x: inset, y: sortTop, width: sortWidth, height: 34)
        sortButtons.dropFirst().first?.frame = CGRect(x: inset + sortWidth + spacing, y: sortTop, width: sortWidth, height: 34)

        label.frame = CGRect(x: inset, y: sortTop + 40, width: view.bounds.width - (inset * 2), height: 20)

        let tableTop = label.frame.maxY + 8
        let tableBottomInset = max(view.safeAreaInsets.bottom, 8)
        tableView?.frame = CGRect(x: 0, y: tableTop, width: view.bounds.width, height: max(0, view.bounds.height - tableTop - tableBottomInset))
    }

    private func configureStaticUI() {
        navButtons = addTopNavigationButtons([
            (title: "Back", action: #selector(PurchasesVC.navigateBack)),
        ])

        let btnSortScreening = makeControlButton(title: "By Screening", action: #selector(PurchasesVC.sortByScreeningDate))
        let btnSortPurchase = makeControlButton(title: "By Purchase", action: #selector(PurchasesVC.sortByPurchaseDate))
        sortButtons = [btnSortScreening, btnSortPurchase]
        sortButtons.forEach { view.addSubview($0) }

        label = UILabel(frame: .zero)
        view.addSubview(label)

        let frame = CGRect(x: 0, y: 110, width: view.frame.width, height: view.frame.height - 110)
        tableView = UITableView(frame: frame)
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        view.addSubview(tableView!)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView?.addGestureRecognizer(longPress)

        view.addSubview(refundBubbleLabel)
        view.addSubview(purchaseDeletedToastLabel)
        NSLayoutConstraint.activate([
            refundBubbleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            refundBubbleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            refundBubbleLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            purchaseDeletedToastLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            purchaseDeletedToastLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            purchaseDeletedToastLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
        ])

        // Keep the affordance visible until user interacts: long-press arms swipe refund.
        refundBubbleLabel.text = "  Long press a purchase row to enable swipe.\n  Swipe left, tap Refund, then swipe left again and tap Confirm."
        refundBubbleLabel.isHidden = false
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
        guard gesture.state == .began,
              let tableView,
              let indexPath = tableView.indexPathForRow(at: gesture.location(in: tableView)) else { return }
        refundArmedSection = indexPath.section
        refundPendingSection = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        showRefundHint(for: indexPath.section)
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
    }

    @objc func sortByPurchaseDate() {
        purchaseTableData.sort { $0.purchaseDate > $1.purchaseDate }
        sortBy = "purchase"
        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailText = NSMutableAttributedString(string: sortBy, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

        label.attributedText = detailText

        tableView?.reloadData()
    }

    @objc func sortByScreeningDate() {
        purchaseTableData.sort { $0.screeningDate > $1.screeningDate }
        sortBy = "screening"
        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailText = NSMutableAttributedString(string: sortBy, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

        label.attributedText = detailText

        tableView?.reloadData()
    }

    @objc func refresh() {
        purchaseTableData.removeAll()
        addPurchasesData()
    }

    @objc func navigateBack() {
        dismiss(animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_tickets" {
            CheckoutDataManager.shared.selectedPurchaseId = purchaseId
        }
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        if sortBy == "purchase" {
            purchaseTableData[section].purchaseDate
        } else {
            purchaseTableData[section].screeningDate
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "CELL") as UITableViewCell?

        if cell == nil {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "CELL")
        }

        if sortBy == "purchase" {
            purchaseTableData.sort { $0.purchaseDate > $1.purchaseDate }
        }
        if sortBy == "screening" {
            purchaseTableData.sort { $0.screeningDate > $1.screeningDate }
        }

        let data = purchaseTableData[indexPath.section]

        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailText = NSMutableAttributedString(string: data.movieName, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

        detailText.append(NSAttributedString(string: "\n\(purchaseTableData[indexPath.section].screeningDate)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 12.0)!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor(red: 155 / 255, green: 161 / 255, blue: 171 / 255, alpha: 1)])))

        cell!.textLabel?.numberOfLines = 5
        // cell!.textLabel?.translatesAutoresizingMaskIntoConstraints = false

        cell!.textLabel?.attributedText = detailText

        let urlMovie = URLManager.image(purchaseTableData[indexPath.section].moviePicture)

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let imgData = try await self.appServices.images.getData(urlString: urlMovie, realmCache: true)
                let image = UIImage(data: imgData)
                cell!.imageView?.image = image
                if let updatedCell = tableView.cellForRow(at: indexPath) {
                    updatedCell.imageView?.image = image
                    updatedCell.setNeedsLayout()
                }
            } catch {
                NSLog("PurchasesVC image: %@", error.localizedDescription)
            }
        }

        return cell!
    }

    func numberOfSections(in _: UITableView) -> Int {
        purchaseTableData.count
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        75
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        purchaseId = purchaseTableData[indexPath.section].purchaseId
        CheckoutDataManager.shared.selectedPurchaseId = purchaseId
        performSegue(withIdentifier: "goto_tickets", sender: self)
    }

    func tableView(_: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        guard refundArmedSection == indexPath.section else {
            return nil
        }

        if refundPendingSection == indexPath.section {
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
                            self.refundPendingSection = nil
                            self.updateRefundBubble()
                            self.tableView?.reloadData()
                        }
                    } catch {
                        NSLog("delete purchase: %@", error.localizedDescription)
                    }
                }
                success(true)
            }
            confirmAction.backgroundColor = .systemRed

            let cancelAction = UIContextualAction(style: .normal, title: "Cancel") { [weak self] _, _, success in
                self?.refundPendingSection = nil
                self?.showRefundHint(for: indexPath.section)
                self?.tableView?.reloadRows(at: [indexPath], with: .none)
                success(true)
            }
            cancelAction.backgroundColor = .systemGray

            let config = UISwipeActionsConfiguration(actions: [confirmAction, cancelAction])
            config.performsFirstActionWithFullSwipe = false
            return config
        }

        let armConfirmAction = UIContextualAction(style: .normal, title: "Refund") { [weak self] _, _, success in
            self?.refundPendingSection = indexPath.section
            self?.showConfirmHint(for: indexPath.section)
            self?.tableView?.reloadRows(at: [indexPath], with: .none)
            success(true)
        }
        armConfirmAction.backgroundColor = .systemOrange

        let config = UISwipeActionsConfiguration(actions: [armConfirmAction])
        config.performsFirstActionWithFullSwipe = false
        return config
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

    private func showConfirmHint(for section: Int) {
        guard purchaseTableData.indices.contains(section) else { return }
        let purchase = purchaseTableData[section]
        let header = "  Confirm refund for #\(purchase.purchaseId) \(purchase.movieName)\n  Swipe left again and tap Confirm"
        let history = refundedEntries.prefix(3)
        let historyText = history.isEmpty ? "" : "\n  \n  Refunded\n  " + history.joined(separator: "\n  ")
        refundBubbleLabel.text = header + historyText
        refundBubbleLabel.isHidden = false
    }

    func addPurchasesData() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                self.purchaseTableData = try await CheckoutDataManager.shared.fetchAllPurchases()
                self.tableView?.reloadData()
            } catch {
                NSLog("addPurchasesData: %@", error.localizedDescription)
                self.presentAlert(withTitle: "Error", message: error.localizedDescription)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
