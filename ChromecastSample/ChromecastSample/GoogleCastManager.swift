//
//  GoogleCastManager.swift
//  PlayerSDK-Demo
//
//  Created by Eliza Sapir on 12/04/2017.
//  Copyright © 2017 Kaltura. All rights reserved.
//

import UIKit
import GoogleCast
import PlayKit

protocol GoogleCastManagerDelegate {
    func castManagerDidStartSession(sender:GoogleCastManager)
    func castManagerDidEndSession(sender:GoogleCastManager)
    func castManagerDidStartMediaSession(sender:GoogleCastManager)
    func castManagerDidResumeSession(sender:GoogleCastManager)
}

class GoogleCastManager: NSObject,
    GCKLoggerDelegate,
    GCKRemoteMediaClientListener,
    GCKSessionManagerListener,
    GCKRemoteMediaClientAdInfoParserDelegate,
    GCKRequestDelegate {
    
    public static let sharedInstance = GoogleCastManager()
    public var delegate: GoogleCastManagerDelegate? = nil
    
    // MARK - Setup
    public func setup(applicationId:String){
        let option: GCKCastOptions = GCKCastOptions(receiverApplicationID: applicationId)
        GCKCastContext.setSharedInstanceWith(option)
        GCKLogger.sharedInstance().delegate  = self
        GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true
        GCKCastContext.sharedInstance().sessionManager.add(self)
    }
    
    // MARK : Getters
    public func isConnected() -> Bool {
        return (GCKCastContext.sharedInstance().sessionManager.currentCastSession != nil)
    }
    
    // MARK - Handle UI
    public func showExpandedControl() -> Void {
        GCKCastContext.sharedInstance().presentDefaultExpandedMediaControls()
        
    }
    
    public func embedRootViewController(viewcontroller: UIViewController) -> GCKUICastContainerViewController {
        let castController: GCKUICastContainerViewController = GCKCastContext.sharedInstance().createCastContainerController(for: viewcontroller)
        castController.miniMediaControlsItemEnabled = true
        return castController
    }
    
    // MARK : Cast
    public func cast(appending:Bool)  {
        
        let customData = self.customData(_title: "Folger's coffee", _subtitle: "Smucker Company", _image: URL(string: "http://cfvod.kaltura.com/p/243342/sp/24334200/thumbnail/entry_id/0_uka1msg4/version/100007/width/1200/hight/780")!, _width: 780, _height: 1200)
        
        
        var media: GCKMediaInformation? = nil
        do {
            media = try OVPCastBuilder()
            .set(streamType: BasicCastBuilder.StreamType.vod)
            .set(ks: "")
            .set(contentId: "0_uka1msg4")
            .set(adTagURL: "http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=xml_vmap1&unviewed_position_start=1&cust_params=sample_ar%3Dpremidpost&cmsid=496&vid=short_onecue&correlator=")
            .set(webPlayerURL: "")
            .set(uiconfID: "21099702")
            .set(partnerID: "243342")
            .set(metaData: customData)
            .build()
        
            if let m = media {
                self.load(mediaInformation: m, appending: appending)
            }
            
        }catch{
            print(error)
        }
    }
    
    private func customData(_title: String?, _subtitle: String?, _image:URL, _width: Int, _height: Int) ->  GCKMediaMetadata {
        
        let metaData = GCKMediaMetadata(metadataType: GCKMediaMetadataType.movie)
        if let title = _title {
            metaData.setString(title, forKey: kGCKMetadataKeyTitle)
        }
        
        if let subtitle = _subtitle {
            metaData.setString(subtitle, forKey: kGCKMetadataKeySubtitle)
        }
        
        metaData.addImage(GCKImage(url: _image , width: _width , height: _height))
        
        return metaData
    }
    
    // MARK : Cast item
    private func load(mediaInformation:GCKMediaInformation, appending: Bool) -> Void {
        let session =  GCKCastContext.sharedInstance().sessionManager.currentCastSession
        if let currentSession = session,  let remoteMediaClient = currentSession.remoteMediaClient {
            
            let builder = GCKMediaQueueItemBuilder()

            builder.mediaInformation = mediaInformation
            builder.autoplay = true
            // TODO:: remove/ ask product
            builder.preloadTime = 0
            
            let item = builder.build()
            
            if (remoteMediaClient.mediaStatus != nil && appending) {
                //Toast.displayMessage("Added \(mediaInformation.metadata?.string(forKey: kGCKMetadataKeyTitle)) to queue.", forTimeInterval: 3, in: (UIApplication.shared.delegate?.window)!)
                let request = remoteMediaClient.queueInsert(item, beforeItemWithID: kGCKMediaQueueInvalidItemID)
                request.delegate = self
            } else {
                var repeatMode = GCKMediaRepeatMode.off
                
                if let mediaStatus = remoteMediaClient.mediaStatus {
                    repeatMode = mediaStatus.queueRepeatMode
                }
                
                let request = remoteMediaClient.queueLoad([item], start:0, playPosition:0, repeatMode: repeatMode, customData: nil)
                request.delegate = self
            }

            remoteMediaClient.add(self)
            remoteMediaClient.adInfoParserDelegate = CastAdInfoParser.shared
        }
    }

    // MARK: - LoggerDelegate methods
    func logMessage(_ message: String, fromFunction function: String){
        print("GoogleCast:")
        print("message: \(message)")
        print("method:\(function)")
    }
    
    // MARK: - RemoteMediaClientListener
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?){
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didStartMediaSessionWithID sessionID: Int){
        self.delegate?.castManagerDidStartMediaSession(sender: self)
    }
    
    // MARK - SessionManagerListener
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession){
        self.delegate?.castManagerDidStartSession(sender: self)
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?){
        self.delegate?.castManagerDidEndSession(sender: self)
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        self.delegate?.castManagerDidResumeSession(sender: self)
    }
    
    // MARK: GCKRequestDelegate
    func requestDidComplete(_ request: GCKRequest) {
        print("requestDidComplete::", request)
    }
    
    func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        print("request::", request, "didFailWithError", error.description)
    }
}



