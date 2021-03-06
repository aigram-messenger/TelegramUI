import Foundation
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit

import TelegramUIPrivateModule

final class CallControllerNode: ASDisplayNode {
    private let account: Account
    
    private let statusBar: StatusBar
    
    private var presentationData: PresentationData
    private var peer: Peer?
    private let debugInfo: Signal<(String, String), NoError>
    
    private let containerNode: ASDisplayNode
    
    private let imageNode: TransformImageNode
    private let dimNode: ASDisplayNode
    private let backButtonArrowNode: ASImageNode
    private let backButtonNode: HighlightableButtonNode
    private let statusNode: CallControllerStatusNode
    private let buttonsNode: CallControllerButtonsNode
    private var keyPreviewNode: CallControllerKeyPreviewNode?
    
    private var debugNode: CallDebugNode?
    
    private var keyTextData: (Data, String)?
    private let keyButtonNode: HighlightableButtonNode
    
    private var validLayout: (ContainerViewLayout, CGFloat)?
    
    var isMuted: Bool = false {
        didSet {
            self.buttonsNode.isMuted = self.isMuted
        }
    }
    
    private var shouldStayHiddenUntilConnection: Bool = false
    
    private var audioOutputState: ([AudioSessionOutput], currentOutput: AudioSessionOutput?)?
    private var callState: PresentationCallState?
    
    var toggleMute: (() -> Void)?
    var setCurrentAudioOutput: ((AudioSessionOutput) -> Void)?
    var beginAudioOuputSelection: (() -> Void)?
    var acceptCall: (() -> Void)?
    var endCall: (() -> Void)?
    var back: (() -> Void)?
    var dismissedInteractively: (() -> Void)?
    
