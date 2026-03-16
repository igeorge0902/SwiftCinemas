//
//  AttendeesVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 25/09/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import Contacts
import Foundation
import UIKit

var attendeesArray: [NSDictionary] = .init()
var attendeesIndexDictionary = [IndexPath: NSDictionary]()
var attendeesDictionary = [Int: NSDictionary]()
class AttendeesVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var movieId: Int?

    deinit {
        print(#function, "\(self)")
    }

    var tableView: UITableView?
    var contacts = [CNContact]()
    var indexOfLetters = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView?.delegate = self
        tableView?.dataSource = self

        requestForAccess { _ in }

        let index = "a b c d e f g h i j k l m n o p q r s t u v w x y z #"
        indexOfLetters = index.components(separatedBy: " ")
    }

    override func viewWillAppear(_: Bool) {
        let frame = CGRect(x: 0, y: 100, width: view.frame.width, height: view.frame.height / 2.2)
        tableView = UITableView(frame: frame)
        tableView?.dataSource = self
        tableView?.delegate = self

        view.addSubview(tableView!)

        let btnData = UIButton(frame: CGRect(x: view.frame.width / 2, y: 25, width: view.frame.width / 2, height: 20))
        btnData.backgroundColor = UIColor.black
        btnData.showsTouchWhenHighlighted = true
        btnData.setTitle("Clear", for: UIControl.State.normal)
        btnData.addTarget(self, action: #selector(AttendeesVC.clearAttendees), for: UIControl.Event.touchUpInside)

        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.showsTouchWhenHighlighted = true
        btnNav.setTitle("Back", for: UIControl.State.normal)
        btnNav.addTarget(self, action: #selector(AttendeesVC.navigateBack), for: UIControl.Event.touchUpInside)

        view.addSubview(btnData)
        view.addSubview(btnNav)

        contactS()

        // TODO: add UITextView to display select attendees
    }

    @objc func clearAttendees() {
        attendeesDictionary.removeAll()
        attendeesIndexDictionary.removeAll()

        tableView?.reloadData()
    }

    @objc func navigateBack() {
        dismiss(animated: true, completion: nil)
    }

    func showMessage(_ message: String) {
        // Create an Alert
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)

        // Add an OK button to dismiss
        let dismissAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { _ in
        }
        alertController.addAction(dismissAction)

        // Show the Alert
        present(alertController, animated: true, completion: nil)
    }

    func requestForAccess(_ completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        // Get authorization
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)

        // Find out what access level we have currently
        switch authorizationStatus {
        case .authorized:
            completionHandler(true)

        case .denied, .notDetermined:
            CNContactStore().requestAccess(for: CNEntityType.contacts, completionHandler: { access, accessError in
                if access {
                    completionHandler(access)
                } else {
                    if authorizationStatus == CNAuthorizationStatus.denied {
                        DispatchQueue.main.async { () in
                            let message = "\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings."
                            self.showMessage(message)
                        }
                    }
                }
            })

        default:
            completionHandler(false)
        }
    }

    func contactS() {
        let contactStore = CNContactStore()
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataAvailableKey,
            CNContactThumbnailImageDataKey,
            CNContactImageDataKey,
        ] as [Any]

        // let keys = [CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName)]
        let request = CNContactFetchRequest(keysToFetch: keysToFetch as! [CNKeyDescriptor])

        do {
            try contactStore.enumerateContacts(with: request) {
                contact, _ in
                // Array containing all unified contacts from everywhere
                self.contacts.append(contact)
            }
        } catch {
            print("unable to fetch contacts")
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func numberOfSections(in _: UITableView) -> Int {
        contacts.count
    }

    func sectionIndexTitles(for _: UITableView) -> [String]? {
        indexOfLetters
    }

    func tableView(_: UITableView, sectionForSectionIndexTitle title: String, at _: Int) -> Int {
        let temp = indexOfLetters as NSArray
        return temp.index(of: title)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "CELL") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "CELL")
        }

        let data = contacts[indexPath.section]

        cell?.textLabel?.text = data.familyName + " " + data.givenName

        if attendeesIndexDictionary.count > 0 {
            if attendeesIndexDictionary.keys.contains(indexPath) {
                for (key, value) in attendeesIndexDictionary[indexPath]! {
                    print("Value: \(value) for key: \(key)")

                    if (key as! NSString) as String == "email" {
                        cell?.detailTextLabel?.text = (value as! NSString) as String
                    }
                }
            }

        } else {
            cell?.detailTextLabel?.text = ""
        }

        if data.isKeyAvailable(CNContactImageDataKey) {
            if data.imageDataAvailable {
                cell?.imageView?.image = UIImage(data: data.imageData!)
            }
        }

        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentContact = contacts[indexPath.section]
        let cell = tableView.cellForRow(at: indexPath)

        // Create the AlertController
        let actionSheetController = UIAlertController(title: "Action Sheet", message: "Choose an option!", preferredStyle: .actionSheet)

        // Create and add the Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Just dismiss the action sheet
        }

        actionSheetController.addAction(cancelAction)

        var homeEmailAddress: String!
        for emailAddress in currentContact.emailAddresses {
            homeEmailAddress = emailAddress.value as String

            // Create and add first option action
            let takePictureAction = UIAlertAction(title: homeEmailAddress, style: .default) { _ in

                let attendees = ["email": homeEmailAddress, "displayName": currentContact.givenName, "responseStatus": "needsAction"] as [String: Any]

                attendeesIndexDictionary.updateValue(attendees as NSDictionary, forKey: indexPath)
                attendeesDictionary.updateValue(attendees as NSDictionary, forKey: indexPath.row)

                for attendee in attendeesDictionary.values {
                    attendeesArray.append(attendee as NSDictionary)
                }

                cell?.detailTextLabel?.text = homeEmailAddress
            }

            actionSheetController.addAction(takePictureAction)
        }

        let removeAction = UIAlertAction(title: "Remove", style: .default) { _ in

            attendeesIndexDictionary.removeValue(forKey: indexPath)
            attendeesDictionary.removeValue(forKey: indexPath.row)
            cell?.detailTextLabel?.text = ""
        }

        actionSheetController.addAction(removeAction)

        // Present the AlertController
        actionSheetController.popoverPresentationController?.sourceView = view
        present(actionSheetController, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isHighlighted = true
    }

    func tableView(_: UITableView, didUnhighlightRowAt _: IndexPath) {}
}
