//
//  People+CoreDataProperties.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 16/11/15.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import CoreData
import Foundation

extension People {
    @NSManaged var deviceId: String?
    @NSManaged var email: String?
    @NSManaged var name: String?
    @NSManaged var uuid: String?
}
