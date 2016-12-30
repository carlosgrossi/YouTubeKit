//
//  YTChannel.swift
//  YTKit
//
//  Created by Carlos Grossi on 3/8/16.
//  Copyright © 2016 Carlos Grossi. All rights reserved.
//

import Foundation

public class YTChannels: YTAPI {
    
    public var etag:String?
    public var channelsIds:[String] = []
    public var totalResults:Int?
    public var resultsPerPage:Int?
    public var nextPageToken:String?
    public var prevPageToken:String?
    public var items:[YTChannel] = []
    
    
    public func getChannels(part:String = "snippet", channelsIds:[String], pageToken:String?, completitionHandler:()->()) {
        guard channelsIds.count > 0 else { completitionHandler(); return }
        guard let url = getChannelsURL(part, channelsIds:channelsIds , pageToken:pageToken) else { completitionHandler(); return }
        self.channelsIds = channelsIds
        getChannels(url, completitionHandler:completitionHandler)
    }
    
    public func loadNextPage(completitionHandler:()->()) {
    }
    
    // MARK: - Private Methods
    private func getChannelsURL(part:String, channelsIds:[String], pageToken:String?) -> NSURL? {
        let pgToken:String = pageToken == nil ? "" : pageToken!
        
        var channelsIdsStr = ""
        for channelId in channelsIds {
            channelsIdsStr = channelsIdsStr.stringByAppendingString(channelId).stringByAppendingString(",")
        }
        channelsIdsStr = String(channelsIdsStr.characters.dropLast())
        
        return NSURL(string: APIConstants.channelsURL, args: [part, channelsIdsStr, pgToken, apiKey])
    }
    
    private func getChannels(url:NSURL, completitionHandler:()->()) {
        NSURLSession.urlSessionDataTaskWithURL(url) { (data, response, error) in
            NSURLSession.validateURLSessionDataTask(data, response: response, error: error, completitionHandler: { (data, error) in
                self.getChannels(NSJSONSerialization.serializeDataToDictionary(data), completitionHandler: completitionHandler)
            })
        }
    }
    
    private func getChannels(playlistDictionary:NSDictionary?, completitionHandler:()->()) {
        guard let channelsDictionary = playlistDictionary else { return }
        
        etag = channelsDictionary.valueForKeyPath("etag") as? String
        totalResults = channelsDictionary.valueForKeyPath("pageInfo.totalResults") as? Int
        resultsPerPage = channelsDictionary.valueForKeyPath("pageInfo.resultsPerPage") as? Int
        nextPageToken = channelsDictionary.valueForKeyPath("nextPageToken") as? String
        prevPageToken = channelsDictionary.valueForKeyPath("prevPageToken") as? String
        
        if let ytChannels = channelsDictionary.valueForKeyPath("items") as? NSArray {
            for ytChannel in ytChannels {
                let channel = YTChannel()
                channel.etag = ytChannel.valueForKeyPath("etag") as? String
                channel.id = ytChannel.valueForKeyPath("id") as? String
                channel.country = ytChannel.valueForKeyPath("country") as? String
                channel.customUrl = ytChannel.valueForKeyPath("customURL") as? String
                channel.description = ytChannel.valueForKeyPath("description") as? String
                channel.title = ytChannel.valueForKeyPath("title") as? String
                
                
                if let publishedAt = ytChannel.valueForKeyPath("snippet.publishedAt") as? String {
                    let posix = NSLocale(localeIdentifier: "en_US_POSIX")
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    dateFormatter.locale = posix
                    channel.publishedAt = dateFormatter.dateFromString(publishedAt)
                }
                
                channel.defaultThumbnail = ytChannel.valueForKeyPath("snippet.thumbnails.default.url") as? String
                channel.highThumbnail = ytChannel.valueForKeyPath("snippet.thumbnails.high.url") as? String
                channel.mediumThumbnail = ytChannel.valueForKeyPath("snippet.thumbnails.medium.url") as? String
                
                items.append(channel)
            }
        }
        
        completitionHandler()
    }
    
}