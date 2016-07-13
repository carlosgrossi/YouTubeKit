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
    optional func playerViewDidBecomeReady(playerView: YTPlayerView)
    optional func playerView(playerView: YTPlayerView!, didPlayTime playTime: Float)
    optional func playerView(playerView: YTPlayerView!, receivedError error: YTPlayerError)
    optional func playerView(playerView: YTPlayerView!, didChangeToState state: YTPlayerState)
    optional func playerView(playerView: YTPlayerView!, didChangeToQuality quality: YTPlaybackQuality)
}

// MARK: - YTPlayerController
public class YTPlayerController: NSObject, YTPlayerViewDelegate {
    
    private var playerView:YTPlayerView?
    
    public static let sharedController = YTPlayerController()
    public var delegate:YTPlayerControllerDelegate?
    public var videoID:String?
    public var playerParameters:[NSObject : AnyObject]
    
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
    public func loadVideoUnderContainerView(containerView:UIView, withSuggestedPlaybackQuality suggestedPlaybackQuality:YTPlaybackQuality) {
        playerView = YTPlayerView(frame: CGRectMake(0, 0, containerView.frame.width, containerView.frame.height))
        
        guard let localPlayerView = playerView else { return }
        
        containerView.addSubview(localPlayerView)
        containerView.setupStandardConstraintsForSubview(localPlayerView)
        
        localPlayerView.delegate = self
        localPlayerView.loadWithVideoId(videoID, playerVars: playerParameters)
        localPlayerView.setPlaybackQuality(suggestedPlaybackQuality)
    }
    
    public func loadVideoID(videoID:String) {
        self.videoID = videoID
        playerView?.loadWithVideoId(self.videoID)
    }
    
    public func unloadVideo() {
        playerView?.clearVideo()
        playerView?.removeWebView()
        playerView?.removeFromSuperview()
    }
    
    // MARK: - YTPlayerViewDelegate
    @objc public func playerViewDidBecomeReady(playerView: YTPlayerView!) {
        delegate?.playerViewDidBecomeReady?(playerView)
    }
    
    @objc public func playerView(playerView: YTPlayerView!, didPlayTime playTime: Float) {
        delegate?.playerView?(playerView, didPlayTime: playTime)
    }
    
    @objc public func playerView(playerView: YTPlayerView!, receivedError error: YTPlayerError) {
        delegate?.playerView?(playerView, receivedError: error)
    }
    
    @objc public func playerView(playerView: YTPlayerView!, didChangeToState state: YTPlayerState) {
        delegate?.playerView?(playerView, didChangeToState: state)
    }
    
    @objc public func playerView(playerView: YTPlayerView!, didChangeToQuality quality: YTPlaybackQuality) {
        delegate?.playerView?(playerView, didChangeToQuality: quality)
    }
}
