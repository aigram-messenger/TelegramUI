import Foundation
import AsyncDisplayKit
import TelegramCore
import Postbox

func inputNodeForChatPresentationIntefaceState(_ chatPresentationInterfaceState: ChatPresentationInterfaceState, account: Account, currentNode: ChatInputNode?, interfaceInteraction: ChatPanelInterfaceInteraction?, inputMediaNode: ChatMediaInputNode?, controllerInteraction: ChatControllerInteraction, inputPanelNode: ChatInputPanelNode?) -> ChatInputNode? {
    if !(inputPanelNode is ChatTextInputPanelNode) {
        return nil
    }
    switch chatPresentationInterfaceState.inputMode {
        case .media:
            if let currentNode = currentNode as? ChatMediaInputNode {
                return currentNode
            } else if let inputMediaNode = inputMediaNode {
                return inputMediaNode
            } else {
                var peerId: PeerId?
                if case let .peer(id) = chatPresentationInterfaceState.chatLocation {
                    peerId = id
                }
                let inputNode = ChatMediaInputNode(account: account, peerId: peerId, controllerInteraction: controllerInteraction, theme: chatPresentationInterfaceState.theme, strings: chatPresentationInterfaceState.strings, gifPaneIsActiveUpdated: { [weak interfaceInteraction] value in
                    if let interfaceInteraction = interfaceInteraction {
                        interfaceInteraction.updateInputModeAndDismissedButtonKeyboardMessageId { state in
                            if case let .media(_, expanded) = state.inputMode {
                                if value {
                                    return (.media(mode: .gif, expanded: expanded), nil)
                                } else {
                                    return (.media(mode: .other, expanded: expanded), nil)
                                }
                            } else {
                                return (state.inputMode, nil)
                            }
                        }
                    }
                })
                inputNode.interfaceInteraction = interfaceInteraction
                return inputNode
            }
        case .inputButtons:
            if let currentNode = currentNode as? ChatButtonKeyboardInputNode {
                return currentNode
            } else {
                let inputNode = ChatButtonKeyboardInputNode(account: account, controllerInteraction: controllerInteraction)
                inputNode.interfaceInteraction = interfaceInteraction
                return inputNode
            }
        case .suggestions(let messages):
            if let currentNode = currentNode as? ChatSuggestionsInputNode {
                currentNode.set(messages: messages)
                return currentNode
            } else {
                let inputNode = ChatSuggestionsInputNode(account: account, controllerInteraction: controllerInteraction)
                inputNode.interfaceInteraction = interfaceInteraction
                inputNode.set(messages: messages)
                return inputNode
        }
        case .none, .text:
            return nil
    }
}
