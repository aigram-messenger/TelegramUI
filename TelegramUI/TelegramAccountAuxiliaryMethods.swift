import Foundation
import TelegramCore
import Postbox

public let telegramAccountAuxiliaryMethods = AccountAuxiliaryMethods(updatePeerChatInputState: { interfaceState, inputState -> PeerChatInterfaceState? in
    if interfaceState == nil {
        return ChatInterfaceState().withUpdatedSynchronizeableInputState(inputState)
    } else if let interfaceState = interfaceState as? ChatInterfaceState {
        return interfaceState.withUpdatedSynchronizeableInputState(inputState)
    } else {
        return interfaceState
    }
}, fetchResource: { account, resource, range, _ in
    if let resource = resource as? VideoLibraryMediaResource {
        return fetchVideoLibraryMediaResource(resource: resource)
    } else if let resource = resource as? LocalFileVideoMediaResource {
        return fetchLocalFileVideoMediaResource(resource: resource)
    } else if let photoLibraryResource = resource as? PhotoLibraryMediaResource {
        return fetchPhotoLibraryResource(localIdentifier: photoLibraryResource.localIdentifier)
    } else if let mapSnapshotResource = resource as? MapSnapshotMediaResource {
        return fetchMapSnapshotResource(resource: mapSnapshotResource)
    } else if let resource = resource as? ExternalMusicAlbumArtResource {
        return fetchExternalMusicAlbumArtResource(account: account, resource: resource)
    }
    return nil
}, fetchResourceMediaReferenceHash: { resource in
    if let resource = resource as? VideoLibraryMediaResource {
        return fetchVideoLibraryMediaResourceHash(resource: resource)
    }
    return .single(nil)
})