//
//  Models.swift
//  Yep
//
//  Created by NIX on 15/3/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import MapKit
import PositanoNetworking
import RealmSwift

// 总是在这个队列里使用 Realm
//let realmQueue = dispatch_queue_create("com.Yep.realmQueue", DISPATCH_QUEUE_SERIAL)
public let realmQueue = DispatchQueue(label: "com.Positano.realmQueue", qos: .utility, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
//public let realmQueue = DispatchQueue(label: "com.Yep.realmQueue", attributes: dispatch_queue_attr_make_with_qos_class(DispatchQueue.Attributes(), DispatchQoS.QoSClass.utility, 0))

// MARK: User

open class Avatar: Object {
    open dynamic var avatarURLString: String = ""
    open dynamic var avatarFileName: String = ""

    open dynamic var roundMini: Data = Data() // 60
    open dynamic var roundNano: Data = Data() // 40

    let users = LinkingObjects(fromType: User.self, property: "avatar")
    open var user: User? {
        return users.first
    }
}

//这里定义一下和数据库交互的models 2016-12-31 13:04:25

open class User: Object {
    open dynamic var userID: String = ""
    open dynamic var username: String = ""
    open dynamic var nickname: String = ""
    open dynamic var introduction: String = ""
    open dynamic var avatarURLString: String = ""
    open dynamic var avatar: Avatar?

    open override class func indexedProperties() -> [String] {
        return ["userID"]
    }

    open dynamic var createdUnixTime: TimeInterval = Date().timeIntervalSince1970
    open dynamic var lastSignInUnixTime: TimeInterval = Date().timeIntervalSince1970
    
    open dynamic var longitude: Double = 0
    open dynamic var latitude: Double = 0
    



    open var isMe: Bool {
        if let myUserID = PositanoUserDefaults.userID.value {
            return userID == myUserID
        }
        
        return false
    }

    open var mentionedUsername: String? {
        if username.isEmpty {
            return nil
        } else {
            return "@\(username)"
        }
    }

    open var compositedName: String {
        if username.isEmpty {
            return nickname
        } else {
            return "\(nickname) @\(username)"
        }
    }

    // 级联删除关联的数据对象

    open func cascadeDeleteInRealm(_ realm: Realm) {

        if let avatar = avatar {

            if !avatar.avatarFileName.isEmpty {
                FileManager.deleteAvatarImageWithName(avatar.avatarFileName)
            }

            realm.delete(avatar)
        }



        realm.delete(self)
    }
}

open class UserLocationName: Object {
    
    open dynamic var userID: String = ""
    open dynamic var locationName: String = ""
    
    open override class func primaryKey() -> String? {
        return "userID"
    }
    
    open override class func indexedProperties() -> [String] {
        return ["userID"]
    }
    
    public convenience init(userID: String, locationName: String) {
        self.init()
        
        self.userID = userID
        self.locationName = locationName
    }
    
    open class func withUserID(_ userID: String, inRealm realm: Realm) -> UserLocationName? {
        return realm.objects(UserLocationName.self).filter("userID = %@", userID).first
    }
}


// MARK: Helpers

public func userWithUserID(_ userID: String, inRealm realm: Realm) -> User? {
    let predicate = NSPredicate(format: "userID = %@", userID)

    #if DEBUG
    let users = realm.objects(User.self).filter(predicate)
    if users.count > 1 {
        println("Warning: same userID: \(users.count), \(userID)")
    }
    #endif

    return realm.objects(User.self).filter(predicate).first
}

public func meInRealm(_ realm: Realm) -> User? {
    guard let myUserID = PositanoUserDefaults.userID.value else {
        return nil
    }
    return userWithUserID(myUserID, inRealm: realm)
}

public func me() -> User? {
    guard let realm = try? Realm() else {
        return nil
    }
    return meInRealm(realm)
}

public func userWithUsername(_ username: String, inRealm realm: Realm) -> User? {
    let predicate = NSPredicate(format: "username = %@", username)
    return realm.objects(User.self).filter(predicate).first
}

public func userWithAvatarURLString(_ avatarURLString: String, inRealm realm: Realm) -> User? {
    let predicate = NSPredicate(format: "avatarURLString = %@", avatarURLString)
    return realm.objects(User.self).filter(predicate).first
}


public func avatarWithAvatarURLString(_ avatarURLString: String, inRealm realm: Realm) -> Avatar? {
    let predicate = NSPredicate(format: "avatarURLString = %@", avatarURLString)
    return realm.objects(Avatar.self).filter(predicate).first
}

public func tryGetOrCreateMeInRealm(_ realm: Realm) -> User? {

    guard let userID = PositanoUserDefaults.userID.value else {
        return nil
    }

    if let me = userWithUserID(userID, inRealm: realm) {
        return me

    } else {
        let me = User()

        me.userID = userID

        if let nickname = PositanoUserDefaults.nickname.value {
            me.nickname = nickname
        }

        if let avatarURLString = PositanoUserDefaults.avatarURLString.value {
            me.avatarURLString = avatarURLString
        }

        let _ = try? realm.write {
            realm.add(me)
        }

        return me
    }
}


// MARK: Update with info

public func updateUserWithUserID(_ userID: String, useUserInfo userInfo: JSONDictionary, inRealm realm: Realm) {

    if let user = userWithUserID(userID, inRealm: realm) {

        // 更新用户信息

        if let lastSignInUnixTime = userInfo["last_sign_in_at"] as? TimeInterval {
            user.lastSignInUnixTime = lastSignInUnixTime
        }

        if let username = userInfo["username"] as? String {
            user.username = username
        }

        if let nickname = userInfo["nickname"] as? String {
            user.nickname = nickname
        }

        if let introduction = userInfo["introduction"] as? String {
            user.introduction = introduction
        }

        if let avatarInfo = userInfo["avatar"] as? JSONDictionary, let avatarURLString = avatarInfo["url"] as? String {
            user.avatarURLString = avatarURLString
        }

    }
}

public func clearUselessRealmObjects() {
    
    realmQueue.async {
        
        guard let realm = try? Realm() else {
            return
        }
        
        defer {
            realm.refresh()
        }
        
        println("do clearUselessRealmObjects")
        
        realm.beginWrite()
        
        // Message
        
        do {
            // 7天前

        }
        
        // Feed

        
        // User
        
        
        // Group
        
        let _ = try? realm.commitWrite()
    }
}


