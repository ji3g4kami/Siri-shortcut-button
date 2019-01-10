/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Defines the strucutre of the podcast library.
*/

import Foundation

public struct PodcastLibrary: Codable {
    public var shows: [PodcastShow]
    public var episodes: [PodcastEpisode]
    
    public var playlists: [Playlist]
    
    init() {
        shows = []
        episodes = []
        playlists = []
    }
    
    var allContainers: [LibraryItemContainer] {
        return shows + playlists
    }
}
