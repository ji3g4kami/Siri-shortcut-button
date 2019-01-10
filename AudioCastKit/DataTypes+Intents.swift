/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility file that converts the struct types representing media into equivalent representations
 for use with the Intents framework.
*/

import Foundation
import Intents

protocol MediaItemConvertible {
    var mediaItem: INMediaItem { get }
}

extension LibraryItemContainer: MediaItemConvertible {
    
    var mediaItem: INMediaItem {
        return INMediaItem(identifier: itemID.uuidString,
                           title: title,
                           type: containerType.mediaItemType,
                           artwork: INImage(named: artworkName))
    }
}

extension PodcastEpisode: MediaItemConvertible {
    
    var mediaItem: INMediaItem {
        return INMediaItem(identifier: itemID.uuidString,
                           title: title,
                           type: .podcastEpisode,
                           artwork: nil)
    }
}

extension PlayRequest {
    
    public var intent: INPlayMediaIntent {
        let mediaItems = episodes?.map { $0.mediaItem }
        let intent = INPlayMediaIntent(mediaItems: mediaItems,
                                       mediaContainer: container.mediaItem,
                                       playShuffled: false,
                                       playbackRepeatMode: .none,
                                       resumePlayback: false)
        return intent
    }
    
    public init?(intent: INPlayMediaIntent) {
        
        let libraryManager = PodcastLibraryDataManager.shared
        
        guard let container = intent.mediaContainer,
            let containerID = container.identifier,
            let libraryContainerID = LibraryItemID(uuidString: containerID),
            let libraryContainer = libraryManager.container(matching: libraryContainerID)
        else {
            return nil
        }
        
        // Find unplayed episodes.
        let unplayedEpisodes = intent.mediaItems?.compactMap { (item) -> PodcastEpisode? in
            guard let episodeID = item.identifier,
                let libraryItemID = LibraryItemID(uuidString: episodeID)
            else {
                return nil
            }
            
            return libraryManager.episode(matching: libraryItemID)
        }
        
        self = PlayRequest(container: libraryContainer, episodes: unplayedEpisodes)
    }
}

extension LibraryItemContainer.ContainerType {
    
    public var mediaItemType: INMediaItemType {
        switch self {
        case .show:
            return .podcastShow
        case .playlist:
            return .podcastPlaylist
        }
    }
}
