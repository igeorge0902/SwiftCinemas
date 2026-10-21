// PopOver.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import UIKit

// import FacebookCore
// import Braintree

nonisolated(unsafe) var tickets = [String: String]()
/**
 Legacy seat selection globals were replaced by manager-owned context.
 */
nonisolated(unsafe) var tableView_: UITableView?
class PopOver: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate {
    private lazy var viewModel = SeatSelectionViewModel(seats: .shared, basket: .shared, dates: .shared, movies: .shared, venues: .shared)
    // MARK: Lifecycle

    // lazy var braintreeClient = BTAPIClient(authorization: "sandbox_dpdzm97y_j3ndqpzrhy4gp2p7")!

    deinit {
        print(#function, "\(self)")
    }

    // MARK: Internal

    lazy var storedOffsets = [Int: CGFloat]()
    lazy var label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_: Bool) {
        let frame2 = CGRect(x: view.frame.width * 0.10, y: 55, width: view.frame.width, height: 20)

        label = UILabel(frame: frame2)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left

        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailText = NSMutableAttributedString(string: viewModel.displayDate, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

        label.attributedText = detailText

        view.addSubview(label)
        // FIX: size
        let frame = CGRect(x: 0, y: 90, width: view.frame.width, height: view.frame.height - 120)
        tableView_ = UITableView(frame: frame)
        tableView_?.delegate = self
        tableView_?.dataSource = self
        tableView_?.rowHeight = 75
        // tableView_?.allowsSelection = false

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.setTitle("Clear", for: UIControl.State())
        btnNav.showsTouchWhenHighlighted = true
        btnNav.addTarget(self, action: #selector(PopOver.clearSeatsToBeReserved), for: UIControl.Event.touchUpInside)

        let btnData = UIButton(frame: CGRect(x: view.frame.width / 2, y: 25, width: view.frame.width / 2, height: 20))
        btnData.backgroundColor = UIColor.black
        btnData.setTitle("Basket", for: UIControl.State())
        btnData.showsTouchWhenHighlighted = true
        btnData.addTarget(self, action: #selector(PopOver.openBasket), for: UIControl.Event.touchUpInside)

        view.addSubview(btnNav)
        view.addSubview(btnData)

        tableView_!.register(TableViewCell.self, forCellReuseIdentifier: "TableViewCell")
        // tableView_!.register(UITableViewCell.self, forCellReuseIdentifier: "NormalCell")

        view.addSubview(tableView_!)
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent {
            viewModel.resetSeatSelection()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        rowKeys.count
    }

    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? TableViewCell else { return }

        tableViewCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
        tableViewCell.collectionViewOffset = storedOffsets[indexPath.row] ?? 0
    }

    func tableView(_: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? TableViewCell else { return }

        storedOffsets[indexPath.row] = tableViewCell.collectionViewOffset
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell

        cell.backgroundColor = UIColor.groupTableViewBackground
        //  self.cellDelegate = self
        return cell
    }

    @objc func clearSeatsToBeReserved() {
        guard viewModel.clear() else { return }
        tableView_?.reloadData()
    }

    @objc func openBasket() {
        if viewModel.isBasketEmpty {
            presentAlert(withTitle: "Warning!", message: "No free seat(s) to be reserved!")

        } else {
            let storyboard = UIStoryboard(name: "Storyboard", bundle: nil)
            let pvc = storyboard.instantiateViewController(withIdentifier: "Basket")

            pvc.modalPresentationStyle = UIModalPresentationStyle.custom
            pvc.transitioningDelegate = self
            // pvc.view.backgroundColor = UIColor.groupTableViewBackgroundColor()

            present(pvc, animated: true, completion: nil)
        }
    }
}

private extension PopOver {
    var rowKeys: [String] {
        viewModel.rowKeys
    }

    func seats(forRowTag tag: Int) -> [SeatModel] {
        viewModel.seats(forRowTag: tag)
    }

    var selectedSeatsById: [Int: String] {
        viewModel.selectedSeatsById
    }
}

extension PopOver: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        seats(forRowTag: collectionView.tag).count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SeatCells = collectionView.dequeueReusableCell(withReuseIdentifier: "SeatCells", for: indexPath) as! SeatCells
        // cell.cellDelegate = self

        let seatsForRow = seats(forRowTag: collectionView.tag)
        guard indexPath.item < seatsForRow.count else { return cell }
        let seat = seatsForRow[indexPath.item]
        let total = Double(seat.price) * seat.tax
        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailText = NSMutableAttributedString(string: seat.seatNumber, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))
        let myTextAttribute_ = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "CourierNewPS-BoldMT", size: 11.0)!]
        let priceTag = NSMutableAttributedString(string: String(total).appending(" Ft"), attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute_))

        cell.textLabel.attributedText = detailText
        cell.priceLabel.attributedText = priceTag
        cell.layer.borderColor = UIColor.gray.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 5
        cell.backgroundColor = seat.isReserved ? UIColor.darkGray : UIColor.lightGray

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)

        return true
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let seatsForRow = seats(forRowTag: collectionView.tag)
        guard indexPath.row < seatsForRow.count else { return }
        let seatId = seatsForRow[indexPath.row].seatId
        let seatIds = [Int](selectedSeatsById.keys.sorted(by: { $0 < $1 }))
        if seatIds.contains(seatId) {
            cell.layer.borderWidth = 4
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? SeatCells

        cell?.layer.borderWidth = 4
        // cell?.layer.borderColor = UIColor.black.cgColor

        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)

        let seatsForRow = seats(forRowTag: collectionView.tag)
        guard indexPath.row < seatsForRow.count else { return }
        let selectedSeat = seatsForRow[indexPath.row]
        guard let selected = viewModel.toggle(selectedSeat) else { return }
        if !selected { cell?.layer.borderWidth = 1 }

        print("Collection view at row \(collectionView.tag) selected index path \(indexPath), section is \(indexPath.section), \(indexPath.row)")
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        let seatsForRow = seats(forRowTag: collectionView.tag)
        guard indexPath.row < seatsForRow.count else { return true }
        let seatId = seatsForRow[indexPath.row].seatId
        viewModel.deselect(seatId: seatId)

        return true
    }

    /// do something when user touches cell
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)

        // cell?.layer.borderColor = UIColor.black.cgColor
        cell?.layer.borderWidth = 4
    }

    /// do something when user releases touch
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)

        cell?.layer.borderWidth = 1
    }
}

/// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    input.rawValue
}

/// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
