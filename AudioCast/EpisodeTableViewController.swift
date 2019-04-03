/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A table view controller that displays the episodes within a specific episode container.
*/

import UIKit
import Intents
import IntentsUI
import AudioCastKit

class EpisodeTableViewController: UITableViewController {
    
    private static let CellID = "EpisodeCell"
    
    var notificationToken: NSObjectProtocol?
    
    var libraryContainer: LibraryItemContainer! {
        didSet {
            title = libraryContainer.title
            episodesInContainer = PodcastLibraryDataManager.shared.episodes(for: libraryContainer.itemID)
            tableView.reloadData()
        }
    }
    
    private var episodesInContainer = [PodcastEpisode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSiriButton(to: view)
        
        let libraryManager = PodcastLibraryDataManager.shared
        let center = NotificationCenter.default
        let queue = OperationQueue.main
        let name = dataChangedNotificationKey
        
        notificationToken = center.addObserver(forName: name, object: libraryManager, queue: queue) { [weak self] (notification) in
            guard let container = self?.libraryContainer else { return }
            self?.episodesInContainer = libraryManager.episodes(for: container.itemID)
            self?.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
    }
    
    @available(iOS 12.0, *)
    func addSiriButton(to view: UIView) {
        let button = INUIAddVoiceShortcutButton(style: .black)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        view.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 350).isActive = true
        
        setupIntents(button: button)
    }
    
    @available(iOS 12.0, *)
    func setupIntents(button: INUIAddVoiceShortcutButton?) {
        let activity = NSUserActivity(activityType: "your_reverse_bundleID.\(libraryContainer.title)")
        activity.userInfo = ["speech": "\(libraryContainer.title)"]
        
        activity.title = libraryContainer.title
        activity.suggestedInvocationPhrase = "Play \(libraryContainer.title)"
        
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier("your_reverse_bundleID.\(libraryContainer.title)")
        view.userActivity = userActivity
        activity.becomeCurrent()
        self.userActivity = activity
        
        button?.shortcut = INShortcut(userActivity: activity)
        button?.delegate = self
    }
    
    public func play() {
        play(episodes: nil)
    }
    
    private func play(episodes: [PodcastEpisode]?) {
        let request = PlayRequest(container: libraryContainer, episodes: episodes)
        PodcastLibraryDataManager.shared.donatePlayRequestToSystem(request)
        
        if let itemsToPlay = AudioPlaybackManager.shared.resolveItems(for: request) {
            AudioPlaybackManager.shared.play(itemsToPlay)
        }
    }
    
    @IBAction private func playAll(_ sender: Any) {
        play(episodes: nil)
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)
        
        guard let containerID = activity.userInfo?[NSUserActivity.LibraryItemContainerIDKey] as? LibraryItemID,
            let container = PodcastLibraryDataManager.shared.container(matching: containerID)
            else { return }
        
        libraryContainer = container
    }
}

/// UITableViewDataSource
extension EpisodeTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodesInContainer.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let episode = episodesInContainer[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: EpisodeTableViewController.CellID, for: indexPath)
        cell.textLabel?.text = episode.title
        
        return cell
    }
}

/// UITableViewDelegate
extension EpisodeTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        play(episodes: [episodesInContainer[indexPath.row]])
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

@available(iOS 12.0, *)
extension EpisodeTableViewController: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

@available(iOS 12.0, *)
extension EpisodeTableViewController: INUIAddVoiceShortcutButtonDelegate {
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        addVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(addVoiceShortcutViewController, animated: true, completion: nil)
    }
    
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        editVoiceShortcutViewController.delegate = self
        editVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
}

@available(iOS 12.0, *)
extension EpisodeTableViewController: INUIEditVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}
