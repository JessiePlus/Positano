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


}

