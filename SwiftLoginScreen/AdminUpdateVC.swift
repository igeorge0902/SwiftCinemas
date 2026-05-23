// AdminUpdateVC.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import UIKit

nonisolated(unsafe) var originalVenueName: NSAttributedString!
class AdminUpdateVC: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate, @MainActor HasAppServices {
    // MARK: Lifecycle

    deinit {
        print(#function, "\(self)")
        adminUpdatePage = false
    }

    // MARK: Internal

    class HalfSizePresentationController: UIPresentationController {
        override var frameOfPresentedViewInContainerView: CGRect {
            CGRect(x: 0, y: 200, width: containerView!.bounds.width, height: containerView!.bounds.height)
        }
    }

    var appServices: AppServices!
    var movieSelected = false
    // var originalVenueName: NSAttributedString!

    var addMovie: String = ""
    var addMovieId: String = ""
    var addVenueId: String = ""
    var addVenue: String = ""
    var addScreeningID: String = ""
    var addScreeningDate: String = ""
    var addScreeningDateId: String = ""
    var addCategory: String = ""

    @IBOutlet var movieName: UITextField!
    @IBOutlet var screeningDate: UITextField!
    @IBOutlet var venueName: UITextField!
    @IBOutlet var ScreeningID: UITextField!
    @IBOutlet var category: UITextField!
    @IBOutlet var venueChanged: UIImageView!

    @IBOutlet var TrollErrorLabel: UILabel!

    let datePicker = UIDatePicker()

    @IBOutlet var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        injectAppServicesIfNeeded()
        adminUpdatePage = true
        adminPage = false

        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)

        // scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = UIColor.white
        configureScrollLayoutIfNeeded()
        buildCardLayoutIfNeeded()
        category.delegate = self
        category.placeholder = "Optional (Action/Drama/Crime/Romance/Troll)"
        movieName.isUserInteractionEnabled = false
        venueName.isUserInteractionEnabled = false
        movieName.textColor = .systemGray
        venueName.textColor = .systemGray
        styleSelectButtons()
        showDatePicker()

        NotificationCenter.default.addObserver(self, selector: #selector(AdminUpdateVC.refreshMovie), name: NSNotification.Name(rawValue: "movieSelected"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(AdminUpdateVC.refreshVenue), name: NSNotification.Name(rawValue: "newScreenVenueSelected"), object: nil)

        //  NotificationCenter.default.addObserver(self, selector: #selector(keyboardwillshow), name: UIResponder.keyboardWillShowNotification, object: nil)
        //  NotificationCenter.default.addObserver(self, selector: #selector(keyboardwillhide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillAppear(_: Bool) {
        topButtons = addTopNavigationButtons([
            (title: "Back", action: #selector(AdminUpdateVC.navigateBack)),
            (title: "Clear", action: #selector(AdminUpdateVC.clear)),
        ])

        ensureBottomButtons()
        applyPrefillFromSelectionContext()
        view.setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutTopNavigationButtons(topButtons, topOffset: 8)
        updateScrollInsetsForBottomActions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        AdminScreeningsDataManager.shared.screeningsForAdminUpdate = []
    }

    @objc func keyboardwillshow() {
        //     self.view.frame.origin.y = -150
    }

    @objc func keyboardwillhide() {
        //     self.view.frame.origin.y = 0
    }

    @objc func clear() {
        addMovie = ""
        addVenue = ""
        addScreeningID = ""
        addScreeningDate = ""
        addCategory = ""
        addScreeningDateId = ""

        movieName.text = ""
        venueName.text = ""
        ScreeningID.text = ""
        screeningDate.text = ""
        category.text = ""
    }

    @objc func refreshMovie() {
        applyPrefillFromSelectionContext()
    }

    @objc func refreshVenue() {
        addVenue = (LocationsDataManager.shared.selectedLocation?.title)!
        let changed = !originalVenueTitle.isEmpty && addVenue != originalVenueTitle
        venueName.text = changed ? "\(addVenue) (changed)" : addVenue
        venueName.textColor = .systemGray
        venueChanged.isHidden = true
    }

    @objc func navigateBack() {
        dismiss(animated: false, completion: nil)
    }

    @IBAction func selectMovies(_: UIButton) {
        adminUpdatePage = true
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
        // mapView = true
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
        datePicker.preferredDatePickerStyle = .compact

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

    func textFieldShouldEndEditing(_: UITextField) -> Bool {
        true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        var CategoryData = [String]()
        CategoryData = ["Action", "Drama", "Crime", "Romance", "Troll"]

        if textField == category {
            if !CategoryData.contains(category.text!), category.text != "" {
                presentAlert(withTitle: "Hello", message: "Invalid category")
                category.text = ""
                TrollErrorLabel.isHidden = false
            }

            // self.view.frame.origin.y = 0
            // category.resignFirstResponder()
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == category {
            // self.view.frame.origin.y = -100
            TrollErrorLabel.isHidden = true
        }
    }

    @objc func updateScreen() {
        let venue: NSString = venueName.text! as NSString
        let date: NSString = screeningDate.text! as NSString
        let ScreeningID_: NSString = ScreeningID.text! as NSString
        let category_: NSString = category.text! as NSString

        let testdata: [String: Any] = [
            "venue": venue as String,
            "venueId": addVenueId,
            "movieId": addMovieId,
            "date": date as String,
            "ScreeningDatesId": addScreeningDateId,
            "screenId": ScreeningID_ as String,
            "category": category_ as String,
        ]

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let screenResult = try await AdminDataManager.shared.updateScreen(body: testdata)
                if screenResult.screeningId.contains("Error") {
                    self.presentAlert(withTitle: "Error:", message: "Duplicate ScreeningId: \(ScreeningID_)")

                } else {
                    self.presentAlert(withTitle: "Info:", message: "Screen updated:, ScreeningId: \(screenResult.screeningId)")
                }
            } catch {
                NSLog("updateScreen: %@", error.localizedDescription)
            }
        }
    }

    @objc func deleteScreen() {
        let testdata: [String: Any] = [
            "ScreeningDatesId": addScreeningDateId as Any,
        ]

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                if try await AdminDataManager.shared.deleteScreen(body: testdata) {
                    self.presentAlert(withTitle: "Info:", message: "Screen deleted:, ScreeningDatesId: \(addScreeningDateId)")

                    addMovie = ""
                    addVenue = ""
                    addScreeningID = ""
                    addScreeningDate = ""
                    addCategory = ""
                    addScreeningDateId = ""

                    self.movieName.text = ""
                    self.venueName.text = ""
                    self.ScreeningID.text = ""
                    self.screeningDate.text = ""
                    self.category.text = ""
                }
            } catch {
                NSLog("deleteScreen: %@", error.localizedDescription)
                self.presentAlert(withTitle: "Error:", message: "Duplicate ScreeningDatesId: \(addScreeningDateId)")
            }
        }
    }

