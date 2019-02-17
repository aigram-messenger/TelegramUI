import Foundation
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import Postbox

class ThemeSettingsChatPreviewItem: ListViewItem, ItemListItem {
    let account: Account
    let theme: PresentationTheme
    let componentTheme: PresentationTheme
    let strings: PresentationStrings
    let sectionId: ItemListSectionId
    let fontSize: PresentationFontSize
    let wallpaper: TelegramWallpaper
    let dateTimeFormat: PresentationDateTimeFormat
    
    init(account: Account, theme: PresentationTheme, componentTheme: PresentationTheme, strings: PresentationStrings, sectionId: ItemListSectionId, fontSize: PresentationFontSize, wallpaper: TelegramWallpaper, dateTimeFormat: PresentationDateTimeFormat) {
        self.account = account
        self.theme = theme
        self.componentTheme = componentTheme
        self.strings = strings
        self.sectionId = sectionId
        self.fontSize = fontSize
        self.wallpaper = wallpaper
        self.dateTimeFormat = dateTimeFormat
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, () -> Void)) -> Void) {
        async {
            let node = ThemeSettingsChatPreviewItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
            
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { apply() })
                })
            }
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping () -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? ThemeSettingsChatPreviewItemNode {
                let makeLayout = nodeValue.asyncLayout()
                
                async {
                    let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                    Queue.mainQueue().async {
                        completion(layout, {
                            apply()
                        })
                    }
                }
            }
        }
    }
}

class ThemeSettingsChatPreviewItemNode: ListViewItemNode {
    private let backgroundNode: ASImageNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    
    private let containerNode: ASDisplayNode
    
    private var messageNode1: ListViewItemNode?
    private var messageNode2: ListViewItemNode?
    
    private var item: ThemeSettingsChatPreviewItem?
    
    private let controllerInteraction: ChatControllerInteraction
    
    init() {
        self.backgroundNode = ASImageNode()
        self.backgroundNode.isLayerBacked = true
        self.backgroundNode.displaysAsynchronously = false
        self.backgroundNode.displayWithoutProcessing = true
        self.backgroundNode.contentMode = .scaleAspectFill
        
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true
        
        self.containerNode = ASDisplayNode()
        self.containerNode.subnodeTransform = CATransform3DMakeRotation(CGFloat.pi, 0.0, 0.0, 1.0)
        
        self.controllerInteraction = ChatControllerInteraction(openMessage: { _, _ in
        return false }, openPeer: { _, _, _ in }, openPeerMention: { _ in }, openMessageContextMenu: { _, _, _ in }, navigateToMessage: { _, _ in }, clickThroughMessage: { }, toggleMessagesSelection: { _, _ in }, sendMessage: { _ in }, sendSticker: { _, _ in }, sendGif: { _ in }, requestMessageActionCallback: { _, _, _ in }, activateSwitchInline: { _, _ in }, openUrl: { _, _, _ in }, shareCurrentLocation: {}, shareAccountContact: {}, sendBotCommand: { _, _ in }, openInstantPage: { _ in  }, openHashtag: { _, _ in }, updateInputState: { _ in }, updateInputMode: { _ in }, openMessageShareMenu: { _ in
        }, presentController: { _, _ in }, navigationController: {
            return nil
        }, presentGlobalOverlayController: { _, _ in }, callPeer: { _ in }, longTap: { _ in }, openCheckoutOrReceipt: { _ in }, openSearch: { }, setupReply: { _ in
        }, canSetupReply: { _ in
            return false
        }, navigateToFirstDateMessage: { _ in
        }, requestRedeliveryOfFailedMessages: { _ in
        }, addContact: { _ in   
        }, requestMessageUpdate: { _ in
        }, cancelInteractiveKeyboardGestures: {
        }, automaticMediaDownloadSettings: AutomaticMediaDownloadSettings.defaultSettings,
           handleMessagesWithBots: { _, _ in },
           showBotDetails: { _, _ in },
           buyBot: { _, _ in },
           showBotActions: { _, _ in },
           handleSuggestionTap: { _ in })
        
        super.init(layerBacked: false, dynamicBounce: false)
        
        self.addSubnode(self.containerNode)
    }
    
