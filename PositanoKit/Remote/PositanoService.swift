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


public let PositanoHost = "positano.com"
public let PositanoBaseURL = URL(string: "https://api.leancloud.cn")!

func println(_ item: @autoclosure () -> Any) {
    #if DEBUG
        Swift.print(item())
    #endif
}

// 这里定义一下和服务器交互的Models

// MARK: - 登录返回的用户
public struct LoginUser: CustomStringConvertible {

    //不能为空:
    public let userID: String
    public let username: String
    //可以为空:
    public let nickname: String?
    public let introduction: String?
    public let avatarURLString: String?
    public let createdUnixTime: TimeInterval?
    public let lastSignInUnixTime: TimeInterval?
    public let longitude: Double?
    public let latitude: Double?
    
    //登录用户独有的数据:
    //不能为空:
    public let accessToken: String
    //可以为空:
    public let pusherID: String?

    public var description: String {
        return "LoginUser(accessToken: \(accessToken), userID: \(userID), username: \(username), nickname: \(nickname), avatarURLString: \(avatarURLString), pusherID: \(pusherID))"
    }

    static func fromJSONDictionary(_ data: JSONDictionary) -> LoginUser? {

        //不能为空
        guard let userID = data["objectId"] as? String else { return nil }
        guard let username = data["username"] as? String else { return nil }
        guard let accessToken = data["sessionToken"] as? String else { return nil }
        
        //可以为空
        let nickname = data["nickname"] as? String
        let introduction = data["introduction"] as? String
        let avatarURLString = data["avatarURLString"] as? String
        let createdUnixTime = data["createdUnixTime"] as? TimeInterval
        let lastSignInUnixTime = data["lastSignInUnixTime"] as? TimeInterval
        let longitude = data["longitude"] as? Double
        let latitude = data["latitude"] as? Double
        let pusherID = data["pusher_id"] as? String


        return LoginUser(userID: userID, username: username,
                         nickname: nickname, introduction: introduction,
                         avatarURLString: avatarURLString, createdUnixTime: createdUnixTime,
                         lastSignInUnixTime: lastSignInUnixTime, longitude: longitude,
                         latitude: latitude,
                         accessToken: accessToken, pusherID: pusherID)
    }
}

// MARK: - 通过扫描二维码或者查询用户名返回的用户
public struct DiscoveredUser: Hashable {
    
    //不能为空:
    public let userID: String
    public let username: String
    
    //可以为空:
    public let nickname: String?
    public let introduction: String?
    public let avatarURLString: String?
    public let createdUnixTime: TimeInterval?
    public let lastSignInUnixTime: TimeInterval?
    public let longitude: Double?
    public let latitude: Double?
    
    
    public var hashValue: Int {
        return userID.hashValue
    }
    
    public var description: String {
        return "DiscoveredUser(userID: \(userID), username: \(username), nickname: \(nickname), avatarURLString: \(avatarURLString))"
    }
    
    public var isMe: Bool {
        if let myUserID = PositanoUserDefaults.userID.value {
            return userID == myUserID
        }
        
        return false
    }
    
    //从数据库的model转成服务器需要的DiscoveredUser
    public static func fromUser(_ user: User) -> DiscoveredUser {
        
        return DiscoveredUser(userID: user.userID, username: user.username, nickname: user.nickname, introduction: user.introduction, avatarURLString: user.avatarURLString, createdUnixTime: user.createdUnixTime, lastSignInUnixTime: user.lastSignInUnixTime, longitude: user.longitude, latitude: user.latitude)
    }
}

public func ==(lhs: DiscoveredUser, rhs: DiscoveredUser) -> Bool {
    return lhs.userID == rhs.userID
}

