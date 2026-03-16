//
//  CachedURLResponse+CoreDataProperties.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 15/11/15.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import CoreData
import Foundation

extension CachedURLResponse {
    @NSManaged var data: Data?
    @NSManaged var encoding: String?
    @NSManaged var mimeType: String?
    @NSManaged var statusCode: NSNumber?
    @NSManaged var timestamp: Date?
    @NSManaged var url: String?
}
