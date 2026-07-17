//
//  UserDefaults+AppSettings.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import Foundation

extension UserDefaults {
    private enum Keys {
        static let conversionQuality = "conversionQuality"
        static let notifyOnCompletion = "notifyOnCompletion"
        static let outputFolderBookmark = "outputFolderBookmark"
        static let outputLocationMode = "outputLocationMode"
    }

    var conversionQuality: Double {
        get { object(forKey: Keys.conversionQuality) as? Double ?? 0.85 }
        set { set(newValue, forKey: Keys.conversionQuality) }
    }

    var notifyOnCompletion: Bool {
        get { bool(forKey: Keys.notifyOnCompletion) }
        set { set(newValue, forKey: Keys.notifyOnCompletion) }
    }

    var outputFolderBookmark: Data? {
        get { data(forKey: Keys.outputFolderBookmark) }
        set { set(newValue, forKey: Keys.outputFolderBookmark) }
    }

    var outputLocationMode: String? {
        get { string(forKey: Keys.outputLocationMode) }
        set { set(newValue, forKey: Keys.outputLocationMode) }
    }
}
