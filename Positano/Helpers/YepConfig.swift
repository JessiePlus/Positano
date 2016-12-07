//
//  YepConfig.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import CoreLocation
import Ruler
import Kingfisher

let avatarFadeTransitionDuration: TimeInterval = 0.0
let bigAvatarFadeTransitionDuration: TimeInterval = 0.15
let imageFadeTransitionDuration: TimeInterval = 0.2

let MediaOptionsInfos: KingfisherOptionsInfo = [
    .preloadAllGIFData,
    .backgroundDecode,
    .transition(ImageTransition.fade(imageFadeTransitionDuration))
]

final class YepConfig {

    static let minMessageTextLabelWidth: CGFloat = 20.0

    static let minMessageSampleViewWidth: CGFloat = 25.0

    static let maxFeedTextLength: Int = 300

    static let termsURLString = "http://privacy.soyep.com"
    static let appURLString = "itms-apps://itunes.apple.com/app/id" + "983891256"

    static let forcedHideActivityIndicatorTimeInterval: TimeInterval = 30

    static let dismissKeyboardDelayTimeInterval : TimeInterval = 0.45

    struct NotificationName {

        static let applicationDidBecomeActive = Notification.Name(rawValue: "YepConfig.Notification.applicationDidBecomeActive")
        static let oauthResult = Notification.Name(rawValue: "YepConfig.Notification.oauthResult")
        static let createdFeed = Notification.Name(rawValue: "YepConfig.Notification.createdFeed")
        static let deletedFeed = Notification.Name(rawValue: "YepConfig.Notification.deletedFeed")
        static let switchedToOthersFromContactsTab = Notification.Name(rawValue: "YepConfig.Notification.switchedToOthersFromContactsTab")
        static let blockedFeedsByCreator = Notification.Name(rawValue: "YepConfig.Notification.blockedFeedsByCreator")
        static let newFriendsInContacts = Notification.Name(rawValue: "YepConfig.Notification.newFriendsInContacts")

        static let updateDraftOfConversation = Notification.Name(rawValue: "YepConfig.Notification.updateDraftOfConversation")

        static let logout = Notification.Name(rawValue: "YepConfig.Notification.logout")
        static let newUsername = Notification.Name(rawValue: "YepConfig.Notification.newUsername")
    }

    class func getScreenRect() -> CGRect {
        return UIScreen.main.bounds
    }

    class func verifyCodeLength() -> Int {
        return 4
    }

    class func callMeInSeconds() -> Int {
        return 60
    }

    class func avatarMaxSize() -> CGSize {
        return CGSize(width: 414, height: 414)
    }

    class func chatCellAvatarSize() -> CGFloat {
        return 40.0
    }

    class func chatCellGapBetweenTextContentLabelAndAvatar() -> CGFloat {
        return 23
    }

    class func chatCellGapBetweenWallAndAvatar() -> CGFloat {
        return 15
    }

    class func chatTextGapBetweenWallAndContentLabel() -> CGFloat {
        return 50
    }

    class func messageImageCompressionQuality() -> CGFloat {
        return 0.95
    }

    class func audioSampleWidth() -> CGFloat {
        return 2
    }

    class func audioSampleGap() -> CGFloat {
        return 1
    }

    class func editProfileAvatarSize() -> CGFloat {
        return 100
    }

    struct AudioRecord {
        static let shortestDuration: TimeInterval = 1.0
        static let longestDuration: TimeInterval = 60
    }

    struct Profile {
        static let leftEdgeInset: CGFloat = Ruler.iPhoneHorizontal(20, 38, 40).value
        static let rightEdgeInset: CGFloat = leftEdgeInset
        static let introductionFont = UIFont.systemFont(ofSize: 14)
    }

    struct Settings {
        static let userCellAvatarSize: CGFloat = 80

        static let introFont: UIFont = {
            return UIFont.systemFont(ofSize: 12, weight: UIFontWeightLight)
        }()

        static let introInset: CGFloat = 20 + userCellAvatarSize + 20 + 10 + 11 + 20
    }

    struct EditProfile {

        static let infoFont = UIFont.systemFont(ofSize: 15, weight: UIFontWeightLight)
        static let infoInset: CGFloat = 20 + 20
    }


    struct ContactsCell {
        static let separatorInset = UIEdgeInsets(top: 0, left: 85, bottom: 0, right: 0)
    }

    struct SearchTableView {
        static let separatorColor = UIColor(red: 245/255.0, green: 245/255.0, blue: 245/255.0, alpha: 1)
        static let backgroundColor = UIColor(red: 250/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1)
    }

    struct SearchedItemCell {
        static let separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)

        static let nicknameFont = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
        static let nicknameColor = UIColor.darkGray
        static let usernameFont = UIFont.systemFont(ofSize: 12)
        static let usernameColor = UIColor.lightGray
        static let messageFont = UIFont.systemFont(ofSize: 12)
        static let messageColor = UIColor.yep_mangmorGrayColor()
        static let logoTintColor = UIColor.yep_mangmorGrayColor()
    }






    struct Location {
        static let distanceThreshold: CLLocationDistance = 500
    }

    struct ChinaSocialNetwork {

        struct WeChat {

            static let appID = "wx10f099f798871364"

            static let sessionType = "com.Catch-Inc.Yep.WeChat.Session"
            static let sessionTitle = NSLocalizedString("WeChat Session", comment: "")
            static let sessionImage = UIImage.yep_wechatSession
            
            static let timelineType = "com.Catch-Inc.Yep.WeChat.Timeline"
            static let timelineTitle = NSLocalizedString("WeChat Timeline", comment: "")
            static let timelineImage = UIImage.yep_wechatTimeline
        }
    }


    struct Search {
        static let delayInterval: TimeInterval = 0.5
    }

    struct Domain {
        static let feed = "Catch-Inc.Yep.Feed"
        static let user = "Catch-Inc.Yep.User"
    }
}

