//
//  YTComment.swift
//  YTKit
//
//  Created by Carlos Grossi on 11/8/16.
//  Copyright © 2016 Carlos Grossi. All rights reserved.
//

import Foundation

open class YTComment {
    
    open var id:String?
    open var authorChannelId:String?
    open var authorChannelURL:String?
    open var authorChannelName:String?
    open var authorProfileImageURL:String?
    open var commentText:String?
    open var likeCount:Int64 = 0
    open var publishedAt:Date?
    open var updatedAt:Date?
    open var videoId:String?
    open var viewerRating:String?
    open var canRate:Bool?
    open var canReply:Bool?
    open var isPublic:Bool?
    
    open var replies:[YTComment] = []
    open var totalReplyCount:Int64 = 0
    
    open var nextPageToken:String?
    open var prevPageToken:String?
}
