import Foundation
import AsyncDisplayKit
import Postbox
import TelegramCore
import Display

private let backgroundCenterImage = generateImage(CGSize(width: 30.0, height: 82.0), rotatedContext: { size, context in
    context.clear(CGRect(origin: CGPoint(), size: size))
    context.setStrokeColor(UIColor(0xbfbfc4).cgColor)
    context.setFillColor(UIColor.white.cgColor)
    let lineWidth = UIScreenPixel
    context.setLineWidth(lineWidth)
    
    context.translateBy(x: 460.5, y: 364)
    let _ = try? drawSvgPath(context, path: "M-490.476836,-365 L-394.167708,-365 L-394.167708,-291.918214 C-394.167708,-291.918214 -383.538396,-291.918214 -397.691655,-291.918214 C-402.778486,-291.918214 -424.555168,-291.918214 -434.037301,-291.918214 C-440.297129,-291.918214 -440.780682,-283.5 -445.999879,-283.5 C-450.393041,-283.5 -452.491241,-291.918214 -456.502636,-291.918214 C-465.083339,-291.918214 -476.209155,-291.918214 -483.779021,-291.918214 C-503.033963,-291.918214 -490.476836,-291.918214 -490.476836,-291.918214 L-490.476836,-365 ")
    context.fillPath()
    context.translateBy(x: 0.0, y: lineWidth / 2.0)
    let _ = try? drawSvgPath(context, path: "M-490.476836,-365 L-394.167708,-365 L-394.167708,-291.918214 C-394.167708,-291.918214 -383.538396,-291.918214 -397.691655,-291.918214 C-402.778486,-291.918214 -424.555168,-291.918214 -434.037301,-291.918214 C-440.297129,-291.918214 -440.780682,-283.5 -445.999879,-283.5 C-450.393041,-283.5 -452.491241,-291.918214 -456.502636,-291.918214 C-465.083339,-291.918214 -476.209155,-291.918214 -483.779021,-291.918214 C-503.033963,-291.918214 -490.476836,-291.918214 -490.476836,-291.918214 L-490.476836,-365 ")
    context.strokePath()
    context.translateBy(x: -460.5, y: -lineWidth / 2.0 - 364.0)
    context.move(to: CGPoint(x: 0.0, y: lineWidth / 2.0))
    context.addLine(to: CGPoint(x: size.width, y: lineWidth / 2.0))
    context.strokePath()
})

private let backgroundLeftImage = generateImage(CGSize(width: 8.0, height: 16.0), rotatedContext: { size, context in
    context.clear(CGRect(origin: CGPoint(), size: size))
    context.setStrokeColor(UIColor(0xbfbfc4).cgColor)
    context.setFillColor(UIColor.white.cgColor)
    let lineWidth = UIScreenPixel
    context.setLineWidth(lineWidth)
    
    context.fillEllipse(in: CGRect(origin: CGPoint(), size: CGSize(width: size.height, height: size.height)))
    context.strokeEllipse(in: CGRect(origin: CGPoint(x: lineWidth / 2.0, y: lineWidth / 2.0), size: CGSize(width: size.height - lineWidth, height: size.height - lineWidth)))
})?.stretchableImage(withLeftCapWidth: 8, topCapHeight: 8)

private struct StickerEntry: Identifiable, Comparable {
    let index: Int
    let file: TelegramMediaFile
    
    var stableId: MediaId {
        return self.file.fileId
    }
    
    static func ==(lhs: StickerEntry, rhs: StickerEntry) -> Bool {
        return lhs.index == rhs.index && lhs.stableId == rhs.stableId
    }
    
    static func <(lhs: StickerEntry, rhs: StickerEntry) -> Bool {
        return lhs.index < rhs.index
    }
    
    func item(account: Account, interfaceInteraction: ChatPanelInterfaceInteraction) -> GridItem {
        let file = self.file
        return HorizontalStickerGridItem(account: account, file: file, interfaceInteraction: interfaceInteraction)
    }
}

