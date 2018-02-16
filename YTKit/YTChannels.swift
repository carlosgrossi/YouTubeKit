//
//  YTChannel.swift
//  YTKit
//
//  Created by Carlos Grossi on 3/8/16.
//  Copyright © 2016 Carlos Grossi. All rights reserved.
//

import Foundation

open class YTChannels: YTAPI {
    
    open var etag:String?
    open var channelsIds:[String] = []
    open var totalResults:Int?
    open var resultsPerPage:Int?
    open var nextPageToken:String?
    open var prevPageToken:String?
    open var items:[YTChannel] = []
    
    
    open func getChannels(_ part:String = "snippet", channelsIds:[String], pageToken:String?, completitionHandler:@escaping ()->()) {
        guard channelsIds.count > 0 else { completitionHandler(); return }
        guard let url = getChannelsURL(part, channelsIds:channelsIds , pageToken:pageToken) else { completitionHandler(); return }
        self.channelsIds = channelsIds
        getChannels(url, completitionHandler:completitionHandler)
    }
    
    open func loadNextPage(_ completitionHandler:()->()) {
    }
    
    // MARK: - Private Methods
    fileprivate func getChannelsURL(_ part:String, channelsIds:[String], pageToken:String?) -> URL? {
        let pgToken:String = pageToken == nil ? "" : pageToken!
        
        var channelsIdsStr = ""
        for channelId in channelsIds {
            channelsIdsStr = (channelsIdsStr + channelId) + ","
        }
        channelsIdsStr = String(channelsIdsStr.characters.dropLast())
        
        return URL(string: APIConstants.channelsURL, args: [part, channelsIdsStr, pgToken, apiKey])
    }
    
    fileprivate func getChannels(_ url:URL, completitionHandler:@escaping ()->()) {
		URLSession.dataTask(with: url) { (data, response, error) in
            URLSession.validateURLSessionDataTask(data, response: response, error: error as NSError?, completitionHandler: { (data, error) in
                self.getChannels(JSONSerialization.jsonObject(with: data), completitionHandler: completitionHandler)
            })
        }
    }
    
    fileprivate func getChannels(_ playlistDictionary:NSDictionary?, completitionHandler:()->()) {
        guard let channelsDictionary = playlistDictionary else { return }
        
        etag = channelsDictionary.value(forKeyPath: "etag") as? String
        totalResults = channelsDictionary.value(forKeyPath: "pageInfo.totalResults") as? Int
        resultsPerPage = channelsDictionary.value(forKeyPath: "pageInfo.resultsPerPage") as? Int
        nextPageToken = channelsDictionary.value(forKeyPath: "nextPageToken") as? String
        prevPageToken = channelsDictionary.value(forKeyPath: "prevPageToken") as? String
        
        if let ytChannels = channelsDictionary.value(forKeyPath: "items") as? NSArray {
            for ytChannel in ytChannels {
                let channel = YTChannel()
                channel.etag = (ytChannel as AnyObject).value(forKeyPath: "etag") as? String
                channel.id = (ytChannel as AnyObject).value(forKeyPath: "id") as? String
                channel.country = (ytChannel as AnyObject).value(forKeyPath: "country") as? String
                channel.customUrl = (ytChannel as AnyObject).value(forKeyPath: "customURL") as? String
                channel.description = (ytChannel as AnyObject).value(forKeyPath: "description") as? String
                channel.title = (ytChannel as AnyObject).value(forKeyPath: "title") as? String
                
                
                if let publishedAt = (ytChannel as AnyObject).value(forKeyPath: "snippet.publishedAt") as? String {
                    let posix = Locale(identifier: "en_US_POSIX")
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    dateFormatter.locale = posix
                    channel.publishedAt = dateFormatter.date(from: publishedAt)
                }
                
                channel.defaultThumbnail = (ytChannel as AnyObject).value(forKeyPath: "snippet.thumbnails.default.url") as? String
                channel.highThumbnail = (ytChannel as AnyObject).value(forKeyPath: "snippet.thumbnails.high.url") as? String
                channel.mediumThumbnail = (ytChannel as AnyObject).value(forKeyPath: "snippet.thumbnails.medium.url") as? String
                
                items.append(channel)
            }
        }
        
        completitionHandler()
    }
    
}
