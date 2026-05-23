// RegEx.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation

class RegEx {
    func containsMatch(_ pattern: String, inString string: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSMakeRange(0, string.count)
        return regex?.firstMatch(in: string, options: [], range: range) != nil
    }

    func replaceMatches(_ pattern: String, inString string: String, withString replacementString: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSMakeRange(0, string.count)

        return regex?.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: replacementString)
    }
}
