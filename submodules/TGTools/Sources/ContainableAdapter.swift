//
//  ContainableAdapter.swift
//  TGTools
//
//  Created by Aleksei Voronov on 07.03.2025.
//


import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit

/// Adapter class that wraps a UIViewController to be used with Telegram's container system
public final class ContainableAdapter: NSObject, ContainableController {
    // MARK: - Properties
    
    private let controller: UIViewController
    private let node: ASDisplayNode
    private let readyPromise = Promise<Bool>(true)
    
    // MARK: - ContainableController Protocol Properties
    
    public var view: UIView! {
        return controller.view
    }
    
    public var displayNode: ASDisplayNode {
        return node
    }
    
    public var isViewLoaded: Bool {
        return controller.isViewLoaded
    }
    
    public var isOpaqueWhenInOverlay: Bool {
        return false
    }
    
    public var blocksBackgroundWhenInOverlay: Bool {
        return false
    }
    
    public var ready: Promise<Bool> {
        return readyPromise
    }
    
    public var updateTransitionWhenPresentedAsModal: ((CGFloat, ContainedViewLayoutTransition) -> Void)?
    
    // MARK: - Initialization
    
    public init(controller: UIViewController) {
        self.controller = controller
        
        // Create a node that will contain the controller's view
        self.node = ASDisplayNode()
        self.node.backgroundColor = .clear
        self.node.automaticallyManagesSubnodes = false
        
        super.init()
        
        // Add the controller's view to the node if it's loaded
        if controller.isViewLoaded {
            self.node.view.addSubview(controller.view)
        }
    }
    
    // MARK: - ContainableController Protocol Methods
    
    public func combinedSupportedOrientations(currentOrientationToLock: UIInterfaceOrientationMask) -> ViewControllerSupportedOrientations {
        return ViewControllerSupportedOrientations(regularSize: .all, compactSize: .all)
    }
    
    public var deferScreenEdgeGestures: UIRectEdge {
        return []
    }
    
    public var prefersOnScreenNavigationHidden: Bool {
        return false
    }
    
    public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        // Update the controller's view frame to match the new layout
        transition.updateFrame(view: controller.view, frame: CGRect(origin: .zero, size: layout.size))
    }
    
    public func updateToInterfaceOrientation(_ orientation: UIInterfaceOrientation) {
        // Interface orientation update logic can be added here if needed
    }
    
    public func preferredContentSizeForLayout(_ layout: ContainerViewLayout) -> CGSize? {
        return nil
    }
    
    // MARK: - Lifecycle Methods
    
    public func viewWillAppear(_ animated: Bool) {
        controller.viewWillAppear(animated)
    }
    
    public func viewWillDisappear(_ animated: Bool) {
        controller.viewWillDisappear(animated)
    }
    
    public func viewDidAppear(_ animated: Bool) {
        controller.viewDidAppear(animated)
    }
    
    public func viewDidDisappear(_ animated: Bool) {
        controller.viewDidDisappear(animated)
    }
}
