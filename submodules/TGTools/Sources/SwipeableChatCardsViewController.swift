import UIKit
import TelegramCore
import SwiftSignalKit
import AccountContext
import Display
import AsyncDisplayKit
import Postbox
import SnapKit

/// A view controller that displays swipeable chat cards in a Tinder-like interface
public final class SwipeableChatCardsViewController: UIViewController {
    
    // MARK: - Properties
    
    /// The account context used for all operations
    private var accountContext: AccountContext?
    
    /// The chat card manager
    private var cardManager: ChatCardManager?
    
    /// The array of chat cards
    private var cards: [ChatCardManager.ChatCard] = []
    
    /// Array of card views currently displayed
    private var cardViews: [UIView] = []
    
    /// The index of the first visible card
    private var currentFirstIndex: Int = 0
    
    /// Maximum number of cards to show at once
    private let maxVisibleCards: Int = 3
    
    /// Pan gesture for swiping cards
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    // MARK: - UI Components
    
    /// Container view for displaying cards
    private let cardsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Lifecycle Methods
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCardLayouts()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Add subviews
        view.addSubview(cardsContainerView)
        
        // Setup constraints
        cardsContainerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.equalTo(cardsContainerView.snp.width).multipliedBy(1.5) // Card aspect ratio
        }
    }
    
    private func setupGestures() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    // MARK: - Public Methods
    
    /// Initialize the controller with a Telegram account context and peer IDs
    /// - Parameters:
    ///   - context: The Telegram account context to use
    ///   - peerIds: The peer IDs to display as cards
    public func setup(with context: AccountContext, peerIds: [PeerId]) {
        self.accountContext = context
        
        // Create the card manager
        let cardManager = ChatCardManager(accountContext: context)
        self.cardManager = cardManager
        
        // Load chat cards
        cardManager.loadChatCards(for: peerIds) { [weak self] cards in
            guard let self = self, !cards.isEmpty else { return }
            
            self.cards = cards
            self.setupInitialCards()
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up the initial stack of cards
    private func setupInitialCards() {
        // Clear any existing cards
        cardsContainerView.subviews.forEach { $0.removeFromSuperview() }
        cardViews.removeAll()
        
        // Initialize with first set of cards
        currentFirstIndex = 0
        
        // Load first set of visible cards (up to maxVisibleCards)
        let visibleCount = min(maxVisibleCards, cards.count)
        for i in 0..<visibleCount {
            if let cardView = createAndAddCard(at: i) {
                cardViews.append(cardView)
            }
        }
        
        // Apply visual styling to show depth
        updateCardStyles()
    }
    
    /// Creates and adds a card at the specified index
    /// - Parameter index: The index of the card to create
    /// - Returns: The created card view, or nil if creation failed
    private func createAndAddCard(at index: Int) -> UIView? {
        guard let cardManager = cardManager,
              index >= 0 && index < cards.count else {
            return nil
        }
        
        // Create a container for the card
        let cardView = createCardView()
        cardsContainerView.addSubview(cardView)
        cardView.frame = cardsContainerView.bounds
        
        // Add the chat controller to the card
        let card = cards[index]
        cardManager.addChatCard(to: self, in: cardView, card: card)
        
        return cardView
    }
    
    /// Creates a card view with appropriate styling
    /// - Returns: A configured UIView for a card
    private func createCardView() -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 24
        cardView.clipsToBounds = true
        
        // Add shadow to the card
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.allowsGroupOpacity = true
        
        return cardView
    }
    
    /// Updates the layouts of all card views
    private func updateCardLayouts() {
        guard let cardManager = cardManager else { return }
        
        for (i, cardView) in cardViews.enumerated() {
            let cardIndex = currentFirstIndex + i
            if cardIndex < cards.count {
                let card = cards[cardIndex]
                cardManager.updateChatControllerLayout(containerView: cardView, chatController: card.chatController)
            }
        }
    }
    
    /// Updates the visual styles of cards to show stacked effect
    private func updateCardStyles() {
        for (i, cardView) in cardViews.enumerated() {
            UIView.animate(withDuration: 0.3) {
                switch i {
                case 0: // Front card
                    cardView.isUserInteractionEnabled = true
                    cardView.transform = .identity
                    cardView.alpha = 1.0
                    cardView.layer.zPosition = 100
                case 1: // Second card
                    cardView.isUserInteractionEnabled = false
                    cardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                        .translatedBy(x: 0, y: -25)
                    cardView.alpha = 0.8
                    cardView.layer.zPosition = 90
                case 2: // Third card
                    cardView.isUserInteractionEnabled = false
                    cardView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                        .translatedBy(x: 0, y: -45)
                    cardView.alpha = 0.6
                    cardView.layer.zPosition = 80
                default:
                    cardView.isUserInteractionEnabled = false
                    cardView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                        .translatedBy(x: 0, y: -65)
                    cardView.alpha = 0.4
                    cardView.layer.zPosition = 70
                }
            }
        }
    }
    
    /// Advances to the next card
    private func advanceToNextCard() {
        guard let cardManager = cardManager,
              currentFirstIndex < cards.count - 1,
              !cardViews.isEmpty else { return }
        
        // Remove the first card with animation
        let topCardView = cardViews.removeFirst()
        
        UIView.animate(withDuration: 0.1, animations: {
            topCardView.alpha = 0
            topCardView.transform = CGAffineTransform(translationX: 300, y: 0).rotated(by: 0.2)
        }, completion: { _ in
            // Remove the current card controller and view
            let card = self.cards[self.currentFirstIndex]
            cardManager.removeChatCard(card)
            topCardView.removeFromSuperview()
            
            // Increment the current index
            self.currentFirstIndex += 1
            
            // Load a new card at the end if available
            let newCardIndex = self.currentFirstIndex + min(self.maxVisibleCards - 1, self.cardViews.count)
            if newCardIndex < self.cards.count {
                if let newCardView = self.createAndAddCard(at: newCardIndex) {
                    // Insert at the end
                    self.cardViews.append(newCardView)
                }
            }
            
            // Update the visual styles
            self.updateCardStyles()
        })
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard !cardViews.isEmpty else { return }
        
        let cardView = cardViews[0] // Top card
        let translation = gesture.translation(in: view)
        let xTranslation = translation.x
        
        switch gesture.state {
        case .changed:
            // Move the card with the gesture
            cardView.transform = CGAffineTransform(translationX: xTranslation, y: 0)
            
            // Add rotation based on the translation
            let rotationAngle = xTranslation / view.bounds.width * 0.2
            cardView.transform = cardView.transform.rotated(by: rotationAngle)
            
            // Change opacity as the card moves away
            let absTranslation = abs(xTranslation)
            let maxTranslation: CGFloat = 200
            let opacity = 1 - min(absTranslation / maxTranslation, 0.5)
            cardView.alpha = opacity
            
        case .ended, .cancelled:
            // If the card was dragged far enough to the right, advance to next card
            if xTranslation > 100 {
                advanceToNextCard()
            } else {
                // Return the card to its original position
                UIView.animate(withDuration: 0.2) {
                    cardView.transform = .identity
                    cardView.alpha = 1.0
                }
            }
            
        default:
            break
        }
    }
}
