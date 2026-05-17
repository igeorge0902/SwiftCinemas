//
//  AdminVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2020. 09. 30..
//  Copyright © 2020. George Gaspar. All rights reserved.
//

import Foundation
import UIKit

var adminPage = false
var adminUpdatePage = false
var addMovie = ""
var addMovieId = ""
var addVenueId = ""
var addVenue = ""
var addScreeningID = ""
var addScreeningDate = ""
var addScreeningDateId = ""
var addCategory = ""
class AdminVC: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate, HasAppServices {
    var appServices: AppServices!
    deinit {
        print(#function, "\(self)")
    }

    @IBOutlet var movieName: UITextField!
    @IBOutlet var screeningDate: UITextField!
    @IBOutlet var nrOfRows: UITextField!
    @IBOutlet var venueName: UITextField!
    @IBOutlet var nrOfSeatsInRow: UITextField!
    @IBOutlet var ScreeningID: UITextField!
    @IBOutlet var category: UITextField!
    @IBOutlet var TrollErrorLabel: UILabel!

    let datePicker = UIDatePicker()

    @IBOutlet var scrollView: UIScrollView!
    private var saveButton: UIButton?
    private var topButtons: [UIButton] = []
    private var saveButtonHeightConstraint: NSLayoutConstraint?
    private var didConfigureScrollLayout = false
    private var didBuildCardLayout = false
    private weak var movieSelectButton: UIButton?
    private weak var venueSelectButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        injectAppServicesIfNeeded()
        adminPage = true
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)

        // scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.white
        configureScrollLayoutIfNeeded()
        buildCardLayoutIfNeeded()
        category.delegate = self
        ScreeningID.delegate = self
        category.placeholder = "Optional (Action/Drama/Crime/Romance/Troll)"
        styleSelectButtons()
        showDatePicker()

        NotificationCenter.default.addObserver(self, selector: #selector(AdminVC.refresh), name: NSNotification.Name(rawValue: "newScreenMovieSelected"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(AdminVC.refreshVenue), name: NSNotification.Name(rawValue: "newScreenVenueSelected"), object: nil)
    }

