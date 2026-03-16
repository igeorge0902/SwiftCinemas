//
//  RegEx.swift
//
//
//  Created by Gaspar Gyorgy on 05/09/15.
//  Copyright (c) 2015 Gaspar Gyorgy. All rights reserved.
//

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
