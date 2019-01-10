/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data manager for the `PodcastLibrary` struct.
*/

import Foundation

/// A concrete `DataManager` for reading and writing data of type `PodcastLibrary`.
public class PodcastLibraryDataManager: DataManager<PodcastLibrary> {
    
    public static let shared = PodcastLibraryDataManager()
    
    private lazy var showIDManager: NewShowIDDataManager = {
        return NewShowIDDataManager()
    }()
    
    private convenience init() {
        let storageInfo = UserDefaultsStorageDescriptor(key: UserDefaults.Keys.podcastLibraryStorageKey.rawValue,
                                                    keyPath: \UserDefaults.podcastLibrary)
        self.init(storageDescriptor: storageInfo)
    }
    
    /// Deploys the starter data to `UserDefaults`.
    override func deployInitialData() {
        dataAccessQueue.sync {
            let bundle = Bundle(for: AudioPlaybackManager.self)
            var library = PodcastLibrary()
            if let starterData = bundle.url(forResource: "StarterData", withExtension: "plist") {
                do {
                    let data = try Data(contentsOf: starterData)
                    let decoder = PropertyListDecoder()
                    library = try decoder.decode(PodcastLibrary.self, from: data)
                    
                } catch let error {
                    fatalError("Could not seed starter data from StarterData.plist. Reason: \(error)")
                }
            }
            
            managedData = library
        }
        
        addNewEpisodes(count: 5)
    }
}

/// Public API for clients of `PodcastLibraryDataManager`
extension PodcastLibraryDataManager {
    
    public var podcastLibrary: PodcastLibrary {
        return dataAccessQueue.sync {
            return managedData
        }
    }
    
    public func container(matching searchID: String) -> LibraryItemContainer? {
        guard let libraryID = LibraryItemID(uuidString: searchID) else { return nil }
        return container(matching: libraryID)
    }
    
    /// Finds the matching container in the library.
    public func container(matching searchID: LibraryItemID) -> LibraryItemContainer? {
        return dataAccessQueue.sync {
            return managedData.allContainers.first { (container) -> Bool in
                container.itemID == searchID
            }
        }
    }

    /// Retreives all episodes that are available for a container (a podcast show or playlist).
    public func episodes(for container: LibraryItemID) -> [PodcastEpisode] {
        return dataAccessQueue.sync {
            return managedData.episodes.filter { (episode) -> Bool in
                episode.containerMembership.contains(container)
            }
        }
    }
    
    /// - Returns: An episode with the matching identifier
    public func episode(matching episodeID: LibraryItemID) -> PodcastEpisode? {
        return dataAccessQueue.sync {
            return managedData.episodes.first { (episode) -> Bool in
                episodeID == episode.itemID
            }
        }
    }
    
    /// Adds new episodes for each show to the library, and adds all new episodes to all playlists.
    public func addNewEpisodes(count: Int) {
        dataAccessQueue.sync {
            let playlistIDs = managedData.playlists.map { (container) -> UUID in
                return container.itemID
            }
            
            var updatedShows = [LibraryItemContainer]()
            var allNewEpisodes = [PodcastEpisode]()
            for show in managedData.shows {
                
                // Set the container IDs for playlists so all new episides are in the playlists
                var containers = playlistIDs
                containers.append(show.itemID)
                
                var newEpisodes = [PodcastEpisode]()
                for _ in 1...count {
                    let showNumber = showIDManager.nextID(for: show)
                    let newEpisode = PodcastEpisode(itemID: LibraryItemID(),
                                                    title: "Episode \(showNumber) (\(show.title))",
                                                    containerMembership: containers)
                    newEpisodes.append(newEpisode)
                }
                
                allNewEpisodes.append(contentsOf: newEpisodes)
                updatedShows.append(show)
            }

            let updatedEpisodeList = managedData.episodes + allNewEpisodes
            managedData.episodes = updatedEpisodeList
            managedData.shows = updatedShows
        }
        
        writeData()
        updateSystemUpcomingContentSuggestions()
    }
    
    /// Marks the episode as played
    public func markAsPlayed(_ episode: PodcastEpisode) {
        dataAccessQueue.sync {
            
            // Remove the played episode from the library.
            managedData.episodes.removeAll { (existingEpisode) -> Bool in
                return existingEpisode == episode
            }
        }
        
        writeData()
        
        // Since the available episodes have now changed, update the system with new information on
        // what unplayed content is in the library.
        updateSystemUpcomingContentSuggestions()
    }
    
    /// Removes a container from the podcast library, and also removes any episodes that are left without a container
    public func delete(container containerToDelete: LibraryItemContainer) {
        dataAccessQueue.sync {
            
            managedData.episodes = managedData.episodes.compactMap { (existingEpisode) -> PodcastEpisode? in
                var updatedContainers = existingEpisode.containerMembership
                
                // Episodes store what containers they are in. Remove the deleted container from the episode.
                updatedContainers.removeAll { (containerID) -> Bool in
                    return containerID == containerToDelete.itemID
                }
                
                // Delete the episode if the deleted container is the last one it belonged to.
                if !updatedContainers.isEmpty {
                    return PodcastEpisode(itemID: existingEpisode.itemID, title: existingEpisode.title, containerMembership: updatedContainers)
                } else {
                    return nil
                }
            }
            
            managedData.shows.removeAll { (currentContainer) -> Bool in
                return currentContainer.itemID == containerToDelete.itemID
            }
            
            managedData.playlists.removeAll { (currentContainer) -> Bool in
                return currentContainer.itemID == containerToDelete.itemID
            }
        }
        
        writeData()
    }
    
    /// Resets the library to the initial seed data.
    public func resetLibrary() {
        showIDManager.deployInitialData()
        deployInitialData()
    }
}

/// This extension enables observation of `UserDefaults` for the `podcastLibrary` key.
private extension UserDefaults {
    
    @objc var podcastLibrary: Data? {
        return data(forKey: Keys.podcastLibraryStorageKey.rawValue)
    }
    
    @objc var nextShowIDs: Data? {
        return data(forKey: Keys.nextShowIDsKey.rawValue)
    }
}

/// A concrete `DataManager` for getting the next episode number when the library feed is refreshed.
private class NewShowIDDataManager: DataManager<[UUID: Int]> {
    
    convenience init() {
        let storageInfo = UserDefaultsStorageDescriptor(key: UserDefaults.Keys.nextShowIDsKey.rawValue,
                                                        keyPath: \UserDefaults.nextShowIDs)
        self.init(storageDescriptor: storageInfo)
    }
    
    override func deployInitialData() {
        dataAccessQueue.sync {
            managedData = [UUID: Int]()
        }
    }
    
    func nextID(for container: LibraryItemContainer) -> Int {
        let nextID = dataAccessQueue.sync { () -> Int in
            
            let nextID = managedData[container.itemID] ?? 1
            managedData[container.itemID] = nextID + 1
            return nextID
        }
        
        writeData()
        return nextID
    }
}