    override func viewWillAppear(_: Bool) {
        topButtons = addTopNavigationButtons([
            (title: "Back", action: #selector(AdminVC.navigateBack)),
            (title: "Update", action: #selector(AdminVC.adminUpdate)),
        ])

        if saveButton == nil {
            let btnAdd = UIButton(type: .system)
            btnAdd.setTitle("Save", for: .normal)
            stylePrimaryButton(btnAdd, fontSize: 14)
            btnAdd.translatesAutoresizingMaskIntoConstraints = false
            btnAdd.addTarget(self, action: #selector(AdminVC.addNewScreen), for: .touchUpInside)
            view.addSubview(btnAdd)

            saveButtonHeightConstraint = btnAdd.heightAnchor.constraint(equalToConstant: 38)
            NSLayoutConstraint.activate([
                btnAdd.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                btnAdd.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                btnAdd.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
                saveButtonHeightConstraint!,
            ])
            saveButton = btnAdd
        }

        view.setNeedsLayout()

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutTopNavigationButtons(topButtons, topOffset: 8)
        updateScrollInsetsForBottomAction()

    }

    private func updateScrollInsetsForBottomAction() {
        let buttonHeight = saveButtonHeightConstraint?.constant ?? 38
        let reserve = buttonHeight + view.safeAreaInsets.bottom + 20
        scrollView.contentInset.bottom = reserve
        scrollView.verticalScrollIndicatorInsets.bottom = reserve

    }

    @objc func refresh() {
        movieName.text = addMovie
    }

    @objc func refreshVenue() {
        venueName.text = addVenue
    }

    @objc func navigateBack() {
        dismiss(animated: true, completion: nil)
    }

    @objc func adminUpdate(_: UIButton, event _: UIEvent) {
        performSegue(withIdentifier: "goto_adminUpdate", sender: self)
    }

    @objc func addNewScreen() {
        let venue: NSString = venueName.text! as NSString
        let date: NSString = screeningDate.text! as NSString
        let movie: NSString = movieName.text! as NSString
        let nrOfRows_: NSString = nrOfRows.text! as NSString
        let nrOfSeatsInRow_: NSString = nrOfSeatsInRow.text! as NSString
        let ScreeningID_: NSString = ScreeningID.text! as NSString
        let category_: NSString = category.text! as NSString

        let testdata: [String: Any] = [
            "venue": venue as String,
            "movie": movie as String,
            "date": date as String,
            "nrOfRows": nrOfRows_ as String,
            "nrOfSeatsInRow": nrOfSeatsInRow_ as String,
            "ScreeningId": ScreeningID_ as String,
            "category": category_ as String,
        ]

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let screenResult = try await AdminDataManager.shared.addScreen(body: testdata)
                if screenResult.screeningId.contains("Error") {
                    self.presentAlert(withTitle: "Error:", message: "Duplicate ScreeningId: \(ScreeningID_)")

                } else {
                    self.presentAlert(withTitle: "Info:", message: "New screen added:, Screen: \(screenResult.movie)")
                }
            } catch {
                NSLog("addNewScreen: %@", error.localizedDescription)
            }
        }
    }

    @IBAction func selectMovies(_: UIButton) {
        adminPage = true
        DispatchQueue.main.async {
            let popOver = MoviesVC()
            popOver.modalPresentationStyle = UIModalPresentationStyle.popover
            popOver.preferredContentSize = CGSize(width: self.view.frame.width * 0.90, height: self.view.frame.height * 0.48)

            let popoverMenuViewController = popOver.popoverPresentationController
            popoverMenuViewController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            popoverMenuViewController?.delegate = self
            popoverMenuViewController?.sourceView = self.view
            popoverMenuViewController!.sourceRect = CGRect(
                x: self.view.frame.width * 0.50,
                y: self.view.frame.height * 0.70,
                width: 0,
                height: 0
            )

            self.present(
                popOver,
                animated: true,
                completion: nil
            )
        }
    }

    @IBAction func selectVenues(_: UIButton) {
        adminPage = true
        DispatchQueue.main.async {
            let popOver = VenuesVC()
            popOver.modalPresentationStyle = UIModalPresentationStyle.popover
            popOver.preferredContentSize = CGSize(width: self.view.frame.width * 0.90, height: self.view.frame.height * 0.48)

            let popoverMenuViewController = popOver.popoverPresentationController
            popoverMenuViewController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            popoverMenuViewController?.delegate = self
            popoverMenuViewController?.sourceView = self.view
            popoverMenuViewController?.backgroundColor = .white
            popoverMenuViewController!.sourceRect = CGRect(
                x: self.view.frame.width * 0.50,
                y: self.view.frame.height * 0.70,
                width: 0,
                height: 0
            )

            self.present(
                popOver,
                animated: true,
                completion: nil
            )
        }
    }

    func showDatePicker() {
        // Formate Date
        datePicker.datePickerMode = .dateAndTime

        // ToolBar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donedatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDatePicker))

        toolbar.setItems([doneButton, spaceButton, cancelButton], animated: false)

        screeningDate.inputAccessoryView = toolbar
        screeningDate.inputView = datePicker
    }

    @objc func donedatePicker() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        screeningDate.text = formatter.string(from: datePicker.date)
        view.endEditing(true)
    }

    @objc func cancelDatePicker() {
        view.endEditing(true)
    }

    func textFieldDidEndEditing(_: UITextField) {
        var CategoryData = [String]()
        CategoryData = ["Action", "Drama", "Crime", "Romance", "Troll"]

        if !CategoryData.contains(category.text!), category.text != "" {
            // self.presenAlertView(withTitle: "Hello", message: "Invalid category")
            category.text = ""
            TrollErrorLabel.isHidden = false
        }
        view.frame.origin.y = 0
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == ScreeningID {
            // self.view.frame.origin.y = -100
        }

        if textField == category {
            // self.view.frame.origin.y = -175
        }
    }

    func textFieldShouldBeginEditing(_: UITextField) -> Bool {
        true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
        view.endEditing(true)
    }

    func presentationController(forPresented presented: UIViewController, presenting _: UIViewController?, source _: UIViewController) -> UIPresentationController? {
        HalfSizePresentationController(presentedViewController: presented, presenting: presentingViewController)
    }

