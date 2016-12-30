//
//  YTVideo.swift
//  YTKit
//
//  Created by Carlos Grossi on 1/8/16.
//  Copyright © 2016 Carlos Grossi. All rights reserved.
//

import Foundation

open class YTVideo:YTAPI {
    open var etag:String?
    open var id:String?
    open var videoId:String?
    open var channelId:String?
    open var channelName:String?
    open var channelIcon:String?
    open var videoTitle:String?
    open var videoDescription:String?
    open var videoDuration:String?
    open var defaultThumbnail:Thumbnail?
    open var standardThumbnail:Thumbnail?
    open var highThumbnail:Thumbnail?
    open var mediumThumbnail:Thumbnail?
    open var maxresThumbnail:Thumbnail?
    open var videoViews:Int64?
    open var videoLikes:Int64?
    open var videoDislikes:Int64?
    open var videoComments:Int64?
    open var videoFavorites:Int64?
    open var publishedAt:Date?
    open var playlistId:String?
    open var channel:YTChannel?
    open var comments:[YTComment] = []
    
    
    public struct Thumbnail {
        public var height:Int?
        public var width:Int?
        public var url:String?
    }

    
    open func getStatistics(_ part:String = "statistics", pageToken:String?, completitionHandler:@escaping ()->()) {
        guard let videoId = self.videoId else { return }
        guard let url = getStatisticsURL(part, videoId:videoId , pageToken:pageToken) else { return }
        getStatistics(url, completitionHandler:completitionHandler)
    }
    
    open func getComments(_ part:String = "snippet,replies", maxResults:String = "100", order:String = "relevance", pageToken:String?, completitionHandler:@escaping ()->()) {
        guard let videoId = self.videoId else { return }
        guard let url = getCommentsURL(part, maxResults: maxResults, order: order, videoId: videoId, pageToken: pageToken) else { return }
        getComments(url, completitionHandler: completitionHandler)
    }
    
    // MARK: - Private Methods
    fileprivate func getStatisticsURL(_ part:String, videoId:String, pageToken:String?) -> URL? {
        return URL(string: APIConstants.videoStatisticsURL, args: [part, videoId, apiKey])
    }
    
    fileprivate func getCommentsURL(_ part:String, maxResults:String, order:String, videoId:String, pageToken:String?) -> URL? {
        let pgToken:String = pageToken == nil ? "" : pageToken!
        return URL(string: APIConstants.videoCommentThreads, args: [part, maxResults, order, videoId, pgToken, apiKey])
    }
    
    fileprivate func getStatistics(_ url:URL, completitionHandler:@escaping ()->()) {
        URLSession.urlSessionDataTaskWithURL(url) { (data, response, error) in
            URLSession.validateURLSessionDataTask(data, response: response, error: error as NSError?, completitionHandler: { (data, error) in
                self.getStatistics(JSONSerialization.serializeDataToDictionary(data), completitionHandler: completitionHandler)
            })
        }
    }
    
    fileprivate func getComments(_ url:URL, completitionHandler:@escaping ()->()) {
        URLSession.urlSessionDataTaskWithURL(url) { (data, response, error) in
            URLSession.validateURLSessionDataTask(data, response: response, error: error as NSError?, completitionHandler: { (data, error) in
                self.getComments(JSONSerialization.serializeDataToDictionary(data), completitionHandler: completitionHandler)
            })
        }
    }
    
    
    fileprivate func getStatistics(_ statisticsDictionary:NSDictionary?, completitionHandler:()->()) {
        guard let statisticsItems = statisticsDictionary?.value(forKeyPath: "items") as? NSArray else { return }
        guard statisticsItems.count > 0 else { return }
        guard let statisticsItem = statisticsItems.firstObject as? NSDictionary else { return }
        guard let statistics = statisticsItem.value(forKey: "statistics") as? NSDictionary else { return }
        
        videoViews = Int64(statistics.value(forKey: "viewCount") as! String)
        videoLikes = Int64(statistics.value(forKey: "likeCount") as! String)
        videoDislikes = Int64(statistics.value(forKey: "dislikeCount") as! String)
        videoComments = Int64(statistics.value(forKey: "commentCount") as! String)
        videoFavorites = Int64(statistics.value(forKey: "favoriteCount") as! String)
        
        completitionHandler()
    }
    
    fileprivate func getComments(_ commentsDictionary:NSDictionary?, completitionHandler:()->()) {
        defer { completitionHandler() }
        guard let comments = commentsDictionary?.value(forKeyPath: "items") as? NSArray else { return }
        
        let nextPageToken = commentsDictionary?.value(forKey: "nextPageToken") as? String
        let prevPageToken = commentsDictionary?.value(forKey: "prevPageToken") as? String
        
        for comment in comments {
            guard let comment = comment as? NSDictionary else { continue }
            guard let toplevelComment = comment.value(forKeyPath: "snippet.topLevelComment") as? NSDictionary else { continue }
            
            let ytComment = getComment(toplevelComment)
            ytComment.nextPageToken = nextPageToken
            ytComment.prevPageToken = prevPageToken
            
            if let replies = comment.value(forKeyPath: "replies.comments") as? NSArray {
                for reply in replies {
                    guard let reply = reply as? NSDictionary else { continue }
                    let ytReply = getComment(reply)
                    ytComment.replies.append(ytReply)
                }
            }
            
            self.comments.append(ytComment)
        }
    }
    
    fileprivate func getComment(_ commentSnippet:NSDictionary) -> YTComment {
        let ytComment = YTComment()
        
        ytComment.id = commentSnippet.value(forKeyPath: "id") as? String
        ytComment.authorChannelId = commentSnippet.value(forKeyPath: "snippet.authorChannelId.value") as? String
        ytComment.authorChannelName = commentSnippet.value(forKeyPath: "snippet.authorDisplayName") as? String
        ytComment.authorChannelURL = commentSnippet.value(forKeyPath: "snippet.authorChannelUrl") as? String
        ytComment.authorProfileImageURL = commentSnippet.value(forKeyPath: "snippet.authorProfileImageUrl") as? String
        ytComment.canRate = commentSnippet.value(forKeyPath: "snippet.canRate") as? Bool
        ytComment.commentText = commentSnippet.value(forKeyPath: "snippet.textDisplay") as? String
        ytComment.videoId = commentSnippet.value(forKeyPath: "snippet.videoId") as? String
        ytComment.viewerRating = commentSnippet.value(forKeyPath: "snippet.viewerRating") as? String
        
        if let likeCount = commentSnippet.value(forKeyPath: "snippet.likeCount") as? Int {
            ytComment.likeCount = Int64(likeCount)
        }
        
        if let publishedAt = commentSnippet.value(forKeyPath: "snippet.publishedAt") as? String {
            let posix = Locale(identifier: "en_US_POSIX")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = posix
            ytComment.publishedAt = dateFormatter.date(from: publishedAt)
        }
        
        if let updatedAt = commentSnippet.value(forKeyPath: "snippet.updatedAt") as? String {
            let posix = Locale(identifier: "en_US_POSIX")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = posix
            ytComment.updatedAt = dateFormatter.date(from: updatedAt)
        }
        
        return ytComment
    }
}
