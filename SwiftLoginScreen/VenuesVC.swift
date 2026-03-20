//
//  VenuesVC.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 24/06/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import MapKit
import SwiftyJSON
import UIKit

class VenuesVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var movieId: Int!
    var movieName: String!
    var selectLarge_picture: String!
    var selectDetails: String!
    var selectVenues_picture: String!
    var imdb: String!

    var mapView: MKMapView? = nil
    var handleMapSearchDelegate: HandleMapSearch? = nil

    deinit {
        adminPage = false
        print(#function, "\(self)")
        PlacesData2_.removeAll()
        PlacesData_.removeAll()
    }

    // local
    var TableData: [datastruct] = .init()
    var LocationData: [PlacesData] = .init()

    struct datastruct: Equatable {
        var venuesId: Int!
        var name: String!
        var address: String!
        var venues_picture: String!
        var screen_screenId: String!
        var locationId: Int!
        var image: UIImage?

        init(add: NSDictionary) {
            venuesId = (add["venuesId"] as! Int)
            name = (add["name"] as! String)
            address = (add["address"] as! String)
            venues_picture = (add["venues_picture"] as! String)
            screen_screenId = (add["screen_screenId"] as! String)
            locationId = (add["locationId"] as! Int)
        }

        static func == (lhs: datastruct, rhs: datastruct) -> Bool {
            lhs.name == rhs.name
        }
    }

    var tableView: UITableView!
    var detailsView: UIView!
    var detailsLabel: UILabel!

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "goto_venues_details" {
            let nextSegue = segue.destination as? VenuesDetailsVC
            if let indexPath = tableView!.indexPathForSelectedRow {
                let data = TableData[indexPath.row]
                // let data_ = LocationData[indexPath.row]

                // TODO: remove venues data, and use location data, instead
                nextSegue?.selectVenues_picture = data.venues_picture
                nextSegue?.selectVenueId = data.venuesId
                nextSegue?.venueName = data.name
                nextSegue?.selectAddress = data.address
                nextSegue?.screen_screenId = data.screen_screenId
                nextSegue?.locationId = data.locationId

                nextSegue?.movieId = movieId
                nextSegue?.movieName = movieName
                nextSegue?.movieDetails = selectDetails
                nextSegue?.selectLarge_picture = selectLarge_picture
                nextSegue?.iMDB = imdb

                /*
                 nextSegue?.locationId = data_.locationId
                 nextSegue?.selectVenues_picture = data_.thumbnail
                 nextSegue?.venueName = data_.title
                 */
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupDetailsView()

        NotificationCenter.default.addObserver(self, selector: #selector(navigateBack), name: NSNotification.Name(rawValue: "navigateBack"), object: nil)
    }

    override func viewWillAppear(_: Bool) {
        let btnNav = UIButton(frame: CGRect(x: 0, y: 25, width: view.frame.width / 2, height: 20))
        btnNav.backgroundColor = UIColor.black
        btnNav.setTitle("Back", for: UIControl.State())
        btnNav.showsTouchWhenHighlighted = true
        btnNav.addTarget(self, action: #selector(VenuesVC.navigateBack), for: UIControl.Event.touchUpInside)

        view.addSubview(btnNav)

        if adminPage {
            addLocation()
        } else if mapViewPage {
            addLocation()
        } else {
            addData()
        }
    }

    private func setupTableView() {
        let tableHeight = view.frame.height / 2
        tableView = UITableView(frame: CGRect(x: 0, y: 100, width: view.frame.width, height: tableHeight))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = true
        tableView.clipsToBounds = true
        view.addSubview(tableView)
    }

    private func setupDetailsView() {
        let detailsFrame = CGRect(x: 0, y: view.frame.height / 2, width: view.frame.width, height: view.frame.height / 2)
        detailsView = UIView(frame: detailsFrame)
        detailsView.backgroundColor = UIColor.lightGray

        // Add a label inside detailsView to show selected venue details
        detailsLabel = UILabel(frame: CGRect(x: 20, y: 20, width: detailsView.frame.width - 40, height: 100))
        detailsLabel.numberOfLines = 0
        detailsLabel.textAlignment = .center
        detailsLabel.font = UIFont.systemFont(ofSize: 16)
        detailsLabel.text = "Select a venue to see details here."

        detailsView.addSubview(detailsLabel)
        view.addSubview(detailsView)
    }

    @objc func navigateBack() {
        dismiss(animated: false, completion: nil)
    }

    @objc func navigateToVenue(button _: UIButton, event _: UIEvent) {
        performSegue(withIdentifier: "goto_venues_details", sender: self)
    }

    func addData() {
        let myString = String(movieId)
        var errorOnLogin: GeneralRequestManager?

        errorOnLogin = GeneralRequestManager(url: URLManager.mbooks("/venue/" + myString), errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: "1", contentType: "", bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            if let list = json["venues"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        self.TableData.append(datastruct(add: dataBlock))
                    }
                }
            }

            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
    }

    func addLocalData() {
        let myString = String(movieId)
        var errorOnLogin: GeneralRequestManager?

        errorOnLogin = GeneralRequestManager(url: URLManager.mbooks("/venue/" + myString), errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: "1", contentType: "", bodyToPost: nil)

        errorOnLogin?.getResponse { [self]
            (json: JSON, _: NSError?) in

                if let list = json["locations"].object as? NSArray {
                    for i in 0 ..< list.count {
                        if let dataBlock = list[i] as? NSDictionary {
                            if let artwork = PlacesData.fromJSON(dataBlock) {
                                LocationData.append(artwork)
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.tableView?.reloadData()
                }
        }
    }

    func addLocation() {
        PlacesData_.removeAll()

        var errorOnLogin: GeneralRequestManager?

        errorOnLogin = GeneralRequestManager(url: URLManager.mbooks("/locations"), errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: "", contentType: "", bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            //   PlacesData_.removeAll()

            if let list = json["locations"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        if let location = PlacesData.fromJSON(dataBlock) {
                            PlacesData_.append(location)
                            if mapViewPage == true {
                                PlacesData2_.append(location)
                            }
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "CELL") as UITableViewCell?

        if cell == nil {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "CELL")
        }

        if adminPage || mapViewPage {
            PlacesData_.sort { ($0.title ?? "") < ($1.title ?? "") }
            PlacesData2_.sort { ($0.title ?? "") < ($1.title ?? "") }

            var data_: PlacesData? = if mapViewPage {
                PlacesData2_[indexPath.row]
            } else {
                PlacesData_[indexPath.row]
            }

            var s = ""
            if originalVenueName != nil {
                s = (originalVenueName.string as NSString) as String
            }

            if data_?.title! == s as String {
                let range = (s as NSString).range(of: s as String)
                let mutableAttributedString = NSMutableAttributedString(string: s as String)
                mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: range)
                cell!.textLabel?.attributedText = mutableAttributedString
                cell!.detailTextLabel?.text = data_?.address

            } else {
                let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
                let detailText = NSMutableAttributedString(string: (data_?.title!)!, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

                cell!.textLabel?.attributedText = detailText
                //   cell!.detailTextLabel?.text = data_?.address
            }

        } else {
            let btn = UIButton(type: UIButton.ButtonType.custom) as UIButton
            btn.frame = CGRect(x: view.frame.width * 0.9, y: 15, width: 20, height: 30)
            btn.addTarget(self, action: #selector(VenuesVC.navigateToVenue), for: .touchUpInside)
            btn.tag = indexPath.row
            btn.setImage(UIImage(named: "window-7.png"), for: .normal)
            cell?.contentView.addSubview(btn)

            // TableData.sort { ($0.title ?? "") < ($1.title ?? "")}
            let data = TableData[indexPath.row]

            let myTextAttribute = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Courier New", size: 13.0)!]
            let detailText = NSMutableAttributedString(string: data.name!, attributes: convertToOptionalNSAttributedStringKeyDictionary(myTextAttribute))

            cell!.textLabel?.attributedText = detailText
            // cell!.detailTextLabel?.text = data.address!

            let urlString = URLManager.image(data.venues_picture!)

            var loadPictures: GeneralRequestManager?
            loadPictures = GeneralRequestManager(url: urlString, errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: "1", contentType: "", bodyToPost: nil)

            loadPictures?.getData_ {
                (data: Data, _: NSError?) in
                let image = UIImage(data: data)
                cell!.imageView?.image = image
                if let updatedCell = tableView.cellForRow(at: indexPath) {
                    updatedCell.imageView?.image = image
                    updatedCell.setNeedsLayout() // Force the cell to update
                }
            }
        }

        return cell!
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        if adminPage {
            PlacesData_.count

        } else if mapViewPage {
            PlacesData2_.count
        } else {
            TableData.count
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if adminPage, TableData.count == 0 {
            addVenue = PlacesData_[indexPath.row].title!
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newScreenVenueSelected"), object: nil)

        } else if mapViewPage {
            addVenue = PlacesData_[indexPath.row].title!
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "screeningVenueSelected"), object: nil)

            let selectedItem = PlacesData_[indexPath.row].mapItem().placemark
            //  mapview_!.removeAnnotations(mapview_!.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedItem.coordinate
            annotation.title = selectedItem.name

            if let city = selectedItem.locality, let state = selectedItem.administrativeArea {
                annotation.subtitle = "(city) (state)"
            }
            mapview_!.addAnnotation(annotation)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: selectedItem.coordinate, span: span)
            mapview_!.setRegion(region, animated: true)

            dismiss(animated: true, completion: nil)
        } else {
            let data = TableData[indexPath.row]
            // Update detailsView with the selected venue information
            detailsLabel.text = "📍 Venue: \(data.name ?? "Unknown")\n🏠 Address: \(data.address ?? "N/A")"

            performSegue(withIdentifier: "goto_venues_details", sender: self)
        }
    }
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
