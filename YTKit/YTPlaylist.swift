//
//  YTPlaylist.swift
//  YTKit
//
//  Created by Carlos Grossi on 1/8/16.
//  Copyright © 2016 Carlos Grossi. All rights reserved.
//

import Foundation

public class YTPlaylist: YTAPI {
    
    public var etag:String?
    public var playlistId:String?
    public var totalResults:Int?
    public var resultsPerPage:Int?
    public var nextPageToken:String?
    public var prevPageToken:String?
    public var items:[YTVideo] = []
    
    var channels:[String:YTChannel] = [:]
    
    public func getPlaylistItems(part:String = "snippet", playlistId:String, pageToken:String?, completitionHandler:()->()) {
        guard let url = getPlaylistItemsURL(part, playlistId:playlistId , pageToken:pageToken) else { return }
        self.playlistId = playlistId
        getPlaylistItems(url, completitionHandler:completitionHandler)
    }
    
    public func getVideosDetails(part:String = "snippet", videosId:String, pageToken:String?, completitionHandler:()->()) {
        guard let url = getVideosDetailsURL(part, videosId: videosId, pageToken: pageToken) else { return }
        getVideosDetails(url, completitionHandler: completitionHandler)
    }
    
    public func loadNextPage(completitionHandler:()->()) {
        guard let playlistId = self.playlistId else { completitionHandler(); return }
        guard let pageToken = self.nextPageToken else { completitionHandler(); return }
        getPlaylistItems(playlistId: playlistId, pageToken: pageToken, completitionHandler: completitionHandler)
    }
    
    // MARK: - Private Methods
    private func getPlaylistItemsURL(part:String, playlistId:String, pageToken:String?) -> NSURL? {
        let pgToken:String = pageToken == nil ? "" : pageToken!
        return NSURL(string: APIConstants.playlistItemsURL, args: [part, playlistId, pgToken, apiKey])
    }
    
    private func getVideosDetailsURL(part:String, videosId:String, pageToken:String?) -> NSURL? {
        let pgToken:String = pageToken == nil ? "" : pageToken!
        return NSURL(string: APIConstants.videosListURL, args: [part, videosId, pgToken, apiKey])
    }
    
    private func getPlaylistItems(url:NSURL, completitionHandler:()->()) {
        NSURLSession.urlSessionDataTaskWithURL(url) { (data, response, error) in
            NSURLSession.validateURLSessionDataTask(data, response: response, error: error, completitionHandler: { (data, error) in
                self.getPlaylistItems(NSJSONSerialization.serializeDataToDictionary(data), completitionHandler: completitionHandler)
            })
        }
    }
    
    private func getVideosDetails(url:NSURL, completitionHandler:()->()) {
        NSURLSession.urlSessionDataTaskWithURL(url) { (data, response, error) in
            NSURLSession.validateURLSessionDataTask(data, response: response, error: error, completitionHandler: { (data, error) in
                self.getVideosDetails(NSJSONSerialization.serializeDataToDictionary(data), completitionHandler: completitionHandler)
            })
        }
    }
    
    private func getPlaylistItems(playlistDictionary:NSDictionary?, completitionHandler:()->()) {
        guard let playlistDictionary = playlistDictionary else { return }
        
        etag = playlistDictionary.valueForKeyPath("etag") as? String
        totalResults = playlistDictionary.valueForKeyPath("pageInfo.totalResults") as? Int
        resultsPerPage = playlistDictionary.valueForKeyPath("pageInfo.resultsPerPage") as? Int
        nextPageToken = playlistDictionary.valueForKeyPath("nextPageToken") as? String
        prevPageToken = playlistDictionary.valueForKeyPath("prevPageToken") as? String
        
        if let playlistVideos = playlistDictionary.valueForKeyPath("items") as? NSArray {
            var videoIds = ""
            
            for playlistVideo in playlistVideos {
                guard let videoId = playlistVideo.valueForKeyPath("snippet.resourceId.videoId") as? String else { continue }
                videoIds = videoIds.stringByAppendingString(videoId).stringByAppendingString(",")
            }
            
            videoIds = String(videoIds.characters.dropLast())
            getVideosDetails(videosId: videoIds, pageToken: nil, completitionHandler: {
                completitionHandler()
            })
        }
    }
    
    private func getVideosDetails(videosDictionary:NSDictionary?, completitionHandler:()->()) {
        guard let videosDictionary = videosDictionary else { return }
        guard let items = videosDictionary.valueForKeyPath("items") as? NSArray else { return }
        
        var channelIds:[String] = []
        
        for item in items {
            guard let item = item as? NSDictionary else { continue }
            let video = YTVideo()
            video.videoId = item.valueForKeyPath("id") as? String
            video.channelId = item.valueForKeyPath("snippet.channelId") as? String
            video.channelName = item.valueForKeyPath("snippet.channelTitle") as? String
            video.videoTitle = item.valueForKeyPath("snippet.title") as? String
            video.videoDescription = item.valueForKeyPath("snippet.description") as? String
            video.videoDuration = item.valueForKeyPath("snippet.description") as? String
            
            if let publishedAt = item.valueForKeyPath("snippet.publishedAt") as? String {
                let posix = NSLocale(localeIdentifier: "en_US_POSIX")
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                dateFormatter.locale = posix
                video.publishedAt = dateFormatter.dateFromString(publishedAt)
            }
            
            video.defaultThumbnail = getThumbnailInfo(item, keyPath: "snippet.thumbnails.default")
            video.highThumbnail = getThumbnailInfo(item, keyPath: "snippet.thumbnails.high")
            video.mediumThumbnail = getThumbnailInfo(item, keyPath: "snippet.thumbnails.medium")
            video.standardThumbnail = getThumbnailInfo(item, keyPath: "snippet.thumbnails.standard")
            video.maxresThumbnail = getThumbnailInfo(item, keyPath: "snippet.thumbnails.maxres")
            
            if let channelId = video.channelId {
                if let channel = channels[channelId] {
                    video.channel = channel
                } else {
                    channelIds.append(channelId)
                }
            }
            
            self.items.append(video)
        }
        
        channelIds.removeDuplicates()        
        let ytChannels = YTChannels(apiKey: super.apiKey)
        
        ytChannels.getChannels(channelsIds: channelIds, pageToken: nil) {
            for item in self.items {
                guard item.channel == nil else { continue }
                guard let channelId = item.channelId else { continue }
                guard let channel = (ytChannels.items.filter{ $0.id == channelId }.first) else { continue }
                
                item.channel = channel
                self.channels.updateValue(channel, forKey: channelId)
            }
            completitionHandler()
        }
    }
    
    private func getThumbnailInfo(playlistVideo:NSDictionary, keyPath:String) -> YTVideo.Thumbnail? {
        if let thumbnail = playlistVideo.valueForKeyPath(keyPath) as? NSDictionary {
            let height = thumbnail.valueForKeyPath("height") as? Int
            let width = thumbnail.valueForKeyPath("width") as? Int
            let url = thumbnail.valueForKeyPath("url") as? String
            
            return YTVideo.Thumbnail(height: height, width: width, url: url)
        }
        return nil
    }
    
}
