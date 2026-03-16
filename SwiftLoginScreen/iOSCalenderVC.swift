//
//  iOSCalenderVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 25/09/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import EventKit
import Foundation
import UIKit

class iOSCalendarVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate {
    deinit {
        attendeesArray.removeAll()
        attendeesDictionary.removeAll()
        attendeesIndexDictionary.removeAll()
        print(#function, "\(self)")
        print(#function, "\(self)")
    }

    var tableView: UITableView?
    var selectCalendar: NSIndexPath?
    lazy var eventStore = EKEventStore()
    var event: EKEvent?
    var calendars: [EKCalendar]?
    var calendars_: [EKCalendar]?

    lazy var datE = Date.formatDate(dateString: String(myDateString!.first!))

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView?.delegate = self
        tableView?.dataSource = self

        calendars = eventStore.calendars(for: EKEntityType.event) as [EKCalendar]
        calendars_ = calendars?.filter { !$0.isSubscribed }
    }

    override func viewWillAppear(_: Bool) {
        let frame = CGRect(x: 0, y: 60, width: view.frame.width, height: view.frame.height - 90)
        tableView = UITableView(frame: frame)
        tableView?.dataSource = self
        tableView?.delegate = self

        view.addSubview(tableView!)

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.setTitle("Back", for: UIControl.State.normal)
        btnNav.showsTouchWhenHighlighted = true
        btnNav.addTarget(self, action: #selector(iOSCalendarVC.navigateBack), for: UIControl.Event.touchUpInside)

        let btnAttendees = UIButton(frame: CGRect(x: view.frame.width / 2, y: 25, width: view.frame.width / 2, height: 20))
        btnAttendees.backgroundColor = UIColor.black
        btnAttendees.setTitle("Save", for: UIControl.State())
        btnAttendees.showsTouchWhenHighlighted = true
        btnAttendees.addTarget(self, action: #selector(iOSCalendarVC.calendar), for: UIControl.Event.touchUpInside)

        view.addSubview(btnAttendees)
        view.addSubview(btnNav)
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
    }

    @objc func navigateBack() {
        dismiss(animated: true, completion: nil)
    }

    @objc func calendar( /* _ sender: UIButton */ ) {
        event = EKEvent(eventStore: eventStore)

        event?.title = SelectMovieName!
        event?.startDate = datE
        event?.endDate = datE.addingTimeInterval(7200)
        event?.notes = "This is a note of creating event"
        event?.calendar = eventStore.defaultCalendarForNewEvents
        event?.addAlarm(EKAlarm(relativeOffset: 60.0))
        event?.location = SelectVenueForMovie
        event?.calendar = (calendars_?[(selectCalendar?.row)!])!

        do {
            try eventStore.save(event!, span: .thisEvent)

        } catch let specError as NSError {
            print("A specific error occurred: \(specError)")

        } catch {
            print("An error occurred")
        }
        showAlert(SelectMovieName!, message: "Event added to calendar: ".appending(String.formatDate(date: datE)))
    }

    // Helper for showing an alert
    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        if calendars_!.count > 0 {
            return calendars_!.count
        }
        return calendars!.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "CELL") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "CELL")
        }

        cell?.textLabel?.text = calendars_![indexPath.row].title

        return cell!
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectCalendar = indexPath as NSIndexPath?
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isHighlighted = true
    }

    func tableView(_: UITableView, didUnhighlightRowAt _: IndexPath) {}

    @objc func addAttendees() {
        let storyboard = UIStoryboard(name: "Storyboard", bundle: nil)
        let pvc = storyboard.instantiateViewController(withIdentifier: "Attendees")

        pvc.modalPresentationStyle = UIModalPresentationStyle.custom
        pvc.transitioningDelegate = self
        // pvc.view.backgroundColor = UIColor.groupTableViewBackgroundColor()

        present(pvc, animated: true, completion: nil)
    }

    func presentationController(forPresented presented: UIViewController, presenting _: UIViewController?, source _: UIViewController) -> UIPresentationController? {
        HalfSizePresentationController(presentedViewController: presented, presenting: presentingViewController)
    }

    class HalfSizePresentationController: UIPresentationController {
        override var frameOfPresentedViewInContainerView: CGRect {
            CGRect(x: 0, y: 200, width: containerView!.bounds.width, height: containerView!.bounds.height)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
