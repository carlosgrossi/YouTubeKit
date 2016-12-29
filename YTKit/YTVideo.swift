//
//  YTVideo.swift
//  YTKit
//
//  Created by Carlos Grossi on 1/8/16.
//  Copyright © 2016 Carlos Grossi. All rights reserved.
//

import Foundation

public class YTVideo:YTAPI {
    public var etag:String?
    public var id:String?
    public var videoId:String?
    public var channelId:String?
    public var channelName:String?
    public var channelIcon:String?
    public var videoTitle:String?
    public var videoDescription:String?
    public var videoDuration:String?
    public var defaultThumbnail:Thumbnail?
    public var standardThumbnail:Thumbnail?
    public var highThumbnail:Thumbnail?
    public var mediumThumbnail:Thumbnail?
    public var maxresThumbnail:Thumbnail?
    public var videoViews:Int64?
    public var videoLikes:Int64?
    public var videoDislikes:Int64?
    public var videoComments:Int64?
    public var videoFavorites:Int64?
    public var publishedAt:NSDate?
    public var playlistId:String?
    public var channel:YTChannel?
    public var comments:[YTComment] = []
    
    
    public struct Thumbnail {
        public var height:Int?
        public var width:Int?
        public var url:String?
    }

    
    public func getStatistics(part:String = "statistics", pageToken:String?, completitionHandler:()->()) {
        guard let videoId = self.videoId else { return }
        guard let url = getStatisticsURL(part, videoId:videoId , pageToken:pageToken) else { return }
        getStatistics(url, completitionHandler:completitionHandler)
    }
    
    public func getComments(part:String = "snippet,replies", maxResults:String = "100", order:String = "relevance", pageToken:String?, completitionHandler:()->()) {
        guard let videoId = self.videoId else { return }
        guard let url = getCommentsURL(part, maxResults: maxResults, order: order, videoId: videoId, pageToken: pageToken) else { return }
        getComments(url, completitionHandler: completitionHandler)
    }
    
    // MARK: - Private Methods
    private func getStatisticsURL(part:String, videoId:String, pageToken:String?) -> NSURL? {
        return NSURL(string: APIConstants.videoStatisticsURL, args: [part, videoId, apiKey])
    }
    
    private func getCommentsURL(part:String, maxResults:String, order:String, videoId:String, pageToken:String?) -> NSURL? {
        let pgToken:String = pageToken == nil ? "" : pageToken!
        return NSURL(string: APIConstants.videoCommentThreads, args: [part, maxResults, order, videoId, pgToken, apiKey])
    }
    
    private func getStatistics(url:NSURL, completitionHandler:()->()) {
        NSURLSession.urlSessionDataTaskWithURL(url) { (data, response, error) in
            NSURLSession.validateURLSessionDataTask(data, response: response, error: error, completitionHandler: { (data, error) in
                self.getStatistics(NSJSONSerialization.serializeDataToDictionary(data), completitionHandler: completitionHandler)
            })
        }
    }
    
    private func getComments(url:NSURL, completitionHandler:()->()) {
        NSURLSession.urlSessionDataTaskWithURL(url) { (data, response, error) in
            NSURLSession.validateURLSessionDataTask(data, response: response, error: error, completitionHandler: { (data, error) in
                self.getComments(NSJSONSerialization.serializeDataToDictionary(data), completitionHandler: completitionHandler)
            })
        }
    }
    
    
    private func getStatistics(statisticsDictionary:NSDictionary?, completitionHandler:()->()) {
        guard let statisticsItems = statisticsDictionary?.valueForKeyPath("items") as? NSArray else { return }
        guard statisticsItems.count > 0 else { return }
        guard let statisticsItem = statisticsItems.firstObject as? NSDictionary else { return }
        guard let statistics = statisticsItem.valueForKey("statistics") as? NSDictionary else { return }
        
        videoViews = Int64(statistics.valueForKey("viewCount") as! String)
        videoLikes = Int64(statistics.valueForKey("likeCount") as! String)
        videoDislikes = Int64(statistics.valueForKey("dislikeCount") as! String)
        videoComments = Int64(statistics.valueForKey("commentCount") as! String)
        videoFavorites = Int64(statistics.valueForKey("favoriteCount") as! String)
        
        completitionHandler()
    }
    
    private func getComments(commentsDictionary:NSDictionary?, completitionHandler:()->()) {
        defer { completitionHandler() }
        guard let comments = commentsDictionary?.valueForKeyPath("items") as? NSArray else { return }
        
        let nextPageToken = commentsDictionary?.valueForKey("nextPageToken") as? String
        let prevPageToken = commentsDictionary?.valueForKey("prevPageToken") as? String
        
        for comment in comments {
            guard let comment = comment as? NSDictionary else { continue }
            guard let toplevelComment = comment.valueForKeyPath("snippet.topLevelComment") as? NSDictionary else { continue }
            
            let ytComment = getComment(toplevelComment)
            ytComment.nextPageToken = nextPageToken
            ytComment.prevPageToken = prevPageToken
            
            if let replies = comment.valueForKeyPath("replies.comments") as? NSArray {
                for reply in replies {
                    guard let reply = reply as? NSDictionary else { continue }
                    let ytReply = getComment(reply)
                    ytComment.replies.append(ytReply)
                }
            }
            
            self.comments.append(ytComment)
        }
    }
    
    private func getComment(commentSnippet:NSDictionary) -> YTComment {
        let ytComment = YTComment()
        
        ytComment.id = commentSnippet.valueForKeyPath("id") as? String
        ytComment.authorChannelId = commentSnippet.valueForKeyPath("snippet.authorChannelId.value") as? String
        ytComment.authorChannelName = commentSnippet.valueForKeyPath("snippet.authorDisplayName") as? String
        ytComment.authorChannelURL = commentSnippet.valueForKeyPath("snippet.authorChannelUrl") as? String
        ytComment.authorProfileImageURL = commentSnippet.valueForKeyPath("snippet.authorProfileImageUrl") as? String
        ytComment.canRate = commentSnippet.valueForKeyPath("snippet.canRate") as? Bool
        ytComment.commentText = commentSnippet.valueForKeyPath("snippet.textDisplay") as? String
        ytComment.videoId = commentSnippet.valueForKeyPath("snippet.videoId") as? String
        ytComment.viewerRating = commentSnippet.valueForKeyPath("snippet.viewerRating") as? String
        
        if let likeCount = commentSnippet.valueForKeyPath("snippet.likeCount") as? Int {
            ytComment.likeCount = Int64(likeCount)
        }
        
        if let publishedAt = commentSnippet.valueForKeyPath("snippet.publishedAt") as? String {
            let posix = NSLocale(localeIdentifier: "en_US_POSIX")
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = posix
            ytComment.publishedAt = dateFormatter.dateFromString(publishedAt)
        }
        
        if let updatedAt = commentSnippet.valueForKeyPath("snippet.updatedAt") as? String {
            let posix = NSLocale(localeIdentifier: "en_US_POSIX")
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = posix
            ytComment.updatedAt = dateFormatter.dateFromString(updatedAt)
        }
        
        return ytComment
    }
}