    func presentationController(forPresented presented: UIViewController, presenting _: UIViewController?, source _: UIViewController) -> UIPresentationController? {
        HalfSizePresentationController(presentedViewController: presented, presenting: presentingViewController)
    }

    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        .none
    }

    // MARK: Private

    private var topButtons: [UIButton] = []
    private var saveButton: UIButton?
    private var deleteButton: UIButton?
    private var saveButtonHeightConstraint: NSLayoutConstraint?
    private var deleteButtonHeightConstraint: NSLayoutConstraint?
    private var hasBottomButtonConstraints = false
    private var originalVenueTitle = ""
    private var didConfigureScrollLayout = false
    private var didBuildCardLayout = false
    private weak var movieSelectButton: UIButton?
    private weak var venueSelectButton: UIButton?

    private func ensureBottomButtons() {
        if saveButton == nil {
            let button = UIButton(type: .system)
            button.setTitle("Save", for: .normal)
            stylePrimaryButton(button, fontSize: 14)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(AdminUpdateVC.updateScreen), for: .touchUpInside)
            view.addSubview(button)
            saveButtonHeightConstraint = button.heightAnchor.constraint(equalToConstant: 38)
            saveButton = button
        }

        if deleteButton == nil {
            let button = UIButton(type: .system)
            button.setTitle("Delete", for: .normal)
            styleDestructiveButton(button, fontSize: 14)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(AdminUpdateVC.deleteScreen), for: .touchUpInside)
            view.addSubview(button)
            deleteButtonHeightConstraint = button.heightAnchor.constraint(equalToConstant: 38)
            deleteButton = button
        }

        if let saveButton, let deleteButton, !hasBottomButtonConstraints {
            NSLayoutConstraint.activate([
                saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                saveButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -5),
                deleteButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 5),
                deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
                deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
                saveButtonHeightConstraint ?? saveButton.heightAnchor.constraint(equalToConstant: 38),
                deleteButtonHeightConstraint ?? deleteButton.heightAnchor.constraint(equalToConstant: 38),
            ])
            hasBottomButtonConstraints = true
        }
    }

    private func updateScrollInsetsForBottomActions() {
        let saveHeight = saveButtonHeightConstraint?.constant ?? 38
        let deleteHeight = deleteButtonHeightConstraint?.constant ?? 38
        let reserve = max(saveHeight, deleteHeight) + view.safeAreaInsets.bottom + 20
        scrollView.contentInset.bottom = reserve
        scrollView.verticalScrollIndicatorInsets.bottom = reserve
    }

    private func applyPrefillFromSelectionContext() {
        let selected = AdminDataManager.shared.selectedScreen

        movieName.text = selected?.movie ?? addMovie
        venueName.text = selected?.venue ?? addVenue
        ScreeningID.text = selected?.screeningId ?? addScreeningID
        screeningDate.text = selected?.date ?? addScreeningDate
        category.text = selected?.category ?? addCategory

        if let selected {
            addMovie = selected.movie
            addVenue = selected.venue
            addScreeningID = selected.screeningId
            addScreeningDate = selected.date
            addScreeningDateId = selected.screeningDatesId
            addMovieId = selected.movieId
            addVenueId = selected.venueId
            addCategory = selected.category
        }

        let originalVenue = selected?.venue ?? addVenue
        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        originalVenueName = NSMutableAttributedString(string: originalVenue, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))
        originalVenueTitle = originalVenue
        venueChanged.isHidden = true
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

    private func styleDestructiveButton(_ button: UIButton, fontSize: CGFloat) {
        button.backgroundColor = UIColor(red: 215 / 255, green: 0, blue: 21 / 255, alpha: 1)
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

        let allButtons = collectButtons(in: scrollView)
            .filter { $0.currentTitle == "Select" }
            .sorted { $0.frame.minY < $1.frame.minY }
        movieSelectButton = allButtons.first
        venueSelectButton = allButtons.dropFirst().first

        guard let movieSelectButton, let venueSelectButton else { return }

        for item in [movieName, venueName, screeningDate, ScreeningID, category, movieSelectButton, venueSelectButton] {
            item!.translatesAutoresizingMaskIntoConstraints = false
            item!.removeFromSuperview()
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

    /// Helper function inserted by Swift 4.2 migrator.
    private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
        input.rawValue
    }

    /// Helper function inserted by Swift 4.2 migrator.
    private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
        guard let input else { return nil }
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
    }
}
