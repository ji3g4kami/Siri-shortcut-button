/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility file for accessing the app group configured for the app and extension points.
*/

import Foundation

extension UserDefaults {
    
    /// - Tag: app_group
    private static let AppGroup = "group.com.example.apple-samplecode.AudioCast"
    
    enum Keys: String {
        case historyStorageKey
        case podcastLibraryStorageKey
        case nextShowIDsKey
    }
    
    static let dataSuite = { () -> UserDefaults in
        guard let dataSuite = UserDefaults(suiteName: AppGroup) else {
             fatalError("Could not load UserDefaults for app group \(AppGroup)")
        }
        
        return dataSuite
    }()
}
