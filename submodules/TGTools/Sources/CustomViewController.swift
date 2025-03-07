// MARK: - CustomChatViewController.swift
import UIKit
import TelegramCore
import SwiftSignalKit
import AccountContext
import Display
import AsyncDisplayKit
import Postbox
import SnapKit

/// A view controller that displays a Telegram chat interface
public final class CustomChatViewController: UIViewController {
    // MARK: - Properties
    
    /// The Telegram account context used for all operations
    private var accountContext: AccountContext?
    
    /// The currently active chat controller
    private var chatController: ChatController?
    
    /// The display node from the chat controller
    private var chatControllerNode: ASDisplayNode?
    
    // MARK: - UI Components
    
    /// Label to display the current status to the user
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Waiting for account context..."
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// Container view for the Telegram chat interface
    private let chatContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    
    // MARK: - Lifecycle Methods
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateChatControllerLayout()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanupChatControllerIfNeeded()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Add subviews
        view.addSubview(statusLabel)
        view.addSubview(chatContainer)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Status label
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        chatContainer.snp.makeConstraints { make in
            make.height.equalTo(520)
            make.centerY.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(16)
        }
        
        chatContainer.layer.cornerRadius = 24
    }
    
    // MARK: - Public Methods
    
    /// Initialize the controller with a Telegram account context
    /// - Parameter context: The Telegram account context to use
    public func setupWithContext(_ context: AccountContext) {
        self.accountContext = context
        updateStatus("Context received! Loading chat...")
        
        // Open chat with specified peer ID
        // Note: You can use context.account.peerId to open "Saved Messages"
        openChat(peerId: PeerId(683905927))
    }
    
    // MARK: - Private Methods
    
    /// Opens a chat with the specified peer
    /// - Parameter peerId: The ID of the peer to open chat with
    private func openChat(peerId: PeerId) {
        guard let context = accountContext else {
            updateStatus("Cannot open chat: no account context")
            return
        }
        
        // Get peer information first to confirm it exists
        let _ = (context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
        |> deliverOnMainQueue).start(next: { [weak self] peer in
            guard let self = self, let peer = peer else {
                self?.updateStatus("Peer not found")
                return
            }
            
            self.createAndDisplayChatController(context: context, peer: peer)
        })
    }
    
    /// Updates the status label with a new message
    /// - Parameter message: The message to display
    private func updateStatus(_ message: String) {
        statusLabel.text = message
    }
    
    /// Creates and displays the chat controller for a specific peer
    /// - Parameters:
    ///   - context: The account context to use
    ///   - peer: The peer to open a chat with
    private func createAndDisplayChatController(context: AccountContext, peer: EnginePeer) {
        // Create chat controller
        let chatController = context.sharedContext.makeChatController(
            context: context,
            chatLocation: .peer(id: peer.id),
            subject: nil,
            botStart: nil,
            mode: .standard(.previewing),
            params: nil
        )
        
        self.chatController = chatController
        
        // Add chat controller as child view controller
        addChild(chatController)
        
        // Get the ASDisplayNode from chat controller and add its view to our container
        let chatNode = chatController.displayNode
        self.chatControllerNode = chatNode
        chatContainer.addSubview(chatNode.view)
        
        // Set up the chat controller view to fill the container
        chatNode.frame = chatContainer.bounds
        
        // Finish adding the child controller
        chatController.didMove(toParent: self)
        
        // Show the chat container and hide the status label
        chatContainer.isHidden = false
        statusLabel.isHidden = true
        
        // Update the status label (in case we need to show it again)
        updateStatus("Opened chat with: \(peer)")
        
        // Initial layout update
        updateChatControllerLayout()
    }
    
    /// Updates the chat controller layout when the view layout changes
    private func updateChatControllerLayout() {
        guard let chatNode = chatControllerNode, let chatController = self.chatController else { return }
        
        // Update frame
        chatNode.frame = chatContainer.bounds
        
        // Update container layout
        let containerLayout = ContainerViewLayout(
            size: chatContainer.bounds.size,
            metrics: LayoutMetrics(
                widthClass: .compact,
                heightClass: .compact,
                orientation: .portrait
            ),
            deviceMetrics: DeviceMetrics.iPhone13,
            intrinsicInsets: UIEdgeInsets(),
            safeInsets: view.safeAreaInsets,
            additionalInsets: UIEdgeInsets(),
            statusBarHeight: nil,
            inputHeight: nil,
            inputHeightIsInteractivellyChanging: false,
            inVoiceOver: false
        )
        
        chatController.containerLayoutUpdated(containerLayout, transition: .immediate)
    }
    
    /// Cleans up the chat controller if the view controller is being removed
    private func cleanupChatControllerIfNeeded() {
        if isMovingFromParent || isBeingDismissed {
            chatController?.willMove(toParent: nil)
            chatController?.view.removeFromSuperview()
            chatController?.removeFromParent()
            chatController = nil
            chatControllerNode = nil
        }
    }
}

