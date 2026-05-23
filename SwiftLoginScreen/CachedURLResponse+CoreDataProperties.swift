// CachedURLResponse+CoreDataProperties.swift
// Created by Gyorgy Gaspar on 2026.05.23.

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
