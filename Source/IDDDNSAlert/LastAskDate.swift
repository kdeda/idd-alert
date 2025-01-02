//
//  LastAskDate.swift
//  idd-alert
//
//  Created by Klajd Deda on 12/30/24.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

internal struct LastAskDate: Equatable {
    static let dateFormatter = DateFormatter.init(posixFormatString: "yyyy-MM-dd HH:mm:ss")
    internal let propertyName: String

    internal init(propertyName: String) {
        self.propertyName = "DoNotShowAgain.\(propertyName)"
    }

    var date: Date {
        get {
            guard !propertyName.isEmpty
            else { return .distantPast }

            let stringValue = UserDefaults.standard.string(forKey: propertyName) ?? ""

            Log4swift[Self.self].info("key: '\(propertyName)' until: '\(stringValue)'")
            return Self.dateFormatter.date(from: stringValue) ?? .distantPast
        }
        set {
            guard !propertyName.isEmpty
            else { return }

            let stringValue = Self.dateFormatter.string(from: newValue)
            Log4swift[Self.self].info("key: '\(propertyName)' until: '\(stringValue)'")
            UserDefaults.standard.set(stringValue, forKey: propertyName)
        }
    }

    /**
     True if our date is on the future from today

     defaults read ~/Library/Preferences/com.id-design.v8.whatsize.plist DoNotShowAgain.AppReducer.noMeasuresFound
     defaults write ~/Library/Preferences/com.id-design.v8.whatsize.plist DoNotShowAgain.AppReducer.noMeasuresFound "2023-03-30 12:41:27"
     defaults delete ~/Library/Preferences/com.id-design.v8.whatsize.plist DoNotShowAgain.AppReducer.noMeasuresFound
     */
    var doNotShow: Bool {
        let date = self.date
        let elapsedTimeInSeconds1 = Int(Date.distantPast.elapsedTimeInSeconds)
        let elapsedTimeInSeconds = Int(date.elapsedTimeInSeconds)
        let rv = elapsedTimeInSeconds <= 0

        Log4swift[Self.self].info("key: '\(propertyName)' \(rv ? "doNotShow till" : "show"): '\(date.string(withFormat: "MMMM d, yyyy HH:mm"))'")
        return rv
    }
}
