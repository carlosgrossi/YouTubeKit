//
//  Constants.swift
//  YTKit
//
//  Created by Carlos Grossi on 1/8/16.
//  Copyright © 2016 Carlos Grossi. All rights reserved.
//

import Foundation

public struct APIConstants {
    static let playlistItemsURL = "https://www.googleapis.com/youtube/v3/playlistItems?part=%@&maxResults=50&playlistId=%@&pageToken=%@&key=%@"
    static let channelsURL = "https://www.googleapis.com/youtube/v3/channels?part=%@&id=%@&pageToken=%@&key=%@"
    static let videoStatisticsURL = "https://www.googleapis.com/youtube/v3/videos?part=%@&id=%@&key=%@"
    static let videoCommentThreads = "https://www.googleapis.com/youtube/v3/commentThreads?part=%@&maxResults=%@&order=%@&videoId=%@&pageToken=%@&textFormat=plainText&key=%@"
    static let videosListURL = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails,%@&maxResults=50&id=%@&pageToken=%@&key=%@"
}
