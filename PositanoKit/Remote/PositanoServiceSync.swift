//
//  PositanoServiceSync.swift
//  Positano
//
//  Created by dinglin on 2016/12/22.
//  Copyright © 2016年 dinglin. All rights reserved.
//

import Foundation
import PositanoNetworking
import RealmSwift


public func syncMyInfoAndDoFurtherAction(_ furtherAction: @escaping () -> Void) {
    
    userInfo(failureHandler: { (reason, errorMessage) in
        furtherAction()
        
    }, completion: { friendInfo in
        
        //println("my userInfo: \(friendInfo)")
        
        realmQueue.async {
            
            if let myUserID = PositanoUserDefaults.userID.value {
                
                guard let realm = try? Realm() else {
                    return
                }
                
                var me = userWithUserID(myUserID, inRealm: realm)
                
                if me == nil {
                    let newUser = User()
                    newUser.userID = myUserID
                    
                    if let createdUnixTime = friendInfo["created_at"] as? TimeInterval {
                        newUser.createdUnixTime = createdUnixTime
                    }
                    
                    let _ = try? realm.write {
                        realm.add(newUser)
                    }
                    
                    me = newUser
                }
                
                if let user = me {
                    
                    // 更新用户信息
                    
                    let _ = try? realm.write {
                        updateUserWithUserID(user.userID, useUserInfo: friendInfo, inRealm: realm)
                    }
                                        
                    // also save some infomation in YepUserDefaults
                    
                    PositanoUserDefaults.admin.value = (friendInfo["admin"] as? Bool)
                    
                    let nickname = friendInfo["nickname"] as? String
                    PositanoUserDefaults.nickname.value = nickname
                    
                    let introduction = friendInfo["introduction"] as? String
                    PositanoUserDefaults.introduction.value = introduction
                    
                    let avatarInfo = friendInfo["avatar"] as? JSONDictionary
                    let avatarURLString = avatarInfo?["url"] as? String
                    PositanoUserDefaults.avatarURLString.value = avatarURLString
                    
                    let areaCode = friendInfo["phone_code"] as? String
                    PositanoUserDefaults.areaCode.value = areaCode
                    
                    let mobile = friendInfo["mobile"] as? String
                    PositanoUserDefaults.mobile.value = mobile
                }
            }
            
            furtherAction()
        }
    })
}
