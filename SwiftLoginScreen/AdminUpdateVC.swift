//
//  AdminUpdateVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2020. 09. 30..
//  Copyright © 2020. George Gaspar. All rights reserved.
//

import Foundation
import SwiftyJSON
import UIKit

var originalVenueName: NSAttributedString!
@available(iOS 9.0, *)
class AdminUpdateVC: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate, HasAppServices {
    var appServices: AppServices!
    deinit {
        print(#function, "\(self)")
        adminUpdatePage = false
        ScreenData_2.removeAll()
    }

    var movieSelected = false
    // var originalVenueName: NSAttributedString!

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
        view.addSubview(scrollView)
        category.delegate = self
        showDatePicker()

        NotificationCenter.default.addObserver(self, selector: #selector(AdminUpdateVC.refresh), name: NSNotification.Name(rawValue: "movieSelected"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(AdminUpdateVC.refreshVenue), name: NSNotification.Name(rawValue: "newScreenVenueSelected"), object: nil)

        //  NotificationCenter.default.addObserver(self, selector: #selector(keyboardwillshow), name: UIResponder.keyboardWillShowNotification, object: nil)
        //  NotificationCenter.default.addObserver(self, selector: #selector(keyboardwillhide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillAppear(_: Bool) {
        //   adminUpdatePage = true
        //   adminPage = false

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.setTitle("Back", for: UIControl.State())
        btnNav.showsTouchWhenHighlighted = true
        btnNav.addTarget(self, action: #selector(AdminUpdateVC.navigateBack), for: UIControl.Event.touchUpInside)

        let btnAdd = UIButton(frame: CGRect(x: 0, y: view.frame.height * 0.9, width: view.frame.width / 2, height: 20))
        btnAdd.backgroundColor = UIColor.black
        btnAdd.setTitle("Save", for: UIControl.State())
        btnAdd.showsTouchWhenHighlighted = true
        btnAdd.addTarget(self, action: #selector(AdminUpdateVC.updateScreen), for: UIControl.Event.touchUpInside)

        let btnDel = UIButton(frame: CGRect(x: view.frame.width / 2, y: view.frame.height * 0.9, width: view.frame.width / 2, height: 20))
        btnDel.backgroundColor = UIColor.black
        btnDel.setTitle("Delete", for: UIControl.State())
        btnDel.showsTouchWhenHighlighted = true
        btnDel.addTarget(self, action: #selector(AdminUpdateVC.deleteScreen), for: UIControl.Event.touchUpInside)

        let btnClear = UIButton(frame: CGRect(x: view.frame.width / 2, y: 25, width: view.frame.width / 2, height: 20))
        btnClear.backgroundColor = UIColor.black
        btnClear.setTitle("Clear", for: UIControl.State())
        btnClear.showsTouchWhenHighlighted = true
        btnClear.addTarget(self, action: #selector(AdminUpdateVC.clear), for: UIControl.Event.touchUpInside)

        view.addSubview(btnClear)
        view.addSubview(btnAdd)
        view.addSubview(btnDel)
        view.addSubview(btnNav)
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

    @objc func refresh() {
        movieName.text = addMovie
        venueName.text = addVenue
        ScreeningID.text = addScreeningID
        screeningDate.text = addScreeningDate
        category.text = addCategory

        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        originalVenueName = NSMutableAttributedString(string: addVenue, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))
    }

    @objc func refreshVenue() {
        let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
        let detailText = NSMutableAttributedString(string: addVenue, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

        venueName.attributedText = detailText

        if originalVenueName == detailText {
            venueName.text = addVenue
            venueChanged.isHidden = true
        } else {
            venueChanged.isHidden = false
        }
    }

    @objc func navigateBack() {
        dismiss(animated: false, completion: nil)
    }

    @IBAction func selectMovies(_: UIButton) {
        adminUpdatePage = true
        DispatchQueue.main.async {
            let popOver = MoviesVC()
            popOver.modalPresentationStyle = UIModalPresentationStyle.popover
            popOver.preferredContentSize = CGSize(width: self.view.frame.width * 0.90, height: self.view.frame.height / 2)

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
            popOver.preferredContentSize = CGSize(width: self.view.frame.width * 0.90, height: self.view.frame.height / 2)

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
            "venueId": addVenueId as String,
            "movieId": addMovieId as String,
            "date": date as String,
            "ScreeningDatesId": addScreeningDateId as String,
            "screenId": ScreeningID_ as String,
            "category": category_ as String,
        ]

        ScreenData_.removeAll()

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let responseData = try await self.appServices.mbooks.adminUpdateScreen(body: testdata)
                let json = try JSON(data: responseData)
                if let dataBlock = json.object as? NSDictionary {
                    ScreenData_.append(ScreenData(add: dataBlock))
                }
                if ScreenData_[0].ScreeningId.contains("Error") {
                    self.presentAlert(withTitle: "Error:", message: "Duplicate ScreeningId: \(ScreeningID_)")

                } else {
                    self.presentAlert(withTitle: "Info:", message: "Screen updated:, ScreeningId: \(ScreenData_[0].ScreeningId!)")
                }
            } catch {
                NSLog("updateScreen: %@", error.localizedDescription)
            }
        }
    }

    @objc func deleteScreen() {
        let testdata: [String: Any] = [
            "ScreeningDatesId": addScreeningDateId as String,
        ]

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let responseData = try await self.appServices.mbooks.adminDeleteScreen(body: testdata)
                let json = try JSON(data: responseData)
                if json["screeningDatesId"].string != nil {
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

    class HalfSizePresentationController: UIPresentationController {
        override var frameOfPresentedViewInContainerView: CGRect {
            CGRect(x: 0, y: 200, width: containerView!.bounds.width, height: containerView!.bounds.height)
        }
    }

    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        .none
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
}