private struct StickerEntryTransition {
    let deletions: [Int]
    let insertions: [GridNodeInsertItem]
    let updates: [GridNodeUpdateItem]
    let updateFirstIndexInSectionOffset: Int?
    let stationaryItems: GridNodeStationaryItems
    let scrollToItem: GridNodeScrollToItem?
}

private func preparedGridEntryTransition(account: Account, from fromEntries: [StickerEntry], to toEntries: [StickerEntry], interfaceInteraction: ChatPanelInterfaceInteraction) -> StickerEntryTransition {
    let stationaryItems: GridNodeStationaryItems = .none
    let scrollToItem: GridNodeScrollToItem? = nil
    
    let (deleteIndices, indicesAndItems, updateIndices) = mergeListsStableWithUpdates(leftList: fromEntries, rightList: toEntries)
    
    let deletions = deleteIndices
    let insertions = indicesAndItems.map { GridNodeInsertItem(index: $0.0, item: $0.1.item(account: account, interfaceInteraction: interfaceInteraction), previousIndex: $0.2) }
    let updates = updateIndices.map { GridNodeUpdateItem(index: $0.0, item: $0.1.item(account: account, interfaceInteraction: interfaceInteraction)) }
    
    return StickerEntryTransition(deletions: deletions, insertions: insertions, updates: updates, updateFirstIndexInSectionOffset: nil, stationaryItems: stationaryItems, scrollToItem: scrollToItem)
}

final class HorizontalStickersChatContextPanelNode: ChatInputContextPanelNode {
    private let backgroundLeftNode: ASImageNode
    private let backgroundNode: ASImageNode
    private let backgroundRightNode: ASImageNode
    private let clippingNode: ASDisplayNode
    private let gridNode: GridNode
    
    private var validLayout: (CGSize, ChatPresentationInterfaceState)?
    private var currentEntries: [StickerEntry] = []
    private var queuedTransitions: [StickerEntryTransition] = []
    
    override init(account: Account) {
        self.backgroundNode = ASImageNode()
        self.backgroundNode.displayWithoutProcessing = true
        self.backgroundNode.displaysAsynchronously = false
        self.backgroundNode.image = backgroundCenterImage
        
        self.backgroundLeftNode = ASImageNode()
        self.backgroundLeftNode.displayWithoutProcessing = true
        self.backgroundLeftNode.displaysAsynchronously = false
        self.backgroundLeftNode.image = backgroundLeftImage
        
        self.backgroundRightNode = ASImageNode()
        self.backgroundRightNode.displayWithoutProcessing = true
        self.backgroundRightNode.displaysAsynchronously = false
        self.backgroundRightNode.image = backgroundLeftImage
        self.backgroundRightNode.transform = CATransform3DMakeScale(-1.0, 1.0, 1.0)
        
        self.clippingNode = ASDisplayNode()
        self.clippingNode.clipsToBounds = true
        self.gridNode = GridNode()
        self.gridNode.transform = CATransform3DMakeRotation(-CGFloat(M_PI / 2.0), 0.0, 0.0, 1.0)
        self.gridNode.view.disablesInteractiveTransitionGestureRecognizer = true
        
        super.init(account: account)
        
        self.isOpaque = false
        
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.backgroundLeftNode)
        self.addSubnode(self.backgroundRightNode)
        
