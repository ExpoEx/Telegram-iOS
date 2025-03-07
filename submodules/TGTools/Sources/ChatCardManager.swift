//
//  ChatCardManager.swift
//  TGTools
//
//  Created by Aleksei Voronov on 07.03.2025.
//

import UIKit
import TelegramCore
import SwiftSignalKit
import AccountContext
import Display
import AsyncDisplayKit
import Postbox

/// A reusable component that manages a card-based chat interface
public final class ChatCardManager {
    
    // MARK: - Types
    
    /// Represents a single chat card with its associated data
    public struct ChatCard {
        let peerId: PeerId
        let chatController: ChatController
        
        fileprivate init(peerId: PeerId, chatController: ChatController) {
            self.peerId = peerId
            self.chatController = chatController
        }
    }
    
    // MARK: - Properties
    
    /// The account context used for all operations
    private let accountContext: AccountContext
    
    /// The current active cards in the stack
    private(set) var cards: [ChatCard] = []
    
    /// Callback when card loading completes
    private var onCardsLoaded: (([ChatCard]) -> Void)?
    
    // MARK: - Initialization
    
    /// Initialize with a Telegram account context
    /// - Parameter context: The Telegram account context to use
    public init(accountContext: AccountContext) {
        self.accountContext = accountContext
    }
    
    // MARK: - Public Methods
    
    /// Load chat cards for the specified peer IDs
    /// - Parameters:
    ///   - peerIds: Array of peer IDs to load chat cards for
    ///   - completion: Callback when all cards are loaded
    public func loadChatCards(for peerIds: [PeerId], completion: @escaping ([ChatCard]) -> Void) {
        self.onCardsLoaded = completion
        
        // Clear existing cards
        self.cards = []
        
        // Load each peer and create a chat controller
        let dispatchGroup = DispatchGroup()
        
        for peerId in peerIds {
            dispatchGroup.enter()
            
            // Get peer information to confirm it exists
            let _ = (accountContext.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
            |> deliverOnMainQueue).start(next: { [weak self] peer in
                guard let self = self, let peer = peer else {
                    dispatchGroup.leave()
                    return
                }
                
                // Create a chat controller for this peer
                let chatController = self.createChatController(for: peer)
                
                // Add to our cards array
                let card = ChatCard(peerId: peerId, chatController: chatController)
                self.cards.append(card)
                
                dispatchGroup.leave()
            })
        }
        
        // Notify when all are loaded
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.onCardsLoaded?(self.cards)
        }
    }
    
    /// Add a chat card to the container view
    /// - Parameters:
    ///   - containerViewController: The view controller to add the chat card to
    ///   - containerView: The view to add the chat controller's view to
    ///   - card: The chat card to display
    public func addChatCard(to containerViewController: UIViewController,
                           in containerView: UIView,
                           card: ChatCard) {
        // Add chat controller as child view controller
        containerViewController.addChild(card.chatController)
        
        // Get the display node and add its view to the container
        let chatNode = card.chatController.displayNode
        containerView.addSubview(chatNode.view)
        
        // Set up the chat controller view to fill the container
        chatNode.frame = containerView.bounds
        
        // Finish adding the child controller
        card.chatController.didMove(toParent: containerViewController)
        
        // Update layout
        updateChatControllerLayout(containerView: containerView, chatController: card.chatController)
    }
    
    /// Remove a chat card from its container
    /// - Parameter card: The chat card to remove
    public func removeChatCard(_ card: ChatCard) {
        card.chatController.willMove(toParent: nil)
        card.chatController.displayNode.view.removeFromSuperview()
        card.chatController.removeFromParent()
    }
    
    /// Update the layout of a chat controller when the container view changes size
    /// - Parameters:
    ///   - containerView: The container view
    ///   - chatController: The chat controller to update
    public func updateChatControllerLayout(containerView: UIView, chatController: ChatController) {
        // Update frame
        chatController.displayNode.frame = containerView.bounds
        
        // Update container layout
        let containerLayout = ContainerViewLayout(
            size: containerView.bounds.size,
            metrics: LayoutMetrics(
                widthClass: .compact,
                heightClass: .compact,
                orientation: .portrait
            ),
            deviceMetrics: DeviceMetrics.iPhone13,
            intrinsicInsets: UIEdgeInsets(),
            safeInsets: containerView.safeAreaInsets,
            additionalInsets: UIEdgeInsets(),
            statusBarHeight: nil,
            inputHeight: nil,
            inputHeightIsInteractivellyChanging: false,
            inVoiceOver: false
        )
        
        chatController.containerLayoutUpdated(containerLayout, transition: .immediate)
    }
    
    // MARK: - Private Methods
    
    /// Creates a chat controller for a specific peer
    /// - Parameter peer: The peer to create a chat controller for
    /// - Returns: A configured chat controller
    private func createChatController(for peer: EnginePeer) -> ChatController {
        // Create chat controller in preview mode (no input field)
        let chatController = accountContext.sharedContext.makeChatController(
            context: accountContext,
            chatLocation: .peer(id: peer.id),
            subject: nil,
            botStart: nil,
            mode: .standard(.previewing),
            params: nil
        )
        
        return chatController
    }
}
