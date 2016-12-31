//
//  YepUIModels.swift
//  Yep
//
//  Created by NIX on 16/5/23.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import CoreLocation


public enum ProfileUser {
    
    case discoveredUserType(DiscoveredUser)
    case userType(User)
    
    public var userID: String {
        
        switch self {
        case .discoveredUserType(let discoveredUser):
            return discoveredUser.userID
        case .userType(let user):
            return user.userID
        }
    }
    
    public var username: String? {
        
        var username: String? = nil
        switch self {
        case .discoveredUserType(let discoveredUser):
            username = discoveredUser.username
        case .userType(let user):
            if !user.username.isEmpty {
                username = user.username
            }
        }
        
        return username
    }
    
    public var nickname: String? {
        
        switch self {
        case .discoveredUserType(let discoveredUser):
            return discoveredUser.nickname
        case .userType(let user):
            return user.nickname
        }
    }
    
    public var avatarURLString: String? {
        
        var avatarURLString: String? = nil
        switch self {
        case .discoveredUserType(let discoveredUser):
            avatarURLString = discoveredUser.avatarURLString
        case .userType(let user):
            if !user.avatarURLString.isEmpty {
                avatarURLString = user.avatarURLString
            }
        }
        
        return avatarURLString
    }
    
    
    public var isMe: Bool {
        
        switch self {
        case .discoveredUserType(let discoveredUser):
            return discoveredUser.isMe
        case .userType(let user):
            return user.isMe
        }
    }
    
}

public enum PickLocationViewControllerLocation {
    
    public struct Info {
        public let coordinate: CLLocationCoordinate2D
        public var name: String?
        
        public init(coordinate: CLLocationCoordinate2D, name: String?) {
            self.coordinate = coordinate
            self.name = name
        }
    }
    
    case `default`(info: Info)
    case picked(info: Info)
    case selected(info: Info)
    
    public var info: Info {
        switch self {
        case .default(let locationInfo):
            return locationInfo
        case .picked(let locationInfo):
            return locationInfo
        case .selected(let locationInfo):
            return locationInfo
        }
    }
    
    public var isPicked: Bool {
        switch self {
        case .picked:
            return true
        default:
            return false
        }
    }
}

