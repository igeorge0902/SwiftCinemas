//
//  BasketData.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 2017. 04. 26..
//  Copyright © 2017. George Gaspar. All rights reserved.
//

import Foundation

struct BasketItem {
    let movieName: String
    let seatId: Int
    let seatRow: String
    let seatNumber: String
    let price: Int
    let tax: Double
    let screeningDateId: String
    let moviePicture: String
    let venuePicture: String
    let venueName: String
    let screeningDateText: String

    init(
        movieName: String,
        seatId: Int,
        seatRow: String,
        seatNumber: String,
        price: Int,
        tax: Double,
        screeningDateId: String,
        moviePicture: String,
        venuePicture: String,
        venueName: String,
        screeningDateText: String
    ) {
        self.movieName = movieName
        self.seatId = seatId
        self.seatRow = seatRow
        self.seatNumber = seatNumber
        self.price = price
        self.tax = tax
        self.screeningDateId = screeningDateId
        self.moviePicture = moviePicture
        self.venuePicture = venuePicture
        self.venueName = venueName
        self.screeningDateText = screeningDateText
    }

    init?(dictionary: [String: Any]) {
        guard let movieName = dictionary["movie_name"] as? String,
              let seatId = dictionary["seatId"] as? Int,
              let seatRow = dictionary["seats_seatRow"] as? String,
              let seatNumber = dictionary["seats_seatNumber"] as? String,
              let price = dictionary["price"] as? Int,
              let tax = dictionary["tax"] as? Double,
              let screeningDateId = dictionary["screeningDateId"] as? String,
              let moviePicture = dictionary["movie_picture"] as? String,
              let venuePicture = dictionary["venue_picture"] as? String,
              let venueName = dictionary["venue_name"] as? String,
              let screeningDateText = dictionary["screening_date"] as? String else {
            return nil
        }

        self.init(
            movieName: movieName,
            seatId: seatId,
            seatRow: seatRow,
            seatNumber: seatNumber,
            price: price,
            tax: tax,
            screeningDateId: screeningDateId,
            moviePicture: moviePicture,
            venuePicture: venuePicture,
            venueName: venueName,
            screeningDateText: screeningDateText
        )
    }

    var dictionary: NSDictionary {
        [
            "movie_name": movieName,
            "seatId": seatId,
            "seats_seatRow": seatRow,
            "seats_seatNumber": seatNumber,
            "price": price,
            "tax": tax,
            "screeningDateId": screeningDateId,
            "movie_picture": moviePicture,
            "venue_picture": venuePicture,
            "venue_name": venueName,
            "screening_date": screeningDateText,
        ] as NSDictionary
    }
}