    func asyncLayout() -> (_ item: ThemeSettingsChatPreviewItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let currentItem = self.item
        
        let controllerInteraction = self.controllerInteraction
        let currentNode1 = self.messageNode1
        let currentNode2 = self.messageNode2
        
        return { item, params, neighbors in
            var updatedBackgroundImage: UIImage?
            if currentItem?.wallpaper != item.wallpaper {
                updatedBackgroundImage = UIImage()
                switch item.wallpaper {
                    case .builtin:
                        if let filePath = frameworkBundle.path(forResource: "ChatWallpaperBuiltin0", ofType: "jpg") {
                            updatedBackgroundImage = UIImage(contentsOfFile: filePath)?.precomposed()
                        }
                    case let .color(color):
                        updatedBackgroundImage = generateImage(CGSize(width: 1.0, height: 1.0), rotatedContext: { size, context in
                            context.setFillColor(UIColor(rgb: UInt32(bitPattern: color)).cgColor)
                            context.fill(CGRect(origin: CGPoint(), size: size))
                        })
                    case let .image(representations):
                        if let largest = largestImageRepresentation(representations) {
                            if let path = item.account.postbox.mediaBox.completedResourcePath(largest.resource) {
                                updatedBackgroundImage = UIImage(contentsOfFile: path)?.precomposed()
                            }
                        }
                }
            }
            
            let insets: UIEdgeInsets
            let separatorHeight = UIScreenPixel
            
            let peerId = PeerId(namespace: Namespaces.Peer.CloudUser, id: 1)
            
            var peers = SimpleDictionary<PeerId, Peer>()
            var messages = SimpleDictionary<MessageId, Message>()
            
            peers[peerId] = TelegramUser(id: peerId, accessHash: nil, firstName: item.strings.Appearance_PreviewReplyAuthor, lastName: "", username: nil, phone: nil, photo: [], botInfo: nil, restrictionInfo: nil, flags: [])
            let replyMessageId = MessageId(peerId: peerId, namespace: 0, id: 3)
            messages[replyMessageId] = Message(stableId: 3, stableVersion: 0, id: replyMessageId, globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, timestamp: 66000, flags: [.Incoming], tags: [], globalTags: [], localTags: [], forwardInfo: nil, author: peers[peerId], text: item.strings.Appearance_PreviewReplyText, attributes: [], media: [], peers: peers, associatedMessages: SimpleDictionary(), associatedMessageIds: [])
            
            let chatPresentationData = ChatPresentationData(theme: ChatPresentationThemeData(theme: item.componentTheme, wallpaper: item.wallpaper), fontSize: item.fontSize, strings: item.strings, dateTimeFormat: item.dateTimeFormat, disableAnimations: false)
            
            let item2: ChatMessageItem = ChatMessageItem(presentationData: chatPresentationData, account: item.account, chatLocation: .peer(peerId), associatedData: ChatMessageItemAssociatedData(automaticDownloadPeerType: .contact, automaticDownloadNetworkType: .cellular, isRecentActions: false), controllerInteraction: controllerInteraction, content: .message(message: Message(stableId: 1, stableVersion: 0, id: MessageId(peerId: peerId, namespace: 0, id: 1), globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, timestamp: 66000, flags: [.Incoming], tags: [], globalTags: [], localTags: [], forwardInfo: nil, author: nil, text: item.strings.Appearance_PreviewIncomingText, attributes: [ReplyMessageAttribute(messageId: replyMessageId)], media: [], peers: peers, associatedMessages: messages, associatedMessageIds: []), read: true, selection: .none, isAdmin: false), disableDate: true)
            let item1: ChatMessageItem = ChatMessageItem(presentationData: chatPresentationData, account: item.account, chatLocation: .peer(peerId), associatedData: ChatMessageItemAssociatedData(automaticDownloadPeerType: .contact, automaticDownloadNetworkType: .cellular, isRecentActions: false), controllerInteraction: controllerInteraction, content: .message(message: Message(stableId: 2, stableVersion: 0, id: MessageId(peerId: peerId, namespace: 0, id: 2), globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, timestamp: 66001, flags: [], tags: [], globalTags: [], localTags: [], forwardInfo: nil, author: TelegramUser(id: item.account.peerId, accessHash: nil, firstName: "", lastName: "", username: nil, phone: nil, photo: [], botInfo: nil, restrictionInfo: nil, flags: []), text: item.strings.Appearance_PreviewOutgoingText, attributes: [], media: [], peers: peers, associatedMessages: messages, associatedMessageIds: []), read: true, selection: .none, isAdmin: false), disableDate: true)
            
            var node1: ListViewItemNode?
            if let current = currentNode1 {
                node1 = current
                item1.updateNode(async: { $0() }, node: { return current }, params: params, previousItem: nil, nextItem: nil, animation: .None, completion: { (layout, apply) in
                    let nodeFrame = CGRect(origin: current.frame.origin, size: CGSize(width: layout.size.width, height: layout.size.height))
                    
                    current.contentSize = layout.contentSize
                    current.insets = layout.insets
                    current.frame = nodeFrame
                    
                    apply()
                })
            } else {
                item1.nodeConfiguredForParams(async: { $0() }, params: params, previousItem: nil, nextItem: nil, completion: { node, apply in
                    node1 = node
                    apply().1()
                })
            }
            
            var node2: ListViewItemNode?
            if let current = currentNode2 {
                node2 = current
                item2.updateNode(async: { $0() }, node: { return current }, params: params, previousItem: nil, nextItem: nil, animation: .None, completion: { (layout, apply) in
                    let nodeFrame = CGRect(origin: current.frame.origin, size: CGSize(width: layout.size.width, height: layout.size.height))
                    
                    current.contentSize = layout.contentSize
                    current.insets = layout.insets
                    current.frame = nodeFrame
                    
                    apply()
                })
            } else {
                item2.nodeConfiguredForParams(async: { $0() }, params: params, previousItem: nil, nextItem: nil, completion: { node, apply in
                    node2 = node
                    apply().1()
                })
            }
            
            var contentSize = CGSize(width: params.width, height: 4.0 + 4.0)
            if let node1 = node1 {
                contentSize.height += node1.frame.size.height
            }
            if let node2 = node2 {
                contentSize.height += node2.frame.size.height
            }
            insets = itemListNeighborsGroupedInsets(neighbors)
            
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size
            
            return (layout, { [weak self] in
                if let strongSelf = self {
                    strongSelf.item = item
                    
                    strongSelf.containerNode.frame = CGRect(origin: CGPoint(), size: contentSize)
                    
                    var topOffset: CGFloat = 4.0
                    if let node1 = node1 {
                        strongSelf.messageNode1 = node1
                        if node1.supernode == nil {
                            strongSelf.containerNode.addSubnode(node1)
                        }
                        node1.frame = CGRect(origin: CGPoint(x: 0.0, y: topOffset), size: node1.frame.size)
                        topOffset += node1.frame.size.height
                    }
                    
                    if let node2 = node2 {
                        strongSelf.messageNode2 = node2
                        if node2.supernode == nil {
                            strongSelf.containerNode.addSubnode(node2)
                        }
                        node2.frame = CGRect(origin: CGPoint(x: 0.0, y: topOffset), size: node2.frame.size)
                        topOffset += node2.frame.size.height
                    }
                    
                    if let updatedBackgroundImage = updatedBackgroundImage {
                        strongSelf.backgroundNode.image = updatedBackgroundImage
                    }
                    strongSelf.topStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                    strongSelf.bottomStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                    
                    if strongSelf.backgroundNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.backgroundNode, at: 0)
                    }
                    if strongSelf.topStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.topStripeNode, at: 1)
                    }
                    if strongSelf.bottomStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.bottomStripeNode, at: 2)
                    }
                    switch neighbors.top {
                        case .sameSection(false):
                            strongSelf.topStripeNode.isHidden = true
                        default:
                            strongSelf.topStripeNode.isHidden = false
                    }
                    let bottomStripeInset: CGFloat
                    let bottomStripeOffset: CGFloat
                    switch neighbors.bottom {
                        case .sameSection(false):
                            bottomStripeInset = 0.0
                            bottomStripeOffset = -separatorHeight
                        default:
                            bottomStripeInset = 0.0
                            bottomStripeOffset = 0.0
                    }
                    strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: params.width, height: contentSize.height + min(insets.top, separatorHeight) + min(insets.bottom, separatorHeight)))
                    strongSelf.topStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: layoutSize.width, height: separatorHeight))
                    strongSelf.bottomStripeNode.frame = CGRect(origin: CGPoint(x: bottomStripeInset, y: contentSize.height + bottomStripeOffset), size: CGSize(width: layoutSize.width - bottomStripeInset, height: separatorHeight))
                }
            })
        }
    }
    
    override func animateInsertion(_ currentTimestamp: Double, duration: Double, short: Bool) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
}
