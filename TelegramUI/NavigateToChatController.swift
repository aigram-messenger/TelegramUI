import Foundation
import Display
import TelegramCore
import Postbox

public enum NavigateToChatKeepStack {
    case `default`
    case always
    case never
}

public func navigateToChatController(navigationController: NavigationController, chatController: ChatController? = nil, account: Account, chatLocation: ChatLocation, messageId: MessageId? = nil, botStart: ChatControllerInitialBotStart? = nil, keepStack: NavigateToChatKeepStack = .default, purposefulAction: (() -> Void)? = nil, animated: Bool = true, showsUnreadCountOnBackButton: Bool = true, completion: @escaping () -> Void = {}) {
    var found = false
    var isFirst = true
    for controller in navigationController.viewControllers.reversed() {
        if let controller = controller as? ChatController, controller.chatLocation == chatLocation {
            if let messageId = messageId {
                controller.purposefulAction = purposefulAction
                controller.navigateToMessage(messageLocation: .id(messageId), animated: isFirst, completion: { [weak navigationController, weak controller] in
                    if let navigationController = navigationController, let controller = controller {
                        let _ = navigationController.popToViewController(controller, animated: animated)
                    }
                })
            } else {
                let _ = navigationController.popToViewController(controller, animated: animated)
            }
            completion()
            found = true
            break
        }
        isFirst = false
    }
    
    if !found {
        let controller: ChatController
        if let chatController = chatController {
            controller = chatController
        } else {
            controller = ChatController(account: account, chatLocation: chatLocation, messageId: messageId, botStart: botStart)
        }
        controller.purposefulAction = purposefulAction
        controller.showsUnreadCountOnBackButton = showsUnreadCountOnBackButton
        let resolvedKeepStack: Bool
        switch keepStack {
            case .default:
                resolvedKeepStack = account.telegramApplicationContext.immediateExperimentalUISettings.keepChatNavigationStack
            case .always:
                resolvedKeepStack = true
            case .never:
                resolvedKeepStack = false
        }
        if resolvedKeepStack {
            navigationController.pushViewController(controller, completion: completion)
        } else {
            navigationController.replaceAllButRootController(controller, animated: animated, completion: completion)
        }
    }
}

private func findOpaqueLayer(rootLayer: CALayer, layer: CALayer) -> Bool {
    if layer.isHidden || layer.opacity < 0.8 {
        return false
    }
    
    if !layer.isHidden, let backgroundColor = layer.backgroundColor, backgroundColor.alpha > 0.8 {
        let coveringRect = layer.convert(layer.bounds, to: rootLayer)
        let intersection = coveringRect.intersection(rootLayer.bounds)
        let intersectionArea = intersection.width * intersection.height
        let rootArea = rootLayer.bounds.width * rootLayer.bounds.height
        if !rootArea.isZero && intersectionArea / rootArea > 0.8 {
            return true
        }
    }
    
    if let sublayers = layer.sublayers {
        for sublayer in sublayers {
            if findOpaqueLayer(rootLayer: rootLayer, layer: sublayer) {
                return true
            }
        }
    }
    return false
}

public func isInlineControllerForChatNotificationOverlayPresentation(_ controller: ViewController) -> Bool {
    if controller is InstantPageController {
        return true
    }
    return false
}

public func isOverlayControllerForChatNotificationOverlayPresentation(_ controller: ViewController) -> Bool {
    if controller is GalleryController || controller is AvatarGalleryController || controller is ThemeGalleryController || controller is InstantPageGalleryController || controller is InstantVideoController {
        return true
    }
    
    if controller.isNodeLoaded {
        if let backgroundColor = controller.displayNode.backgroundColor, !backgroundColor.isEqual(UIColor.clear) {
            return true
        }
        
        if findOpaqueLayer(rootLayer: controller.view.layer, layer: controller.view.layer) {
            return true
        }
    }
    
    return false
}
