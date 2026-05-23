// People+CoreDataProperties.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import CoreData
import Foundation

extension People {
    @NSManaged var deviceId: String?
    @NSManaged var email: String?
    @NSManaged var name: String?
    @NSManaged var uuid: String?
}
