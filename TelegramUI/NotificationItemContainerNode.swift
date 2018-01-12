import Foundation
import AsyncDisplayKit
import Display

final class NotificationItemContainerNode: ASDisplayNode {
    private let backgroundNode: ASImageNode
    
    private var validLayout: ContainerViewLayout?
    
    var item: NotificationItem?
    
    private var hapticFeedback: HapticFeedback?
    private var willBeExpanded = false {
        didSet {
            if self.willBeExpanded != oldValue {
                if self.hapticFeedback == nil {
                    self.hapticFeedback = HapticFeedback()
                }
                self.hapticFeedback?.impact()
            }
        }
    }
    
    var contentNode: NotificationItemNode? {
        didSet {
            if self.contentNode !== oldValue {
                oldValue?.removeFromSupernode()
            }
            
            if let contentNode = self.contentNode {
                self.addSubnode(contentNode)
                
                if let validLayout = self.validLayout {
                    self.updateLayout(layout: validLayout, transition: .immediate)
                }
            }
        }
    }
    
    var dismissed: ((NotificationItem) -> Void)?
    var cancelTimeout: ((NotificationItem) -> Void)?
    var resumeTimeout: ((NotificationItem) -> Void)?
    
    var cancelledTimeout = false
    
    init(theme: PresentationTheme) {
        self.backgroundNode = ASImageNode()
        self.backgroundNode.displayWithoutProcessing = true
        self.backgroundNode.displaysAsynchronously = false
        self.backgroundNode.image = PresentationResourcesRootController.inAppNotificationBackground(theme)
        
        super.init()
        
        self.addSubnode(self.backgroundNode)
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(_:)))
        panRecognizer.delaysTouchesBegan = false
        panRecognizer.cancelsTouchesInView = false
        self.view.addGestureRecognizer(panRecognizer)
    }
    
    func animateIn() {
        if let _ = self.validLayout {
            self.layer.animatePosition(from: CGPoint(x: 0.0, y: -self.backgroundNode.bounds.size.height), to: CGPoint(), duration: 0.4, additive: true)
        }
    }
    
    func animateOut(completion: @escaping () -> Void) {
        if let _ = self.validLayout {
            self.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: -self.backgroundNode.bounds.size.height), duration: 0.4, removeOnCompletion: false, additive: true, completion: { _ in
                completion()
            })
        } else {
            completion()
        }
    }
    
    func updateLayout(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        self.validLayout = layout
        
        if let contentNode = self.contentNode {
            var contentInsets = UIEdgeInsets(top: 8.0, left: 8.0 + layout.safeInsets.left, bottom: 8.0, right: 8.0 + layout.safeInsets.right)
            if let statusBarHeight = layout.statusBarHeight, CGFloat(44.0).isLessThanOrEqualTo(statusBarHeight) {
                contentInsets.top += 34.0
            }
            let contentWidth = layout.size.width - contentInsets.left - contentInsets.right
            let contentHeight = contentNode.updateLayout(width: contentWidth, transition: transition)
            
            transition.updateFrame(node: self.backgroundNode, frame: CGRect(origin: CGPoint(x: layout.safeInsets.left, y: contentInsets.top - 8.0), size: CGSize(width: layout.size.width - layout.safeInsets.left - layout.safeInsets.right, height: 8.0 + contentHeight + 20.0)))
            
            transition.updateFrame(node: contentNode, frame: CGRect(origin: CGPoint(x: contentInsets.left, y: contentInsets.top), size: CGSize(width: contentWidth, height: contentHeight)))
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let contentNode = self.contentNode, contentNode.frame.contains(point) {
            return self.view
        }
        return nil
    }
    
    @objc func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            if let item = self.item {
                item.tapped({ [weak self] in
                    if let strongSelf = self, let contentNode = strongSelf.contentNode, let _ = strongSelf.item {
                        return (contentNode, {
                            if let strongSelf = self, let item = strongSelf.item {
                                strongSelf.dismissed?(item)
                            }
                        })
                    } else {
                        return (nil, {})
                    }
                })
            }
        }
    }
    
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
            case .began:
                self.cancelledTimeout = false
            case .changed:
                let translation = recognizer.translation(in: self.view)
                var bounds = self.bounds
                bounds.origin.y = -translation.y
                if bounds.origin.y < 0.0 {
                    let delta = -bounds.origin.y
                    bounds.origin.y = -((1.0 - (1.0 / (((delta) * 0.55 / (50.0)) + 1.0))) * 50.0)
                }
                if abs(translation.y) > 1.0 {
                    if self.hapticFeedback == nil {
                        self.hapticFeedback = HapticFeedback()
                    }
                    self.hapticFeedback?.prepareImpact()
                }
                self.bounds = bounds
                var expand = false
                if let item = self.item {
                    if !self.cancelledTimeout && abs(translation.y) > 4.0 {
                        self.cancelledTimeout = true
                        self.cancelTimeout?(item)
                    }
                    expand = item.canBeExpanded() && bounds.minY < -24.0
                }
                if self.willBeExpanded != expand {
                    self.willBeExpanded = expand
                }
            case .ended:
                let translation = recognizer.translation(in: self.view)
                var bounds = self.bounds
                bounds.origin.y = -translation.y
                if bounds.origin.y < 0.0 {
                    let delta = -bounds.origin.y
                    bounds.origin.y = -((1.0 - (1.0 / (((delta) * 0.55 / (50.0)) + 1.0))) * 50.0)
                }
                
                let velocity = recognizer.velocity(in: self.view)
                
                if (bounds.minY < -20.0 || velocity.y > 300.0) {
                    if let item = self.item {
                        if !self.cancelledTimeout {
                            self.cancelledTimeout = true
                            self.cancelTimeout?(item)
                        }
                        
                        item.expand({ [weak self] in
                            if let strongSelf = self, let contentNode = strongSelf.contentNode, let _ = strongSelf.item {
                                return (contentNode, {
                                    if let strongSelf = self, let item = strongSelf.item {
                                        strongSelf.dismissed?(item)
                                    }
                                })
                            } else {
                                return (nil, {})
                            }
                        })
                    }
                } else if bounds.minY > 5.0 || velocity.y < -200.0 {
                    self.animateOut(completion: { [weak self] in
                        if let strongSelf = self, let item = strongSelf.item {
                            strongSelf.dismissed?(item)
                        }
                    })
                } else {
                    if let item = self.item, self.cancelledTimeout {
                        self.cancelledTimeout = false
                        self.resumeTimeout?(item)
                    }
                    
                    self.cancelledTimeout = false
                    let previousBounds = self.bounds
                    var bounds = self.bounds
                    bounds.origin.y = 0.0
                    self.bounds = bounds
                    self.layer.animateBounds(from: previousBounds, to: self.bounds, duration: 0.3, timingFunction: kCAMediaTimingFunctionEaseInEaseOut)
                    
                    self.willBeExpanded = false
                }
            case .cancelled:
                self.willBeExpanded = false
                self.cancelledTimeout = false
                let previousBounds = self.bounds
                var bounds = self.bounds
                bounds.origin.y = 0.0
                self.bounds = bounds
                self.layer.animateBounds(from: previousBounds, to: self.bounds, duration: 0.3, timingFunction: kCAMediaTimingFunctionEaseInEaseOut)
            default:
                break
        }
    }
}