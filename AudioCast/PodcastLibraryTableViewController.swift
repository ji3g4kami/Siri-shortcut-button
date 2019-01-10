/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A `UIViewController` that displays the podcast library's episode containers, which are either shows or playlists.
*/

import UIKit
import AudioCastKit

class PodcastLibraryTableViewCell: UITableViewCell {
    
    static let CellID = "LibraryCell"
    
    @IBOutlet weak var libraryItemImageView: UIImageView!
    @IBOutlet weak var libraryItemTitleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        libraryItemImageView.layer.cornerRadius = 8
    }
}

class PodcastLibraryTableViewController: UITableViewController {
    
    private enum SegueIdentifiers: String {
        case episodeSegue
    }
    
    var selectedContainer: LibraryItemContainer?
    
    var notificationToken: NSObjectProtocol?
    private lazy var libraryManager: PodcastLibraryDataManager = {
        let libraryManager = PodcastLibraryDataManager.shared
        
        let center = NotificationCenter.default
        let queue = OperationQueue.main
        let name = dataChangedNotificationKey
        
        notificationToken = center.addObserver(forName: name, object: libraryManager, queue: queue) { [weak self] (notification) in
            self?.tableView.reloadData()
        }
        
        return libraryManager
    }()
    
    @IBAction private func refreshFeed(_ sender: Any) {
        libraryManager.addNewEpisodes(count: 3)
    }
    
    @IBAction private func stopPlayback(_ sender: Any) {
        AudioPlaybackManager.shared.stopPlaying()
    }
    
    @IBAction private func resetLibrary(_ sender: Any) {
        let alertController = UIAlertController(title: "Reset Library",
                                                message: "Reset the library to the initial data?",
                                                preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { [weak self] (_) in
            self?.libraryManager.resetLibrary()
        }))

        // Display in a popover if the device is an iPad.
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = sender as? UIBarButtonItem
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.episodeSegue.rawValue {
            guard let episodeController = segue.destination as? EpisodeTableViewController else { return }
            
            var containerToPass = selectedContainer
            if containerToPass == nil, let selectedIndexPath = tableView.indexPathForSelectedRow {
                containerToPass = container(for: selectedIndexPath)
            }
           
            if let container = containerToPass {
                episodeController.libraryContainer = container
            }
            
            selectedContainer = nil
        }
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)
        
        guard navigationController?.visibleViewController == self,
            let containerID = activity.userInfo?[NSUserActivity.LibraryItemContainerIDKey] as? LibraryItemID,
            let container = PodcastLibraryDataManager.shared.container(matching: containerID)
            else { return }
        
        selectedContainer = container
        performSegue(withIdentifier: SegueIdentifiers.episodeSegue.rawValue, sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let resetButton = UIBarButtonItem(title: "Reset Library", style: .plain, target: self, action: #selector(resetLibrary(_:)))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let stopButton = UIBarButtonItem(title: "Stop Audio", style: .plain, target: self, action: #selector(stopPlayback(_:)))
        toolbarItems = [resetButton, space, stopButton]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isToolbarHidden = false
    }
    
    private func container(for indexPath: IndexPath) -> LibraryItemContainer? {
        var containersForSection: [LibraryItemContainer]?
        if indexPath.section == Sections.shows.rawValue {
            containersForSection = libraryManager.podcastLibrary.shows
        } else if indexPath.section == Sections.playlists.rawValue {
            containersForSection = libraryManager.podcastLibrary.playlists
        }
        
        return containersForSection?[indexPath.row]
    }
}

extension PodcastLibraryTableViewController {
    
    private enum Sections: Int, CaseIterable {
        case shows
        case playlists
    }
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.allCases.count
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.shows.rawValue {
            return libraryManager.podcastLibrary.shows.count
        } else if section == Sections.playlists.rawValue {
            return libraryManager.podcastLibrary.playlists.count
        }
        
        return 0
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PodcastLibraryTableViewCell.CellID, for: indexPath)
        
        if let podcastCell = cell as? PodcastLibraryTableViewCell {
            let section = indexPath.section
            var dataItem: LibraryItemContainer?
            if section == Sections.shows.rawValue {
                dataItem = libraryManager.podcastLibrary.shows[indexPath.row]
            } else if section == Sections.playlists.rawValue {
                dataItem = libraryManager.podcastLibrary.playlists[indexPath.row]
            }
            
            if let item = dataItem {
                podcastCell.libraryItemTitleLabel.text = item.title
                podcastCell.libraryItemImageView.image = UIImage(named: item.artworkName)
                let episodeCount = libraryManager.episodes(for: item.itemID).count
                podcastCell.detailLabel.text = "\(episodeCount)"
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if let container = container(for: indexPath) {
            let libraryManager = PodcastLibraryDataManager.shared
            libraryManager.deleteInteraction(for: container)
            libraryManager.delete(container: container)
        }
    }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Sections.shows.rawValue {
            return "Shows"
        } else if section == Sections.playlists.rawValue {
            return "Playlists"
        }
        
        return nil
    }
}
