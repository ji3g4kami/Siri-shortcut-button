/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file defines the data types used to structure media in a podcast library.
*/

import Foundation

public typealias LibraryItemID = UUID
public protocol LibraryItem {
    var itemID: LibraryItemID { get }
    var title: String { get }
}

public typealias PodcastShow = LibraryItemContainer
public typealias Playlist = LibraryItemContainer

/// A container of podcasts, such as a show or a playlist
public struct LibraryItemContainer: LibraryItem, Codable, Hashable, Equatable {
    
    public enum ContainerType: UInt, Codable {
        case show = 1
        case playlist
    }
    
    public let containerType: ContainerType
    public let itemID: LibraryItemID
    public let title: String
    
    public let artworkName: String
}

extension NSUserActivity {
    public static let LibraryItemContainerIDKey = "LibraryItemContainerID"
}
