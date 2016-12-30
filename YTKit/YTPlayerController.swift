//
//  YTPlayerController.swift
//  YTKit
//
//  Created by Carlos Grossi on 11/7/16.
//  Copyright © 2016 Carlos Grossi. All rights reserved.
//

import ExtensionKit

// MARK: - YTPlayerControllerDelegate Protocol
@objc public protocol YTPlayerControllerDelegate {
    @objc optional func playerViewDidBecomeReady(_ playerView: YTPlayerView)
    @objc optional func playerView(_ playerView: YTPlayerView!, didPlayTime playTime: Float)
    @objc optional func playerView(_ playerView: YTPlayerView!, receivedError error: YTPlayerError)
    @objc optional func playerView(_ playerView: YTPlayerView!, didChangeToState state: YTPlayerState)
    @objc optional func playerView(_ playerView: YTPlayerView!, didChangeToQuality quality: YTPlaybackQuality)
}

// MARK: - YTPlayerController
open class YTPlayerController: NSObject, YTPlayerViewDelegate {
    
    open var playerView:YTPlayerView?
    
    open static let sharedController = YTPlayerController()
    open var delegate:YTPlayerControllerDelegate?
    open var videoID:String?
    open var playerParameters:[AnyHashable: Any]
    
    // MARK: - Initializers
    override init() {
        playerParameters = [:]
        super.init()
    }
    
    convenience init(videoID:String) {
        self.init()
        self.videoID = videoID
        self.playerParameters = [:]
    }
    
    // MARK: - Methods
    open func loadVideoUnderContainerView(_ containerView:UIView, withSuggestedPlaybackQuality suggestedPlaybackQuality:YTPlaybackQuality) {
        playerView = YTPlayerView(frame: CGRect(x: 0, y: 0, width: containerView.frame.width, height: containerView.frame.height))
        playerView?.backgroundColor = UIColor.clear
        
        guard let localPlayerView = playerView else { return }
        
        localPlayerView.delegate = self
        localPlayerView.load(withVideoId: videoID, playerVars: playerParameters)
        localPlayerView.setPlaybackQuality(suggestedPlaybackQuality)
        
        containerView.addSubview(localPlayerView)
    }
    
    open func loadVideoID(_ videoID:String) {
        self.videoID = videoID
        playerView?.load(withVideoId: self.videoID)
    }
    
    open func unloadVideo() {
        playerView?.clearVideo()
        playerView?.removeWebView()
        playerView?.removeFromSuperview()
    }
    
    // MARK: - YTPlayerViewDelegate
    @objc open func playerViewDidBecomeReady(_ playerView: YTPlayerView!) {
        delegate?.playerViewDidBecomeReady?(playerView)
    }
    
    @objc open func playerView(_ playerView: YTPlayerView!, didPlayTime playTime: Float) {
        delegate?.playerView?(playerView, didPlayTime: playTime)
    }
    
    @objc open func playerView(_ playerView: YTPlayerView!, receivedError error: YTPlayerError) {
        delegate?.playerView?(playerView, receivedError: error)
    }
    
    @objc open func playerView(_ playerView: YTPlayerView!, didChangeTo state: YTPlayerState) {
        delegate?.playerView?(playerView, didChangeToState: state)
    }
    
    @objc open func playerView(_ playerView: YTPlayerView!, didChangeTo quality: YTPlaybackQuality) {
        delegate?.playerView?(playerView, didChangeToQuality: quality)
    }
}
