//
//  AdminVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2020. 09. 30..
//  Copyright © 2020. George Gaspar. All rights reserved.
//

import Foundation
import SwiftyJSON
import UIKit

// data modell for adding new screen
var ScreenData_: [ScreenData] = .init()

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
@available(iOS 9.0, *)
class AdminVC: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        adminPage = true
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)

        // scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.white
        view.addSubview(scrollView)
        category.delegate = self
        ScreeningID.delegate = self
        showDatePicker()

        NotificationCenter.default.addObserver(self, selector: #selector(AdminVC.refresh), name: NSNotification.Name(rawValue: "newScreenMovieSelected"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(AdminVC.refreshVenue), name: NSNotification.Name(rawValue: "newScreenVenueSelected"), object: nil)
    }

    override func viewWillAppear(_: Bool) {
        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.setTitle("Back", for: UIControl.State())
        btnNav.showsTouchWhenHighlighted = true
        btnNav.addTarget(self, action: #selector(AdminVC.navigateBack), for: UIControl.Event.touchUpInside)

        let btnUpdate = UIButton(frame: CGRect(x: view.frame.width / 2, y: 25, width: view.frame.width / 2, height: 20))
        btnUpdate.backgroundColor = UIColor.black
        btnUpdate.setTitle("Update", for: UIControl.State())
        btnUpdate.showsTouchWhenHighlighted = true
        btnUpdate.addTarget(self, action: #selector(AdminVC.adminUpdate), for: UIControl.Event.touchUpInside)

        let btnAdd = UIButton(frame: CGRect(x: 0, y: view.frame.height * 0.9, width: view.frame.width / 2, height: 20))
        btnAdd.backgroundColor = UIColor.black
        btnAdd.setTitle("Save", for: UIControl.State())
        btnAdd.showsTouchWhenHighlighted = true
        btnAdd.addTarget(self, action: #selector(AdminVC.addNewScreen), for: UIControl.Event.touchUpInside)

        view.addSubview(btnAdd)
        view.addSubview(btnUpdate)
        view.addSubview(btnNav)
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

        let testdata: [String: String] = [
            "venue": venue as String,
            "movie": movie as String,
            "date": date as String,
            "nrOfRows": nrOfRows_ as String,
            "nrOfSeatsInRow": nrOfSeatsInRow_ as String,
            "ScreeningId": ScreeningID_ as String,
            "category": category_ as String,
        ]

        let test: Data = try! JSONSerialization.data(withJSONObject: testdata, options: [])

        let data = NSString(data: test, encoding: String.Encoding.utf8.rawValue)! as String
        let post: NSString = "newScreen=\(data)" as NSString
        // let postData: Data = post.data(using: String.Encoding.utf8.rawValue)!

        let postData: Data = post.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: true)!

        var errorOnLogin: GeneralRequestManager?

        errorOnLogin = GeneralRequestManager(url: serverURL + "/mbooks-1/rest/book/admin/addscreen", errors: "", method: "POST", headers: nil, queryParameters: nil, bodyParameters: testdata, isCacheable: nil, contentType: contentType_.json.rawValue, bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            if let dataBlock = json.object as? NSDictionary {
                ScreenData_.append(ScreenData(add: dataBlock))
            }
            if ScreenData_[0].ScreeningId.contains("Error") {
                self.presentAlert(withTitle: "Error:", message: "Duplicate ScreeningId: \(ScreeningID_)")

            } else {
                self.presentAlert(withTitle: "Info:", message: "New screen added:, Screen: \(ScreenData_[0].movie!)")
            }
        }

        ScreenData_.removeAll()
    }

    @IBAction func selectMovies(_: UIButton) {
        adminPage = true
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
}
