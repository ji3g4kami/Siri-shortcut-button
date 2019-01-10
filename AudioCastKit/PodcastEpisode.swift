/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A struct representing an episode in the podcast library.
*/

import Foundation

public struct PodcastEpisode: LibraryItem, Codable, Equatable {
    
    public let itemID: LibraryItemID
    public let title: String
    let containerMembership: [LibraryItemID]
}
