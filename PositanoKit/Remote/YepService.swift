//
//  YepService.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import CoreLocation
import PositanoNetworking
import RealmSwift
import Alamofire

#if STAGING
public let yepHost = "park-staging.catchchatchina.com"
public let yepBaseURL = URL(string: "https://park-staging.catchchatchina.com/api")!
public let fayeBaseURL = URL(string: "wss://faye-staging.catchchatchina.com/faye")!
#else
public let yepHost = "soyep.com"
public let yepBaseURL = URL(string: "https://api.soyep.com")!
public let fayeBaseURL = URL(string: "wss://faye.catchchatchina.com/faye")!
#endif

func println(_ item: @autoclosure () -> Any) {
    #if DEBUG
        Swift.print(item())
    #endif
}

// Models

public struct LoginUser: CustomStringConvertible {

    public let accessToken: String
    public let userID: String
    public let username: String?
    public let nickname: String
    public let avatarURLString: String?
    public let pusherID: String

    public var description: String {
        return "LoginUser(accessToken: \(accessToken), userID: \(userID), username: \(username), nickname: \(nickname), avatarURLString: \(avatarURLString), pusherID: \(pusherID))"
    }

    static func fromJSONDictionary(_ data: JSONDictionary) -> LoginUser? {

        guard let accessToken = data["access_token"] as? String else { return nil }

        guard let user = data["user"] as? JSONDictionary else { return nil }
        guard let userID = user["id"] as? String else { return nil }
        guard let nickname = user["nickname"] as? String else { return nil }
        guard let pusherID = user["pusher_id"] as? String else { return nil }

        let username = user["username"] as? String
        let avatarURLString = user["avatar_url"] as? String

        return LoginUser(accessToken: accessToken, userID: userID, username: username, nickname: nickname, avatarURLString: avatarURLString, pusherID: pusherID)
    }
}

public func saveTokenAndUserInfoOfLoginUser(_ loginUser: LoginUser) {

    PositanoUserDefaults.userID.value = loginUser.userID
    PositanoUserDefaults.nickname.value = loginUser.nickname
    PositanoUserDefaults.avatarURLString.value = loginUser.avatarURLString
    PositanoUserDefaults.pusherID.value = loginUser.pusherID

    // NOTICE: 因为一些操作依赖于 accessToken 做检测，又可能依赖上面其他值，所以要放在最后赋值
    PositanoUserDefaults.v1AccessToken.value = loginUser.accessToken
}

public struct MobilePhone {

    public let areaCode: String
    public let number: String

    public var fullNumber: String {
        return "+" + areaCode + " " + number
    }

    public init(areaCode: String, number: String) {
        self.areaCode = areaCode
        self.number = number
    }
}

// MARK: - Register

public func validateMobilePhone(_ mobilePhone: MobilePhone, failureHandler: FailureHandler?, completion: @escaping ((Bool, String)) -> Void) {

    let requestParameters: JSONDictionary = [
        "phone_code": mobilePhone.areaCode,
        "mobile": mobilePhone.number,
    ]

    let parse: (JSONDictionary) -> (Bool, String)? = { data in
        println("validateMobilePhone: \(data)")
        if let available = data["available"] as? Bool {
            if available {
                return (available, "")
            } else {
                if let message = data["message"] as? String {
                    return (available, message)
                }
            }
        }
        
        return (false, "")
    }

    let resource = jsonResource(path: "/v1/users/mobile_validate", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func registerMobilePhone(_ mobilePhone: MobilePhone, nickname: String, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let requestParameters: JSONDictionary = [
        "phone_code": mobilePhone.areaCode,
        "mobile": mobilePhone.number,
        "nickname": nickname,
        // 注册时不好提示用户访问位置，或许设置技能或用户利用位置查找好友时再提示并更新位置信息
    ]

    let parse: (JSONDictionary) -> Bool? = { data in
        if let state = data["state"] as? String {
            if state == "blocked" {
                return true
            }
        }

        return false
    }

    let resource = jsonResource(path: "/v1/registration/create", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func verifyMobilePhone(_ mobilePhone: MobilePhone, verifyCode: String, failureHandler: FailureHandler?, completion: @escaping (LoginUser) -> Void) {

    let requestParameters: JSONDictionary = [
        "phone_code": mobilePhone.areaCode,
        "mobile": mobilePhone.number,
        "token": verifyCode,
        "client": Config.clientType,
        "expiring": 0, // 永不过期
    ]

    let parse: (JSONDictionary) -> LoginUser? = { data in
        return LoginUser.fromJSONDictionary(data)
    }

    let resource = jsonResource(path: "/v1/registration/update", method: .put, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}