    init(account: Account, presentationData: PresentationData, statusBar: StatusBar, debugInfo: Signal<(String, String), NoError>, shouldStayHiddenUntilConnection: Bool = false) {
        self.account = account
        self.presentationData = presentationData
        self.statusBar = statusBar
        self.debugInfo = debugInfo
        self.shouldStayHiddenUntilConnection = shouldStayHiddenUntilConnection
        
        self.containerNode = ASDisplayNode()
        if self.shouldStayHiddenUntilConnection {
            self.containerNode.alpha = 0.0
        }
        
        self.imageNode = TransformImageNode()
        self.imageNode.contentAnimations = [.subsequentUpdates]
        self.dimNode = ASDisplayNode()
        self.dimNode.isLayerBacked = true
        self.dimNode.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
        
        self.backButtonArrowNode = ASImageNode()
        self.backButtonArrowNode.displayWithoutProcessing = true
        self.backButtonArrowNode.displaysAsynchronously = false
        self.backButtonArrowNode.image = NavigationBarTheme.generateBackArrowImage(color: .white)
        self.backButtonNode = HighlightableButtonNode()
        
        self.statusNode = CallControllerStatusNode()
        self.buttonsNode = CallControllerButtonsNode(strings: self.presentationData.strings)
        self.keyButtonNode = HighlightableButtonNode()
        
        super.init()
        
        self.setViewBlock({
            return UITracingLayerView()
        })
        
        self.containerNode.backgroundColor = .black
        
        self.addSubnode(self.containerNode)
        
        self.backButtonNode.setTitle(presentationData.strings.Common_Back, with: Font.regular(17.0), with: .white, for: [])
        self.backButtonNode.hitTestSlop = UIEdgeInsets(top: -8.0, left: -20.0, bottom: -8.0, right: -8.0)
        self.backButtonNode.highligthedChanged = { [weak self] highlighted in
            if let strongSelf = self {
                if highlighted {
                    strongSelf.backButtonNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.backButtonArrowNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.backButtonNode.alpha = 0.4
                    strongSelf.backButtonArrowNode.alpha = 0.4
                } else {
                    strongSelf.backButtonNode.alpha = 1.0
                    strongSelf.backButtonArrowNode.alpha = 1.0
                    strongSelf.backButtonNode.layer.animateAlpha(from: 0.4, to: 1.0, duration: 0.2)
                    strongSelf.backButtonArrowNode.layer.animateAlpha(from: 0.4, to: 1.0, duration: 0.2)
                }
            }
        }
        
        self.containerNode.addSubnode(self.imageNode)
        self.containerNode.addSubnode(self.dimNode)
        self.containerNode.addSubnode(self.statusNode)
        self.containerNode.addSubnode(self.buttonsNode)
        self.containerNode.addSubnode(self.keyButtonNode)
        self.containerNode.addSubnode(self.backButtonArrowNode)
        self.containerNode.addSubnode(self.backButtonNode)
        
        self.buttonsNode.mute = { [weak self] in
            self?.toggleMute?()
        }
        
        self.buttonsNode.speaker = { [weak self] in
            self?.beginAudioOuputSelection?()
        }
        
        self.buttonsNode.end = { [weak self] in
            self?.endCall?()
        }
        
        self.buttonsNode.accept = { [weak self] in
            self?.acceptCall?()
        }
        
        self.keyButtonNode.addTarget(self, action: #selector(self.keyPressed), forControlEvents: .touchUpInside)
        
        self.backButtonNode.addTarget(self, action: #selector(self.backPressed), forControlEvents: .touchUpInside)
    }
    
    override func didLoad() {
        super.didLoad()
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(_:)))
        self.view.addGestureRecognizer(panRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:)))
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    func updatePeer(peer: Peer) {
        if !arePeersEqual(self.peer, peer) {
            self.peer = peer
            if let peerReference = PeerReference(peer), !peer.profileImageRepresentations.isEmpty {
                let representations: [(TelegramMediaImageRepresentation, MediaResourceReference)] = peer.profileImageRepresentations.map({ ($0, .avatar(peer: peerReference, resource: $0.resource)) })
                self.imageNode.setSignal(chatAvatarGalleryPhoto(account: self.account, representations: representations, autoFetchFullSize: true))
                self.dimNode.isHidden = false
            } else {
                self.imageNode.setSignal(callDefaultBackground())
                self.dimNode.isHidden = true
            }
            
            self.statusNode.title = peer.displayTitle
            
            if let (layout, navigationBarHeight) = self.validLayout {
                self.containerLayoutUpdated(layout, navigationBarHeight: navigationBarHeight, transition: .immediate)
            }
        }
    }
    
    func updateAudioOutputs(availableOutputs: [AudioSessionOutput], currentOutput: AudioSessionOutput?) {
        if self.audioOutputState?.0 != availableOutputs || self.audioOutputState?.1 != currentOutput {
            self.audioOutputState = (availableOutputs, currentOutput)
            self.updateButtonsMode()
        }
    }
    
    func updateCallState(_ callState: PresentationCallState) {
        self.callState = callState
        
        let statusValue: CallControllerStatusValue
        switch callState {
            case .waiting, .connecting:
                statusValue = .text(self.presentationData.strings.Call_StatusConnecting)
            case let .requesting(ringing):
                if ringing {
                    statusValue = .text(self.presentationData.strings.Call_StatusRinging)
                } else {
                    statusValue = .text(self.presentationData.strings.Call_StatusRequesting)
                }
            case .terminating:
                statusValue = .text(self.presentationData.strings.Call_StatusEnded)
            case let .terminated(reason):
                if let reason = reason {
                    switch reason {
                        case let .ended(type):
                            switch type {
                                case .busy:
                                    statusValue = .text(self.presentationData.strings.Call_StatusBusy)
                                case .hungUp, .missed:
                                    statusValue = .text(self.presentationData.strings.Call_StatusEnded)
                            }
                        case .error:
                            statusValue = .text(self.presentationData.strings.Call_StatusFailed)
                    }
                } else {
                    statusValue = .text(self.presentationData.strings.Call_StatusEnded)
                }
            case .ringing:
                statusValue = .text(self.presentationData.strings.Call_StatusIncoming)
            case let .active(timestamp, keyVisualHash):
                let strings = self.presentationData.strings
                statusValue = .timer({ value in
                    return strings.Call_StatusOngoing(value).0
                }, timestamp)
                if self.keyTextData?.0 != keyVisualHash {
                    let text = stringForEmojiHashOfData(keyVisualHash, 4)!
                    self.keyTextData = (keyVisualHash, text)
                    
                    self.keyButtonNode.setAttributedTitle(NSAttributedString(string: text, attributes: [NSAttributedStringKey.font: Font.regular(22.0), NSAttributedStringKey.kern: 2.5 as NSNumber]), for: [])
                    
                    let keyTextSize = self.keyButtonNode.measure(CGSize(width: 200.0, height: 200.0))
                    self.keyButtonNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
                    self.keyButtonNode.frame = CGRect(origin: self.keyButtonNode.frame.origin, size: keyTextSize)
                    
                    if let (layout, navigationBarHeight) = self.validLayout {
                        self.containerLayoutUpdated(layout, navigationBarHeight: navigationBarHeight, transition: .immediate)
                    }
                }
        }
        switch callState {
            case .terminated, .terminating:
                if !self.statusNode.alpha.isEqual(to: 0.5) {
                    self.statusNode.alpha = 0.5
                    self.buttonsNode.alpha = 0.5
                    self.keyButtonNode.alpha = 0.5
                    self.backButtonArrowNode.alpha = 0.5
                    self.backButtonNode.alpha = 0.5
                    
                    self.statusNode.layer.animateAlpha(from: 1.0, to: 0.5, duration: 0.25)
                    self.buttonsNode.layer.animateAlpha(from: 1.0, to: 0.5, duration: 0.25)
                    self.keyButtonNode.layer.animateAlpha(from: 1.0, to: 0.5, duration: 0.25)
                }
            default:
                if !self.statusNode.alpha.isEqual(to: 1.0) {
                    self.statusNode.alpha = 1.0
                    self.buttonsNode.alpha = 1.0
                    self.keyButtonNode.alpha = 1.0
                    self.backButtonArrowNode.alpha = 1.0
                    self.backButtonNode.alpha = 1.0
                }
        }
        if self.shouldStayHiddenUntilConnection {
            switch callState {
                case .connecting, .active:
                    self.containerNode.alpha = 1.0
                default:
                    break
            }
        }
        self.statusNode.status = statusValue
        
        self.updateButtonsMode()
    }
    
    private func updateButtonsMode() {
        guard let callState = self.callState else {
            return
        }
        
        switch callState {
            case .ringing:
                self.buttonsNode.updateMode(.incoming)
            default:
                var mode: CallControllerButtonsSpeakerMode = .none
                if let (availableOutputs, maybeCurrentOutput) = self.audioOutputState, let currentOutput = maybeCurrentOutput {
                    switch currentOutput {
                        case .builtin:
                            mode = .builtin
                        case .speaker:
                            mode = .speaker
                        case .headphones:
                            mode = .headphones
                        case .port:
                            mode = .bluetooth
                    }
                    if availableOutputs.count <= 1 {
                        mode = .none
                    }
                }
                self.buttonsNode.updateMode(.active(mode))
        }
    }
    
    func animateIn() {
        var bounds = self.bounds
        bounds.origin = CGPoint()
        self.bounds = bounds
        self.layer.removeAnimation(forKey: "bounds")
        self.statusBar.layer.removeAnimation(forKey: "opacity")
        self.containerNode.layer.removeAnimation(forKey: "opacity")
        self.containerNode.layer.removeAnimation(forKey: "scale")
        self.statusBar.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        if !self.shouldStayHiddenUntilConnection {
            self.containerNode.layer.animateScale(from: 1.04, to: 1.0, duration: 0.3)
            self.containerNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        }
    }
    
    func animateOut(completion: @escaping () -> Void) {
        self.statusBar.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false)
        if !self.shouldStayHiddenUntilConnection || self.containerNode.alpha > 0.0 {
            self.containerNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false)
            self.containerNode.layer.animateScale(from: 1.0, to: 1.04, duration: 0.3, removeOnCompletion: false, completion: { _ in
                completion()
            })
        } else {
            completion()
        }
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        self.validLayout = (layout, navigationBarHeight)
        
        transition.updateFrame(node: self.containerNode, frame: CGRect(origin: CGPoint(), size: layout.size))
        transition.updateFrame(node: self.dimNode, frame: CGRect(origin: CGPoint(), size: layout.size))
        
        if let keyPreviewNode = self.keyPreviewNode {
            transition.updateFrame(node: keyPreviewNode, frame: CGRect(origin: CGPoint(), size: layout.size))
            keyPreviewNode.updateLayout(size: layout.size, transition: .immediate)
        }
        
        transition.updateFrame(node: self.imageNode, frame: CGRect(origin: CGPoint(), size: layout.size))
        let arguments = TransformImageArguments(corners: ImageCorners(), imageSize: CGSize(width: 640.0, height: 640.0).aspectFilled(layout.size), boundingSize: layout.size, intrinsicInsets: UIEdgeInsets())
        let apply = self.imageNode.asyncLayout()(arguments)
        apply()
        
        let navigationOffset: CGFloat = max(20.0, layout.safeInsets.top)
        
        let backSize = self.backButtonNode.measure(CGSize(width: 320.0, height: 100.0))
        if let image = self.backButtonArrowNode.image {
            transition.updateFrame(node: self.backButtonArrowNode, frame: CGRect(origin: CGPoint(x: 10.0, y: navigationOffset + 11.0), size: image.size))
        }
        transition.updateFrame(node: self.backButtonNode, frame: CGRect(origin: CGPoint(x: 29.0, y: navigationOffset + 11.0), size: backSize))
        
        var statusOffset: CGFloat
        if layout.metrics.widthClass == .regular && layout.metrics.heightClass == .regular {
            if layout.size.height.isEqual(to: 1366.0) {
                statusOffset = 160.0
            } else {
                statusOffset = 120.0
            }
        } else {
            if layout.size.height.isEqual(to: 736.0) {
                statusOffset = 80.0
            } else if layout.size.width.isEqual(to: 320.0) {
                statusOffset = 60.0
            } else {
                statusOffset = 64.0
            }
        }
        
        statusOffset += layout.safeInsets.top
        
        let buttonsHeight: CGFloat = 75.0
        let buttonsOffset: CGFloat
        if layout.size.width.isEqual(to: 320.0) {
            if layout.size.height.isEqual(to: 480.0) {
                buttonsOffset = 60.0
            } else {
                buttonsOffset = 73.0
            }
        } else {
            buttonsOffset = 83.0
        }
        
        let statusHeight = self.statusNode.updateLayout(constrainedWidth: layout.size.width, transition: transition)
        transition.updateFrame(node: self.statusNode, frame: CGRect(origin: CGPoint(x: 0.0, y: statusOffset), size: CGSize(width: layout.size.width, height: statusHeight)))
        
        self.buttonsNode.updateLayout(constrainedWidth: layout.size.width, transition: transition)
        transition.updateFrame(node: self.buttonsNode, frame: CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - (buttonsOffset - 40.0) - buttonsHeight - layout.intrinsicInsets.bottom), size: CGSize(width: layout.size.width, height: buttonsHeight)))
        
        let keyTextSize = self.keyButtonNode.frame.size
        transition.updateFrame(node: self.keyButtonNode, frame: CGRect(origin: CGPoint(x: layout.size.width - keyTextSize.width - 8.0, y: navigationOffset + 8.0), size: keyTextSize))
        
        if let debugNode = self.debugNode {
            transition.updateFrame(node: debugNode, frame: CGRect(origin: CGPoint(), size: layout.size))
        }
    }
    
    @objc func keyPressed() {
        if self.keyPreviewNode == nil, let keyText = self.keyTextData?.1, let peer = self.peer {
            let keyPreviewNode = CallControllerKeyPreviewNode(keyText: keyText, infoText: self.presentationData.strings.Call_EmojiDescription(peer.compactDisplayTitle).0.replacingOccurrences(of: "%%", with: "%"), dismiss: { [weak self] in
                if let _ = self?.keyPreviewNode {
                    self?.backPressed()
                }
            })
            self.containerNode.insertSubnode(keyPreviewNode, aboveSubnode: self.dimNode)
            self.keyPreviewNode = keyPreviewNode
            
            if let (validLayout, _) = self.validLayout {
                keyPreviewNode.updateLayout(size: validLayout.size, transition: .immediate)
                
                self.keyButtonNode.isHidden = true
                keyPreviewNode.animateIn(from: self.keyButtonNode.frame, fromNode: self.keyButtonNode)
            }
        }
    }
    
    @objc func backPressed() {
        if let keyPreviewNode = self.keyPreviewNode {
            self.keyPreviewNode = nil
            keyPreviewNode.animateOut(to: self.keyButtonNode.frame, toNode: self.keyButtonNode, completion: { [weak self, weak keyPreviewNode] in
                self?.keyButtonNode.isHidden = false
                keyPreviewNode?.removeFromSupernode()
            })
        } else {
            self.back?()
        }
    }
    
    private var debugTapCounter: (Double, Int) = (0.0, 0)
    
    @objc func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            if let _ = self.keyPreviewNode {
                self.backPressed()
            } else {
                let point = recognizer.location(in: recognizer.view)
                if self.statusNode.frame.contains(point) {
                    let timestamp = CACurrentMediaTime()
                    if self.debugTapCounter.0 < timestamp - 0.75 {
                        self.debugTapCounter.0 = timestamp
                        self.debugTapCounter.1 = 0
                    }
                    
                    if self.debugTapCounter.0 >= timestamp - 0.75 {
                        self.debugTapCounter.0 = timestamp
                        self.debugTapCounter.1 += 1
                    }
                    
                    if self.debugTapCounter.1 >= 10 {
                        self.debugTapCounter.1 = 0
                        
                        self.presentDebugNode()
                    }
                }
            }
        }
    }
    
    private func presentDebugNode() {
        guard self.debugNode == nil else {
            return
        }
        
        let debugNode = CallDebugNode(signal: self.debugInfo)
        debugNode.dismiss = { [weak self] in
            if let strongSelf = self {
                strongSelf.debugNode?.removeFromSupernode()
                strongSelf.debugNode = nil
            }
        }
        self.addSubnode(debugNode)
        self.debugNode = debugNode
        
        if let (layout, navigationBarHeight) = self.validLayout {
            self.containerLayoutUpdated(layout, navigationBarHeight: navigationBarHeight, transition: .immediate)
        }
    }
    
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
            case .changed:
                let offset = recognizer.translation(in: self.view).y
                var bounds = self.bounds
                bounds.origin.y = -offset
                self.bounds = bounds
            case .ended:
                let velocity = recognizer.velocity(in: self.view).y
                if abs(velocity) < 100.0 {
                    var bounds = self.bounds
                    let previous = bounds
                    bounds.origin = CGPoint()
                    self.bounds = bounds
                    self.layer.animateBounds(from: previous, to: bounds, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring)
                } else {
                    var bounds = self.bounds
                    let previous = bounds
                    bounds.origin = CGPoint(x: 0.0, y: velocity > 0.0 ? -bounds.height: bounds.height)
                    self.bounds = bounds
                    self.layer.animateBounds(from: previous, to: bounds, duration: 0.15, timingFunction: kCAMediaTimingFunctionEaseOut, completion: { [weak self] _ in
                        self?.dismissedInteractively?()
                    })
                }
            case .cancelled:
                var bounds = self.bounds
                let previous = bounds
                bounds.origin = CGPoint()
                self.bounds = bounds
                self.layer.animateBounds(from: previous, to: bounds, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring)
            default:
                break
        }
    }
}

