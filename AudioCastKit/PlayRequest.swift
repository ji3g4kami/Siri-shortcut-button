/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A struct representing media content the user has requested to play.
*/

import Foundation

/// A struct representing media content the user has requested to play.
public struct PlayRequest: Codable {
    public let container: LibraryItemContainer
    public let episodes: [PodcastEpisode]?
    
    public init(container: LibraryItemContainer, episodes: [PodcastEpisode]?) {
        self.container = container
        self.episodes = episodes
    }
}
