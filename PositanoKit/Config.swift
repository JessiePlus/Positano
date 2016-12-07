//
//  Config.swift
//  Yep
//
//  Created by NIX on 16/5/24.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

final public class Config {
    
    public static var updatedAccessTokenAction: (() -> Void)?
    public static var updatedPusherIDAction: ((_ pusherID: String) -> Void)?
    
    public static var sentMessageSoundEffectAction: (() -> Void)?
    
    public static var timeAgoAction: ((_ date: Date) -> String)?
    
    public static var isAppActive: (() -> Bool)?
    
    public static let appGroupID: String = "group.Catch-Inc.Yep"

    public static var clientType: Int {
        #if DEBUG
            return 2
        #else
            return 0
        #endif
    }

    public struct MetaData {
        public static let audioDuration = "audio_duration"
        public static let audioSamples = "audio_samples"
        
        public static let imageWidth = "image_width"
        public static let imageHeight = "image_height"
        
        public static let videoWidth = "video_width"
        public static let videoHeight = "video_height"
        
        public static let thumbnailString = "thumbnail_string"
        public static let blurredThumbnailString = "blurred_thumbnail_string"
        
        public static let thumbnailMaxSize: CGFloat = 60
    }
    
    public struct Media {
        public static let imageWidth: CGFloat = 1024
        public static let imageHeight: CGFloat = 1024
        
        public static let miniImageWidth: CGFloat = 200
        public static let miniImageHeight: CGFloat = 200
    }
    
}

