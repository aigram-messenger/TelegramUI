import Foundation
import SwiftSignalKit
import TelegramCore
import Postbox
import Photos

private func appSpecificAssetCollection() -> Signal<PHAssetCollection, NoError> {
    return Signal { subscriber in
        let fetchOption = PHFetchOptions()
        let albumName = "Telegram"
        fetchOption.predicate = NSPredicate(format: "title == '" + albumName + "'")
        
        let fetchResult = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: fetchOption)
        
        if let collection = fetchResult.firstObject {
            subscriber.putNext(collection)
            subscriber.putCompletion()
        } else {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            }, completionHandler: { success, error in
                if let error = error {
                    Logger.shared.log("appSpecificAssetCollection", "error: \(error)")
                }
                
                if success {
                    let fetchResult = PHAssetCollection.fetchAssetCollections(
                        with: .album,
                        subtype: .albumRegular,
                        options: fetchOption)
                    if let collection = fetchResult.firstObject {
                        subscriber.putNext(collection)
                        subscriber.putCompletion()
                    }
                }
            })
        }
        
        return EmptyDisposable
    }
}

private final class DownloadedMediaStoreContext {
    private let queue: Queue
    private var disposable: Disposable?
    
    init(queue: Queue) {
        self.queue = queue
    }
    
    deinit {
        self.disposable?.dispose()
    }
    
    func start(postbox: Postbox, collection: Signal<PHAssetCollection, NoError>, storeSettings: Signal<AutomaticMediaDownloadSettings, NoError>, peerType: AutomaticMediaDownloadPeerType, timestamp: Int32, media: AnyMediaReference, completed: @escaping () -> Void) {
        var resource: TelegramMediaResource?
        if let image = media.media as? TelegramMediaImage {
            resource = largestImageRepresentation(image.representations)?.resource
        }
        if let resource = resource {
            self.disposable = (storeSettings
            |> map { storeSettings -> Bool in
                switch peerType {
                    case .contact:
                        if !storeSettings.peers.contacts.saveDownloadedPhotos {
                            return false
                        }
                    case .otherPrivate:
                        if !storeSettings.peers.otherPrivate.saveDownloadedPhotos {
                            return false
                        }
                    case .group:
                        if !storeSettings.peers.groups.saveDownloadedPhotos {
                            return false
                        }
                    case .channel:
                        if !storeSettings.peers.channels.saveDownloadedPhotos {
                            return false
                        }
                }
                return true
            }
            |> take(1)
            |> mapToSignal { store -> Signal<(PHAssetCollection, MediaResourceData), NoError> in
                if !store {
                    return .complete()
                } else {
                    return combineLatest(collection |> take(1), postbox.mediaBox.resourceData(resource))
                }
            }
            |> deliverOn(queue)).start(next: { collection, data in
                if !data.complete {
                    return
                }
                
                var filename: String?
                if let id = media.media.id {
                    filename = "telegram-photo-\(id.namespace)-\(id.id).jpg"
                }
                let creationDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
                
                let storeAsset: () -> Void = {
                    PHPhotoLibrary.shared().performChanges({
                        if let _ = media.media as? TelegramMediaImage {
                            if let fileData = try? Data(contentsOf: URL(fileURLWithPath: data.path)) {
                                if #available(iOSApplicationExtension 9.0, *) {
                                    let creationRequest = PHAssetCreationRequest.forAsset()
                                    let options = PHAssetResourceCreationOptions()
                                    if let filename = filename {
                                        options.originalFilename = filename
                                    }
                                    creationRequest.addResource(with: .photo, data: fileData, options: options)
                                    creationRequest.creationDate = creationDate
                                    let request = PHAssetCollectionChangeRequest(for: collection)
                                    if let placeholderForCreatedAsset = creationRequest.placeholderForCreatedAsset {
                                        request?.addAssets([placeholderForCreatedAsset] as NSArray)
                                    }
                                }
                            }
                        }
                    })
                }
                
                let options = PHFetchOptions()
                if #available(iOSApplicationExtension 9.0, *) {
                    options.fetchLimit = 11
                }
                
                options.predicate = NSPredicate(format: "creationDate == %@", creationDate as CVarArg)
                var alreadyStored = false
                let assets = PHAsset.fetchAssets(in: collection, options: options)
                assets.enumerateObjects({ asset, _, done in
                    if #available(iOSApplicationExtension 9.0, *) {
                        if let assetResource = PHAssetResource.assetResources(for: asset).first {
                            if assetResource.originalFilename == filename {
                                alreadyStored = true
                                done.pointee = true
                            }
                        }
                    }
                })
                
                if !alreadyStored {
                    storeAsset()
                }
                
                completed()
            })
        } else {
            completed()
        }
    }
}