private func attributedStringForDebugInfo(_ info: String, version: String) -> NSAttributedString {
    guard !info.isEmpty else {
        return NSAttributedString(string: "")
    }
    
    var string = info
    string = "libtgvoip v\(version)\n" + string
    string = string.replacingOccurrences(of: "Remote endpoints: \n", with: "")
    string = string.replacingOccurrences(of: "Jitter ", with: "\nJitter ")
    string = string.replacingOccurrences(of: "Key fingerprint:\n", with: "Key fingerprint: ")
    
    let attributedString = NSMutableAttributedString(string: string, attributes: [NSAttributedStringKey.font: Font.monospace(15), NSAttributedStringKey.foregroundColor: UIColor.white])
    
    let titleStyle = NSMutableParagraphStyle()
    titleStyle.alignment = .center
    titleStyle.lineSpacing = 7.0

    let style = NSMutableParagraphStyle()
    style.lineHeightMultiple = 1.15
    
    let secondaryColor = UIColor(rgb: 0xa6a9a8)
    let activeColor = UIColor(rgb: 0xa0d875)
    
    let titleAttributes = [NSAttributedStringKey.font: Font.semiboldMonospace(17), NSAttributedStringKey.paragraphStyle: titleStyle]
    let nameAttributes = [NSAttributedStringKey.font: Font.semiboldMonospace(15), NSAttributedStringKey.foregroundColor: secondaryColor]
    let styleAttributes = [NSAttributedStringKey.paragraphStyle: style]
    let typeAttributes = [NSAttributedStringKey.foregroundColor: secondaryColor]
    let activeAttributes = [NSAttributedStringKey.font: Font.semiboldMonospace(15), NSAttributedStringKey.foregroundColor: activeColor]
    
    let range = string.startIndex ..< string.endIndex
    string.enumerateSubstrings(in: range, options: NSString.EnumerationOptions.byLines) { (line, range, _, _) in
        guard let line = line else {
            return
        }
        if range.lowerBound == string.startIndex {
            attributedString.addAttributes(titleAttributes, range: NSRange(range, in: string))
        }
        else {
            if let semicolonRange = line.range(of: ":") {
                if let bracketRange = line.range(of: "[") {
                    if let _ = line.range(of: "IN_USE") {
                        attributedString.addAttributes(activeAttributes, range: NSRange(range, in: string))
                    } else {
                        let offset = line.distance(from: line.startIndex, to: bracketRange.lowerBound)
                        let distance = line.distance(from: line.startIndex, to: line.endIndex)
                        attributedString.addAttributes(typeAttributes, range: NSRange(string.index(range.lowerBound, offsetBy: offset) ..< string.index(range.lowerBound, offsetBy: distance), in: string))
                    }
                } else {
                    attributedString.addAttributes(styleAttributes, range: NSRange(range, in: string))
                    
                    let offset = line.distance(from: line.startIndex, to: semicolonRange.upperBound)
                    attributedString.addAttributes(nameAttributes, range: NSRange(range.lowerBound ..< string.index(range.lowerBound, offsetBy: offset), in: string))
                }
            }
        }
    }
    
    return attributedString
}

