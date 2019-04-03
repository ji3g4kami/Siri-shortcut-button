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
    let siriButton = INUIAddVoiceShortcutButton(style: .black)
    private var episodes: [PodcastEpisode]?
    
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
        
        let libraryManager = PodcastLibraryDataManager.shared
        let center = NotificationCenter.default
        let queue = OperationQueue.main
        let name = dataChangedNotificationKey
        
        notificationToken = center.addObserver(forName: name, object: libraryManager, queue: queue) { [weak self] (notification) in
            guard let container = self?.libraryContainer else { return }
            self?.episodesInContainer = libraryManager.episodes(for: container.itemID)
            self?.tableView.reloadData()
        }
        
        addSiriButton(to: view)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
    }

    func addSiriButton(to view: UIView) {
        
        siriButton.translatesAutoresizingMaskIntoConstraints = false

        
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { [unowned self] (allVoiceShortcuts, error) in
            if let allVoiceShortcuts = allVoiceShortcuts {
                if let identifier = UserDefaults.standard.string(forKey: self.libraryContainer.title),
                    let shortcut = allVoiceShortcuts.first(where: { (voiceShortcut) -> Bool in
                    return voiceShortcut.shortcut.intent?.identifier == identifier
                })?.shortcut {
                    self.siriButton.shortcut = shortcut
                } else {
                    let intent: INPlayMediaIntent = PlayRequest(container: self.libraryContainer, episodes: self.episodes).intent
                    intent.suggestedInvocationPhrase = self.libraryContainer.title
                    self.siriButton.shortcut = INShortcut(intent: intent)!
                }
            }
        }
        
        siriButton.delegate = self
        
        view.addSubview(siriButton)
        view.centerXAnchor.constraint(equalTo: siriButton.centerXAnchor).isActive = true
        view.centerYAnchor.constraint(equalTo: siriButton.centerYAnchor).isActive = true

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

extension EpisodeTableViewController: INUIAddVoiceShortcutViewControllerDelegate, INUIEditVoiceShortcutViewControllerDelegate {
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true) { [unowned self] in
            let identifier = voiceShortcut?.shortcut.intent?.identifier
            UserDefaults.standard.set(identifier, forKey: self.libraryContainer.title)
            self.addSiriButton(to: self.view)
        }
    }

    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true) { [unowned self] in
            UserDefaults.standard.removeObject(forKey: self.libraryContainer.title)
        }
    }

    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true) { [unowned self] in
            let identifier = voiceShortcut?.shortcut.intent?.identifier
            UserDefaults.standard.set(identifier, forKey: self.libraryContainer.title)
            self.addSiriButton(to: self.view)
        }
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