    class HalfSizePresentationController: UIPresentationController {
        override var frameOfPresentedViewInContainerView: CGRect {
            CGRect(x: 0, y: 200, width: containerView!.bounds.width, height: containerView!.bounds.height)
        }
    }

    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        .none
    }

    private func styleSelectButtons() {
        [movieSelectButton, venueSelectButton].compactMap { $0 }.forEach { styleSelectButton($0) }
    }

    private func stylePrimaryButton(_ button: UIButton, fontSize: CGFloat) {
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: fontSize, weight: .semibold)
        button.layer.cornerRadius = 14
    }

    private func styleSelectButton(_ button: UIButton) {
        button.backgroundColor = UIColor(white: 0.91, alpha: 1)
        button.setTitleColor(UIColor(white: 0.12, alpha: 1), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.layer.cornerRadius = 6
    }

    private func configureScrollLayoutIfNeeded() {
        guard !didConfigureScrollLayout else { return }
        didConfigureScrollLayout = true

        if scrollView.superview !== view {
            view.addSubview(scrollView)
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let attachedConstraints = view.constraints.filter { constraint in
            (constraint.firstItem as? UIView) === scrollView || (constraint.secondItem as? UIView) === scrollView
        }
        NSLayoutConstraint.deactivate(attachedConstraints)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func buildCardLayoutIfNeeded() {
        guard !didBuildCardLayout else { return }
        didBuildCardLayout = true

        movieName.isUserInteractionEnabled = false
        movieName.textColor = .systemGray

        let allButtons = collectButtons(in: scrollView)
            .filter { $0.currentTitle == "Select" }
            .sorted { $0.frame.minY < $1.frame.minY }
        movieSelectButton = allButtons.first
        venueSelectButton = allButtons.dropFirst().first

        guard let movieSelectButton, let venueSelectButton else { return }

        [movieName, venueName, screeningDate, nrOfRows, nrOfSeatsInRow, ScreeningID, category, movieSelectButton, venueSelectButton]
            .forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                $0.removeFromSuperview()
            }

        // Remove any leftover storyboard labels/containers that can overlap at the top.
        scrollView.subviews.forEach { $0.removeFromSuperview() }

        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentContainer)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentContainer.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentContainer.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentContainer.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentContainer.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor),

            contentStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            contentStack.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: contentContainer.topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: contentContainer.bottomAnchor, constant: -12),
        ])

        contentStack.addArrangedSubview(makeCard(title: "Select Movie and Venue", rows: [
            makeLabeledInputRow(label: "Movie", input: movieName, trailingButton: movieSelectButton),
            makeLabeledInputRow(label: "Venue", input: venueName, trailingButton: venueSelectButton),
        ]))

        contentStack.addArrangedSubview(makeCard(title: "When to Show", rows: [
            makeLabeledInputRow(label: "Screening Date", input: screeningDate, trailingButton: nil),
        ]))

        let capacityRow = UIStackView()
        capacityRow.axis = .horizontal
        capacityRow.spacing = 8
        capacityRow.distribution = .fillEqually
        capacityRow.addArrangedSubview(makeLabeledColumn(label: "Rows", input: nrOfRows))
        capacityRow.addArrangedSubview(makeLabeledColumn(label: "Seats", input: nrOfSeatsInRow))
        contentStack.addArrangedSubview(makeCard(title: "Theater Capacity", rows: [capacityRow]))

        contentStack.addArrangedSubview(makeCard(title: "Screen Details", rows: [
            makeLabeledInputRow(label: "Screen ID", input: ScreeningID, trailingButton: nil),
            makeLabeledInputRow(label: "Genre (optional)", input: category, trailingButton: nil),
        ]))

    }

    private func makeCard(title: String, rows: [UIView]) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(white: 0.98, alpha: 1)
        card.layer.cornerRadius = 10
        card.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        card.layer.borderWidth = 1

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = UIColor(white: 0.2, alpha: 1)

        let stack = UIStackView(arrangedSubviews: [titleLabel] + rows)
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
        ])
        return card
    }

    private func makeLabeledColumn(label: String, input: UIView) -> UIView {
        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 13)
        labelView.textColor = UIColor(white: 0.2, alpha: 1)

        let column = UIStackView(arrangedSubviews: [labelView, input])
        column.axis = .vertical
        column.spacing = 4
        NSLayoutConstraint.activate([
            input.heightAnchor.constraint(equalToConstant: 38),
        ])
        return column
    }

    private func makeLabeledInputRow(label: String, input: UIView, trailingButton: UIButton?) -> UIView {
        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 13)
        labelView.textColor = UIColor(white: 0.2, alpha: 1)

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8

        row.addArrangedSubview(input)
        NSLayoutConstraint.activate([
            input.heightAnchor.constraint(equalToConstant: 38),
        ])

        if let trailingButton {
            row.addArrangedSubview(trailingButton)
            NSLayoutConstraint.activate([
                trailingButton.widthAnchor.constraint(equalToConstant: 84),
                trailingButton.heightAnchor.constraint(equalToConstant: 36),
            ])
        }

        let stack = UIStackView(arrangedSubviews: [labelView, row])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }

    private func collectButtons(in root: UIView) -> [UIButton] {
        var result = [UIButton]()
        if let b = root as? UIButton { result.append(b) }
        for child in root.subviews {
            result.append(contentsOf: collectButtons(in: child))
        }
        return result
    }
}
