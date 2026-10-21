// PopOverDates.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import UIKit

class PopOverDates: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    private lazy var viewModel = ScreeningDateSelectionViewModel(dates: .shared)
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

        if viewModel.hasDates {
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
        viewModel.rowCount
    }

    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent _: Int) -> String? {
        viewModel.title(at: row)
    }

    func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent _: Int) {
        guard viewModel.hasDates else { return }

        if row == 0 {
            pickerView.selectRow(1, inComponent: 0, animated: true)
            return
        } else {
            guard row > 0, row < viewModel.rowCount else { return }
            viewModel.selectDate(atPickerRow: row)
        }
    }
}