final private class CallDebugNode: ASDisplayNode {
    private let disposable = MetaDisposable()
    
    private let dimNode: ASDisplayNode
    private let textNode: ASTextNode
    
    private let timestamp = CACurrentMediaTime()
    
    public var dismiss: (() -> Void)?
    
    init(signal: Signal<(String, String), NoError>) {
        self.dimNode = ASDisplayNode()
        self.dimNode.isLayerBacked = true
        self.dimNode.backgroundColor = UIColor(rgb: 0x26282c, alpha: 0.95)
        self.dimNode.isUserInteractionEnabled = false
        
        self.textNode = ASTextNode()
        self.textNode.isUserInteractionEnabled = false
        
        super.init()
        
        self.addSubnode(self.dimNode)
        self.addSubnode(self.textNode)
        
        self.disposable.set((signal
        |> deliverOnMainQueue).start(next: { [weak self] (version, info) in
            self?.update(info, version: version)
        }))
    }
    
    deinit {
        self.disposable.dispose()
    }
    
    override func didLoad() {
        super.didLoad()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:)))
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    private func update(_ info: String, version: String) {
        self.textNode.attributedText = attributedStringForDebugInfo(info, version: version)
        self.setNeedsLayout()
    }
    
    @objc func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if CACurrentMediaTime() - self.timestamp > 1.0 {
            self.dismiss?()
        }
    }
    
    override func layout() {
        super.layout()
        
        let size = self.bounds.size
        self.dimNode.frame = CGRect(origin: CGPoint(), size: CGSize(width: size.width, height: size.height))
        
        let textSize = textNode.measure(CGSize(width: size.width - 20.0, height: size.height))
        self.textNode.frame = CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - textSize.width) / 2.0), y: floorToScreenPixels((size.height - textSize.height) / 2.0)), size: textSize)
    }
}
