/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension to `PodcastLibraryDataManager` to group all functionality related to the Intents framework together.
*/

import Foundation
import Intents
import os.log

extension PodcastLibraryDataManager {
    
    /// When your app has new information about media that is upcoming, such as when your app fetches
    /// new content through background refresh, or completes playback of existing content, inform the
    /// the system about the change in upcoming content through the `INUpcomingMediaManager`.
    /// - Tag: upcoming_media
    func updateSystemUpcomingContentSuggestions() {
        
        // Turn the list of shows into [INPlayMediaIntent] with each intent representing one unplayed episode.
        var newMediaIntents = podcastLibrary.shows.reduce([INPlayMediaIntent]()) { (partialResult, show) -> [INPlayMediaIntent] in
            
            let episodesForShow = episodes(for: show.itemID)
            let intentPerEpisode = episodesForShow.map { (episode) -> INPlayMediaIntent in
                return INPlayMediaIntent(mediaItems: [episode.mediaItem],
                                         mediaContainer: show.mediaItem,
                                         playShuffled: false,
                                         playbackRepeatMode: .none,
                                         resumePlayback: false)
            }
            
            let results = partialResult + intentPerEpisode
            return results
        }
        
        // The intents returned to the system need to be ordered with the most important suggestion from
        // the app first. In this sample, do a simple alphabetical sort based on the episode title.
        newMediaIntents.sort { (intentA, intentB) -> Bool in
            guard let titleA = intentA.mediaItems?.first?.title,
                let titleB = intentB.mediaItems?.first?.title
                else {
                    return false
            }
            
            return titleA.localizedCaseInsensitiveCompare(titleB) == .orderedAscending
        }
        
        // Apps with periodic new content, like podcasts, should set the prediction mode to `.onlyPredictSuggestedIntents` so that
        // episodes already listened to by the user are not suggested.
        INUpcomingMediaManager.shared.setPredictionMode(.onlyPredictSuggestedIntents, for: .podcastEpisode)
        INUpcomingMediaManager.shared.setSuggestedMediaIntents(NSOrderedSet(array: newMediaIntents))
    }
    
    /// Inform the system of what media the user asked to play.
    /// - Tag: set_interaction
    public func donatePlayRequestToSystem(_ request: PlayRequest) {
        let interaction = INInteraction(intent: request.intent, response: nil)
        
        /*
         Set the groupIdentifier to be the container's ID so that all interactions can be
         deleted with the same ID if the user deletes the container.
         */
        interaction.groupIdentifier = request.container.itemID.uuidString
        
        interaction.donate { (error) in
            if error != nil {
                guard let error = error as NSError? else { return }
                os_log("Could not donate interaction %@", error)
            } else {
                os_log("Play request interaction donation succeeded")
            }
        }
    }
    
    /// Removes any interactions for the container.
    /// - Tag: delete_interaction
    public func deleteInteraction(for container: LibraryItemContainer) {
        // Use the container's ID for the group identifier to match the ID used when the donation was made.
        INInteraction.delete(with: container.itemID.uuidString) { (error) in
            if error != nil {
                guard let error = error as NSError? else { return }
                os_log("Could not delete interaction %@", error)
            } else {
                os_log("Deleting container interaction succeeded")
            }
        }
    }
}
