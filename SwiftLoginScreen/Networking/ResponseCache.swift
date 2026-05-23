// ResponseCache.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import Realm

protocol ResponseCache {
    func cachedResponse(for key: String) -> Data?
    func save(_ data: Data, for key: String)
}

class InMemoryCache: ResponseCache {
    // MARK: Internal

    func cachedResponse(for key: String) -> Data? {
        storage[key]
    }

    func save(_ data: Data, for key: String) {
        storage[key] = data
    }

    // MARK: Private

    private var storage: [String: Data] = [:]
}

/// Persists GET response bodies in Realm (``CachedResponse``), same 1-hour TTL as ``GeneralRequestManager``.
/// Must be called on the main thread only (``APIClient`` dispatches via `MainActor`).
final class RealmResponseCache: ResponseCache {
    // MARK: Internal

    func cachedResponse(for key: String) -> Data? {
        let p = NSPredicate(format: "url == %@", key)
        let results = CachedResponse.objects(with: p)
        guard results.count > 0,
              let cached = results.object(at: 0) as? CachedResponse,
              let data = cached.data else { return nil }

        if cached.timestamp.addingTimeInterval(ttl) > Date() {
            return data
        }

        let realm = RLMRealm.default()
        realm.beginWriteTransaction()
        realm.delete(cached)
        try? realm.commitWriteTransaction()
        return nil
    }

    func save(_ data: Data, for key: String) {
        let realm = RLMRealm.default()
        realm.beginWriteTransaction()
        let p = NSPredicate(format: "url == %@", key)
        let results = CachedResponse.objects(with: p)
        if results.count > 0 {
            realm.delete(results.object(at: 0) as! RLMObject)
        }
        let obj = CachedResponse()
        obj.url = key
        obj.data = data
        obj.timestamp = Date()
        obj.mimeType = "application/octet-stream" as NSString
        obj.encoding = "utf-8"
        obj.query = ""
        realm.add(obj)
        try? realm.commitWriteTransaction()
    }

    // MARK: Private

    private let ttl: TimeInterval = 3600
}
