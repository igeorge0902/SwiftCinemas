//
//  PopOverDates.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 09/09/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//
//

import CoreData
import SwiftyJSON
import UIKit

var SelectScreeningDateText: String?
var myDateString: [String.SubSequence]?
var screeningDateId: String?
var SelectMovieName: String?
var SelectMoviePicture: String?
var SelectVenueForMovie: String?
var SelectVenueName: String?
var numberOfRows: [String] = .init()
class PopOverDates: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    deinit {
        print(#function, "\(self)")

        /*
         var filteredAttendees = SeatsData_.filter({
             $0.seatRow == String(0)
         })
         */

        for i in 0 ..< SeatsData_.count {
            if !numberOfRows.contains(SeatsData_[i].seatRow) {
                numberOfRows.append(SeatsData_[i].seatRow)
            }
        }
    }

    lazy var pickerView: UIPickerView = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        pickerView.frame = CGRect(x: 0, y: -(view.frame.height / 34), width: view.frame.width, height: view.frame.height / 4)
        // pickerView.sizeToFit()
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.showsSelectionIndicator = true

        view.addSubview(pickerView)
        pickerView.isHidden = false
    }

    override func viewWillAppear(_: Bool) {}

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
    }

    func numberOfComponents(in _: UIPickerView) -> Int {
        1
    }

    func pickerView(_: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        ScreeningDates.count + 1
    }

    func pickerView(_: UIPickerView, attributedTitleForRow row: Int, forComponent _: Int) -> NSAttributedString? {
        let titleData = "Available dates"
        var myTitle: NSAttributedString!
        let myTextAttribute = [NSAttributedString.Key.font: UIFont(name: "CourierNewPS-BoldMT", size: 14.0)!]

        if row > 0 {
            let myDateString_ = titleData
            let date_ = Date.formatDate(dateString: String(myDateString_.first!))

            myTitle = NSMutableAttributedString(string: String.formatDate(date: date_), attributes: myTextAttribute)

        } else {
            myTitle = NSMutableAttributedString(string: titleData, attributes: myTextAttribute)
        }

        return myTitle
    }

    func pickerView(_: UIPickerView, viewForRow row: Int, forComponent _: Int, reusing view: UIView?) -> UIView {
        var pickerLabel = view as! UILabel?
        if view == nil { // if no label there yet
            pickerLabel = UILabel()
            // color the label's background
            // let hue = CGFloat(row)/CGFloat(ScreeningDates.count)
            // pickerLabel?.backgroundColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        }

        var myTitle: NSAttributedString!

        if row > 0 {
            let titleData = ScreeningDates[row - 1].screeningDate
            let myDateString_ = titleData!.split(separator: ".")
            let date_ = Date.formatDate(dateString: String(myDateString_.first!))

            myTitle = NSAttributedString(string: String.formatDate(date: date_), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "CourierNewPS-BoldMT", size: 16.0)!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))

            pickerLabel!.attributedText = myTitle
            pickerLabel!.textAlignment = .center

        } else {
            let titleData = "Select date"
            myTitle = NSAttributedString(string: titleData, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "CourierNewPS-BoldMT", size: 14.0)!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]))

            pickerLabel!.attributedText = myTitle
            pickerLabel!.textAlignment = .left
        }

        return pickerLabel!
    }

    func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent _: Int) {
        if row == 0 {
            pickerView.selectRow(1, inComponent: 0, animated: true)
            pickerView(pickerView, didSelectRow: 1, inComponent: 0)
        } else {
            SelectScreeningDateText = ScreeningDates[row - 1].screeningDate
            if ScreeningDates[row - 1].screeningDatesId != 0 {
                //    SeatsData.addData(ScreeningDates[row].screeningDatesId)
                screeningDateId = String(ScreeningDates[row - 1].screeningDatesId)
                myDateString = SelectScreeningDateText!.split(separator: ".")
            }
        }
    }

    func pickerView(_: UIPickerView, widthForComponent _: Int) -> CGFloat {
        view.frame.width
    }

    func pickerView(_: UIPickerView, rowHeightForComponent _: Int) -> CGFloat {
        view.frame.height / 3
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    input.rawValue
}
