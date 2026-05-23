// PopOverDates.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import UIKit

class PopOverDates: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    // MARK: Lifecycle

    deinit {
        print(#function, "\(self)")
    }

    // MARK: Internal

    lazy var pickerView: UIPickerView = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        pickerView.frame = view.bounds.insetBy(dx: 0, dy: 8)
        pickerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.showsSelectionIndicator = true

        view.addSubview(pickerView)
        pickerView.isHidden = false

        if !DatesDataManager.shared.availableDates.isEmpty {
            pickerView.selectRow(1, inComponent: 0, animated: false)
            pickerView(pickerView, didSelectRow: 1, inComponent: 0)
        }
    }

    override func viewWillAppear(_: Bool) {}

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfComponents(in _: UIPickerView) -> Int {
        1
    }

    func pickerView(_: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        DatesDataManager.shared.availableDates.count + 1
    }

    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent _: Int) -> String? {
        if row == 0 {
            return "Select a date"
        }
        let titleData = DatesDataManager.shared.availableDates[row - 1].date
        let myDateString_ = titleData.split(separator: ".")
        let date_ = Date.formatDate(dateString: String(myDateString_.first!))
        return String.formatDate(date: date_)
    }

    func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent _: Int) {
        guard !DatesDataManager.shared.availableDates.isEmpty else { return }

        if row == 0 {
            pickerView.selectRow(1, inComponent: 0, animated: true)
            return
        } else {
            guard (row - 1) < DatesDataManager.shared.availableDates.count else { return }
            let selectedDate = DatesDataManager.shared.availableDates[row - 1]
            let selectedDateText = selectedDate.date
            DatesDataManager.shared.selectedScreeningDateText = selectedDateText
            DatesDataManager.shared.selectedScreeningDateId = selectedDate.screeningDateId
        }
    }
}
