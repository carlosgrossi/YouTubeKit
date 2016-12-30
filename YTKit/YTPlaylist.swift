//
//  YTPlaylist.swift
//  YTKit
//
//  Created by Carlos Grossi on 1/8/16.
//  Copyright © 2016 Carlos Grossi. All rights reserved.
//

import Foundation

open class YTPlaylist: YTAPI {
    
    open var etag:String?
    open var playlistId:String?
    open var totalResults:Int?
    open var resultsPerPage:Int?
    open var nextPageToken:String?
    open var prevPageToken:String?
    open var items:[YTVideo] = []
    
    var channels:[String:YTChannel] = [:]
    
    open func getPlaylistItems(_ part:String = "snippet", playlistId:String, pageToken:String?, completitionHandler:@escaping ()->()) {
        guard let url = getPlaylistItemsURL(part, playlistId:playlistId , pageToken:pageToken) else { return }
        self.playlistId = playlistId
        getPlaylistItems(url, completitionHandler:completitionHandler)
    }
    
    open func getVideosDetails(_ part:String = "snippet", videosId:String, pageToken:String?, completitionHandler:@escaping ()->()) {
        guard let url = getVideosDetailsURL(part, videosId: videosId, pageToken: pageToken) else { return }
        getVideosDetails(url, completitionHandler: completitionHandler)
    }
    
    open func loadNextPage(_ completitionHandler:@escaping ()->()) {
        guard let playlistId = self.playlistId else { completitionHandler(); return }
        guard let pageToken = self.nextPageToken else { completitionHandler(); return }
        getPlaylistItems(playlistId: playlistId, pageToken: pageToken, completitionHandler: completitionHandler)
    }
    
    // MARK: - Private Methods
    fileprivate func getPlaylistItemsURL(_ part:String, playlistId:String, pageToken:String?) -> URL? {
        let pgToken:String = pageToken == nil ? "" : pageToken!
        return URL(string: APIConstants.playlistItemsURL, args: [part, playlistId, pgToken, apiKey])
    }
    
    fileprivate func getVideosDetailsURL(_ part:String, videosId:String, pageToken:String?) -> URL? {
        let pgToken:String = pageToken == nil ? "" : pageToken!
        return URL(string: APIConstants.videosListURL, args: [part, videosId, pgToken, apiKey])
    }
    
    fileprivate func getPlaylistItems(_ url:URL, completitionHandler:@escaping ()->()) {
        URLSession.urlSessionDataTaskWithURL(url) { (data, response, error) in
            URLSession.validateURLSessionDataTask(data, response: response, error: error as NSError?, completitionHandler: { (data, error) in
                self.getPlaylistItems(JSONSerialization.serializeDataToDictionary(data), completitionHandler: completitionHandler)
            })
        }
    }
    
    fileprivate func getVideosDetails(_ url:URL, completitionHandler:@escaping ()->()) {
        URLSession.urlSessionDataTaskWithURL(url) { (data, response, error) in
            URLSession.validateURLSessionDataTask(data, response: response, error: error as NSError?, completitionHandler: { (data, error) in
                self.getVideosDetails(JSONSerialization.serializeDataToDictionary(data), completitionHandler: completitionHandler)
            })
        }
    }
    
    fileprivate func getPlaylistItems(_ playlistDictionary:NSDictionary?, completitionHandler:@escaping ()->()) {
        guard let playlistDictionary = playlistDictionary else { return }
        
        etag = playlistDictionary.value(forKeyPath: "etag") as? String
        totalResults = playlistDictionary.value(forKeyPath: "pageInfo.totalResults") as? Int
        resultsPerPage = playlistDictionary.value(forKeyPath: "pageInfo.resultsPerPage") as? Int
        nextPageToken = playlistDictionary.value(forKeyPath: "nextPageToken") as? String
        prevPageToken = playlistDictionary.value(forKeyPath: "prevPageToken") as? String
        
        if let playlistVideos = playlistDictionary.value(forKeyPath: "items") as? NSArray {
            var videoIds = ""
            
            for playlistVideo in playlistVideos {
                guard let videoId = (playlistVideo as AnyObject).value(forKeyPath: "snippet.resourceId.videoId") as? String else { continue }
                videoIds = (videoIds + videoId) + ","
            }
            
            videoIds = String(videoIds.characters.dropLast())
            getVideosDetails(videosId: videoIds, pageToken: nil, completitionHandler: {
                completitionHandler()
            })
        }
    }
    
    fileprivate func getVideosDetails(_ videosDictionary:NSDictionary?, completitionHandler:@escaping ()->()) {
        guard let videosDictionary = videosDictionary else { return }
        guard let items = videosDictionary.value(forKeyPath: "items") as? NSArray else { return }
        
        var channelIds:[String] = []
        
        for item in items {
            guard let item = item as? NSDictionary else { continue }
            let video = YTVideo()
            video.videoId = item.value(forKeyPath: "id") as? String
            video.channelId = item.value(forKeyPath: "snippet.channelId") as? String
            video.channelName = item.value(forKeyPath: "snippet.channelTitle") as? String
            video.videoTitle = item.value(forKeyPath: "snippet.title") as? String
            video.videoDescription = item.value(forKeyPath: "snippet.description") as? String
            video.videoDuration = item.value(forKeyPath: "snippet.description") as? String
            
            if let publishedAt = item.value(forKeyPath: "snippet.publishedAt") as? String {
                let posix = Locale(identifier: "en_US_POSIX")
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                dateFormatter.locale = posix
                video.publishedAt = dateFormatter.date(from: publishedAt)
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
        
        channelIds = channelIds.removeDuplicates()
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
    
    fileprivate func getThumbnailInfo(_ playlistVideo:NSDictionary, keyPath:String) -> YTVideo.Thumbnail? {
        if let thumbnail = playlistVideo.value(forKeyPath: keyPath) as? NSDictionary {
            let height = thumbnail.value(forKeyPath: "height") as? Int
            let width = thumbnail.value(forKeyPath: "width") as? Int
            let url = thumbnail.value(forKeyPath: "url") as? String
            
            return YTVideo.Thumbnail(height: height, width: width, url: url)
        }
        return nil
    }
    
}