public let parseDiscoveredUser: (JSONDictionary) -> DiscoveredUser? = { userInfo in
    
    if let userID = userInfo["userID"] as? String, let username = userInfo["username"] as? String {
        
        let nickname = userInfo["nickname"] as? String
        let avatarURLString = userInfo["url"] as? String
        let introduction = userInfo["introduction"] as? String
        let createdUnixTime = userInfo["created_at"] as? TimeInterval
        let lastSignInUnixTime = userInfo["last_sign_in_at"] as? TimeInterval
        let longitude = userInfo["longitude"] as? Double
        let latitude = userInfo["latitude"] as? Double
    
        let discoverUser = DiscoveredUser(userID: userID, username: username, nickname: nickname, introduction: introduction, avatarURLString: avatarURLString, createdUnixTime: createdUnixTime, lastSignInUnixTime: lastSignInUnixTime, longitude: longitude, latitude: latitude)
        
        return discoverUser
    }
    
    println("failed parseDiscoveredUser userInfo: \(userInfo)")
    return nil
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

public struct MailAddress {
    
    public let address: String

    public init(address: String) {
        self.address = address
    }
}

// MARK: - Register by mobile

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

    apiRequest({_ in}, baseURL: PositanoBaseURL, resource: resource, failure: failureHandler, completion: completion)
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

    apiRequest({_ in}, baseURL: PositanoBaseURL, resource: resource, failure: failureHandler, completion: completion)
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

    apiRequest({_ in}, baseURL: PositanoBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Register by mail

public func registerMailAddress(_ mailAddress: MailAddress, nickname: String, password: String, failureHandler: FailureHandler?, completion: @escaping (LoginUser) -> Void) {
    
    let requestParameters: JSONDictionary = [
        "username" : mailAddress.address,
        "password" : password,
        "email": mailAddress.address,
        "nickname": nickname,
    ]
    
    
    let parse: (JSONDictionary) -> LoginUser? = { data in
        return LoginUser.fromJSONDictionary(data)
    }
    
    let resource = jsonResource(path: "/1.1/users", method: .post, requestParameters: requestParameters, parse: parse)
    
    apiRequest({_ in}, baseURL: PositanoBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Login by mail

public func loginByMail(_ mailAddress: MailAddress, password: String, failureHandler: FailureHandler?, completion: @escaping (LoginUser) -> Void) {
    
    println("User login type is \(Config.clientType)")
    
    let requestParameters: JSONDictionary = [
        "username": mailAddress.address,
        "password": password,
        "client": Config.clientType,
    ]
    
    let parse: (JSONDictionary) -> LoginUser? = { data in
        return LoginUser.fromJSONDictionary(data)
    }
    
    let resource = jsonResource(path: "/1.1/login", method: .post, requestParameters: requestParameters, parse: parse)
    
    apiRequest({_ in}, baseURL: PositanoBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - User

public func userInfoOfUserWithUserID(_ userID: String, failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {
    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }
    
    let resource = authJsonResource(path: "/1.1/users/\(userID)", method: .get, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: PositanoBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// 自己的信息
public func userInfo(failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {
    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }
    
    let resource = authJsonResource(path: "/1.1/users/me", method: .get, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: PositanoBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

//该接口还在调试中
public func updateMyselfWithInfo(_ info: JSONDictionary, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {
    
    // nickname
    // avatar_url
    // username
    // latitude
    // longitude
    
    let parse: (JSONDictionary) -> Bool? = { data in
        return true
    }
    
    let resource = authJsonResource(path: "/1.1/users/me", method: .patch, requestParameters: info, parse: parse)
    
    apiRequest({_ in}, baseURL: PositanoBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func updateAvatarWithImageData(_ imageData: Data, failureHandler: FailureHandler?, completion: @escaping (String) -> Void) {
    
    guard let token = PositanoUserDefaults.v1AccessToken.value else {
        println("updateAvatarWithImageData no token")
        return
    }
    
    let headers: [String: String] = [
        "Authorization": "Token token=\"\(token)\"",
    ]
    
    let filename = "avatar.jpg"
    let url = URL(string: PositanoBaseURL.absoluteString + "/v1/user/set_avatar")!
    
    Alamofire.upload(multipartFormData: { multipartFormData in
        
        multipartFormData.append(imageData, withName: "avatar", fileName: filename, mimeType: "image/jpeg")
        
    }, to: url, method: .patch, headers: headers, encodingCompletion: { encodingResult in
        
        switch encodingResult {
            
        case .success(let upload, _, _):
            
            upload.responseJSON(completionHandler: { response in
                
                guard
                    let data = response.data,
                    let json = decodeJSON(data),
                    let avatarInfo = json["avatar"] as? JSONDictionary,
                    let avatarURLString = avatarInfo["url"] as? String else {
                        failureHandler?(.couldNotParseJSON, "failed parse JSON in updateAvatarWithImageData")
                        return
                }
                
                completion(avatarURLString)
            })
            
        case .failure(let encodingError):
            
            let failureHandler: FailureHandler = { (reason, errorMessage) in
                defaultFailureHandler(reason, errorMessage)
                failureHandler?(reason, errorMessage)
            }
            failureHandler(.other(nil), "\(encodingError)")
        }
    })
}