private final class DownloadedMediaStoreManagerImpl {
    private let queue: Queue
    private let postbox: Postbox
    
    private var nextId: Int32 = 1
    private var storeContexts: [MediaId: DownloadedMediaStoreContext] = [:]
    
    private let appSpecificAssetCollectionValue: Promise<PHAssetCollection>
    private let storeSettings = Promise<AutomaticMediaDownloadSettings>()
    
    init(queue: Queue, postbox: Postbox) {
        self.queue = queue
        self.postbox = postbox
        
        self.appSpecificAssetCollectionValue = Promise(initializeOnFirstAccess: appSpecificAssetCollection())
        self.storeSettings.set(postbox.preferencesView(keys: [ApplicationSpecificPreferencesKeys.automaticMediaDownloadSettings])
        |> map { view -> AutomaticMediaDownloadSettings in
            if let settings = view.values[ApplicationSpecificPreferencesKeys.automaticMediaDownloadSettings] as? AutomaticMediaDownloadSettings {
                return settings
            } else {
                return .defaultSettings
            }
        })
    }
    
    deinit {
        assert(self.queue.isCurrent())
    }
    
    private func takeNextId() -> Int32 {
        let nextId = self.nextId
        self.nextId += 1
        return nextId
    }
    
    func store(_ media: AnyMediaReference, timestamp: Int32, peerType: AutomaticMediaDownloadPeerType) {
        guard let id = media.media.id else {
            return
        }
        if self.storeContexts[id] == nil {
            let context = DownloadedMediaStoreContext(queue: self.queue)
            self.storeContexts[id] = context
            let appSpecificAssetCollectionValue = self.appSpecificAssetCollectionValue
            context.start(postbox: self.postbox, collection: deferred { appSpecificAssetCollectionValue.get() }, storeSettings: self.storeSettings.get(), peerType: peerType, timestamp: timestamp, media: media, completed: { [weak self, weak context] in
                guard let strongSelf = self, let context = context else {
                    return
                }
                assert(strongSelf.queue.isCurrent())
                if strongSelf.storeContexts[id] === context {
                    strongSelf.storeContexts.removeValue(forKey: id)
                }
            })
        }
    }
}

final class DownloadedMediaStoreManager {
    private let queue = Queue()
    private let impl: QueueLocalObject<DownloadedMediaStoreManagerImpl>
    
    init(postbox: Postbox) {
        let queue = self.queue
        self.impl = QueueLocalObject(queue: queue, generate: {
            return DownloadedMediaStoreManagerImpl(queue: queue, postbox: postbox)
        })
    }
    
    func store(_ media: AnyMediaReference, timestamp: Int32, peerType: AutomaticMediaDownloadPeerType) {
        self.impl.with { impl in
            impl.store(media, timestamp: timestamp, peerType: peerType)
        }
    }
}

func storeDownloadedMedia(storeManager: DownloadedMediaStoreManager?, media: AnyMediaReference, peerType: AutomaticMediaDownloadPeerType) -> Signal<Never, NoError> {
    guard case let .message(message, _) = media, let timestamp = message.timestamp, let incoming = message.isIncoming, incoming, let secret = message.isSecret, !secret else {
        return .complete()
    }
    
    return Signal { [weak storeManager] subscriber in
        storeManager?.store(media, timestamp: timestamp, peerType: peerType)
        subscriber.putCompletion()
        return EmptyDisposable
    }
}
