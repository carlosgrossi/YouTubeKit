//
//  YTComment.swift
//  YTKit
//
//  Created by Carlos Grossi on 11/8/16.
//  Copyright © 2016 Carlos Grossi. All rights reserved.
//

import Foundation

public class YTComment {
    
    public var id:String?
    public var authorChannelId:String?
    public var authorChannelURL:String?
    public var authorChannelName:String?
    public var authorProfileImageURL:String?
    public var commentText:String?
    public var likeCount:Int64 = 0
    public var publishedAt:NSDate?
    public var updatedAt:NSDate?
    public var videoId:String?
    public var viewerRating:String?
    public var canRate:Bool?
    public var canReply:Bool?
    public var isPublic:Bool?
    
    public var replies:[YTComment] = []
    public var totalReplyCount:Int64 = 0
    
    public var nextPageToken:String?
    public var prevPageToken:String?
}