        self.addSubnode(self.clippingNode)
        self.clippingNode.addSubnode(self.gridNode)
    }
    
    func updateResults(_ results: [TelegramMediaFile]) {
        let previousEntries = self.currentEntries
        var entries: [StickerEntry] = []
        for i in 0 ..< results.count {
            entries.append(StickerEntry(index: i, file: results[i]))
        }
        self.currentEntries = entries
        
        if let validLayout = self.validLayout {
            self.updateLayout(size: validLayout.0, transition: .immediate, interfaceState: validLayout.1)
        }
        
        let transition = preparedGridEntryTransition(account: self.account, from: previousEntries, to: entries, interfaceInteraction: self.interfaceInteraction!)
        self.enqueueTransition(transition)
    }
    
    private func enqueueTransition(_ transition: StickerEntryTransition) {
        self.queuedTransitions.append(transition)
        if self.validLayout != nil {
            self.dequeueTransitions()
        }
    }
    
    private func dequeueTransitions() {
        while !self.queuedTransitions.isEmpty {
            let transition = self.queuedTransitions.removeFirst()
            self.gridNode.transaction(GridNodeTransaction(deleteItems: transition.deletions, insertItems: transition.insertions, updateItems: transition.updates, scrollToItem: transition.scrollToItem, updateLayout: nil, stationaryItems: transition.stationaryItems, updateFirstIndexInSectionOffset: transition.updateFirstIndexInSectionOffset), completion: { _ in })
        }
    }
    
    override func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition, interfaceState: ChatPresentationInterfaceState) {
        let sideInsets: CGFloat = 10.0
        let contentWidth = min(size.width - sideInsets - sideInsets, max(24.0, CGFloat(self.currentEntries.count) * 66.0 + 6.0))
        
        var leftInset: CGFloat = 40.0
        var leftOffset: CGFloat = 0.0
        if sideInsets + floor(contentWidth / 2.0) < sideInsets + leftInset + 15.0 {
            let updatedLeftInset = sideInsets + floor(contentWidth / 2.0) - 15.0 - sideInsets
            leftOffset = leftInset - updatedLeftInset
            leftInset = updatedLeftInset
        }
        
        let backgroundFrame = CGRect(origin: CGPoint(x: sideInsets + leftOffset, y: size.height - 82.0 + 4.0), size: CGSize(width: contentWidth, height: 82.0))
        let backgroundLeftFrame = CGRect(origin: backgroundFrame.origin, size: CGSize(width: leftInset, height: backgroundFrame.size.height - 10.0 + UIScreenPixel))
        let backgroundCenterFrame = CGRect(origin: CGPoint(x: backgroundLeftFrame.maxX, y: backgroundFrame.minY), size: CGSize(width: 30.0, height: 82.0))
        let backgroundRightFrame = CGRect(origin: CGPoint(x: backgroundCenterFrame.maxX, y: backgroundFrame.minY), size: CGSize(width: max(0.0, backgroundFrame.minX + backgroundFrame.size.width - backgroundCenterFrame.maxX), height: backgroundFrame.size.height - 10.0 + UIScreenPixel))
        transition.updateFrame(node: self.backgroundLeftNode, frame: backgroundLeftFrame)
        transition.updateFrame(node: self.backgroundNode, frame: backgroundCenterFrame)
        transition.updateFrame(node: self.backgroundRightNode, frame: backgroundRightFrame)
        
        let gridFrame = CGRect(origin: CGPoint(x: backgroundFrame.minX, y: backgroundFrame.minY + 4.0), size: CGSize(width: backgroundFrame.size.width, height: 66.0))
        self.clippingNode.frame = gridFrame
        self.gridNode.frame = CGRect(origin: CGPoint(), size: CGSize(width: gridFrame.size.height, height: gridFrame.size.width))
        
        let gridBounds = self.gridNode.bounds
        self.gridNode.bounds = CGRect(x: gridBounds.minX, y: gridBounds.minY, width: gridFrame.size.height, height: gridFrame.size.width)
        self.gridNode.position = CGPoint(x: gridFrame.size.width / 2.0, y: gridFrame.size.height / 2.0)
        
        self.gridNode.transaction(GridNodeTransaction(deleteItems: [], insertItems: [], updateItems: [], scrollToItem: nil, updateLayout: GridNodeUpdateLayout(layout: GridNodeLayout(size: CGSize(width: gridFrame.size.height, height: gridFrame.size.width), insets: UIEdgeInsets(top: 3.0, left: 0.0, bottom: 3.0, right: 0.0), preloadSize: 100.0, itemSize: CGSize(width: 66.0, height: 66.0)), transition: .immediate), stationaryItems: .all, updateFirstIndexInSectionOffset: nil), completion: { _ in })
        
        let dequeue = self.validLayout == nil
        self.validLayout = (size, interfaceState)
        
        if dequeue {
            self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
            self.dequeueTransitions()
        }
    }
    
    override func animateOut(completion: @escaping () -> Void) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false, completion: { _ in
            completion()
        })
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return super.hitTest(point, with: event)
    }
}