// CachedResponse.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import Realm

class CachedResponse: RLMObject {
    // MARK: Lifecycle

    override init() {
        super.init()

        data = NSData() as Data?
        encoding = "utf-8"
        mimeType = ""
        url = ""
        query = ""
        timestamp = NSDate() as Date?
    }

    // MARK: Internal

    @objc dynamic var data: Data!
    @objc dynamic var encoding: String!
    @objc dynamic var mimeType: NSString!
    @objc dynamic var url: String!
    @objc dynamic var query: String!
    @objc dynamic var timestamp: Date!
}
