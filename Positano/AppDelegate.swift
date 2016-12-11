//
//  AppDelegate.swift
//  Positano
//
//  Created by dinglin on 2016/11/28.
//  Copyright © 2016年 dinglin. All rights reserved.
//

import UIKit
import PositanoKit
import PositanoNetworking
import Fabric
import AVFoundation
import RealmSwift
import MonkeyKing
import Navi
import Appsee
import CoreSpotlight

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var deviceToken: Data? {
        didSet {
            guard let deviceToken = deviceToken else { return }
            guard let pusherID = PositanoUserDefaults.pusherID.value else { return }
            
            registerThirdPartyPushWithDeciveToken(deviceToken, pusherID: pusherID)
        }
    }
    var notRegisteredThirdPartyPush = true
    
    fileprivate var isFirstActive = true

    
    // MARK: Life Circle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Realm.Configuration.defaultConfiguration = realmConfig()
        
        configurePositanoKit()
        configurePositanoNetworking()
        
        _ = delay(0.5) {
            //Fabric.with([Crashlytics.self])
//            Fabric.with([Appsee.self])
            
            let apsForProduction = true
            JPUSHService.setLogOFF()
            JPUSHService.setup(withOption: launchOptions, appKey: "xxxxxxxxxxxxxxxxxxxxxxxx", channel: "AppStore", apsForProduction: apsForProduction)
        }
        
        let _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        // 全局的外观自定义
        customAppearce()
        
        let isLogined = PositanoUserDefaults.isLogined
        
        if isLogined {
            
            // 记录启动通知类型
            
        } else {
            startShowStory()
        }
        
        PositanoUserDefaults.appLaunchCount.value += 1
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
        println("Did Active")
        
        if !isFirstActive {
            
        } else {
            // 确保该任务不是被 Remote Notification 激活 App 的时候执行
            sync()
            
            // 延迟一些，减少线程切换压力
            _ = delay(2) { [weak self] in
//                self?.startFaye()
            }
        }
        
        clearNotifications()
        
        NotificationCenter.default.post(name: YepConfig.NotificationName.applicationDidBecomeActive, object: nil)
        
        isFirstActive = false
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        println("Resign active")
        
        clearNotifications()
        
        // dynamic shortcut items
        
        // index searchable items
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        println("Enter background")
        
        NotificationCenter.default.post(name: YepConfig.NotificationName.updateDraftOfConversation, object: nil)
        
        #if DEBUG
            //clearUselessRealmObjects() // only for test
        #endif
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        println("Will Foreground")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        clearUselessRealmObjects()
    }
    
    // MARK: APNs
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        // 纪录下来，用于初次登录或注册有 pusherID 后，或“注销再登录”
        self.deviceToken = deviceToken
    }
    
    // MARK: Shortcuts

    
    // MARK: Open URL
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        if url.absoluteString.contains("/auth/success") {
            NotificationCenter.default.post(name: YepConfig.NotificationName.oauthResult, object: NSNumber(value: 1 as Int32))
            
        } else if url.absoluteString.contains("/auth/failure") {
            NotificationCenter.default.post(name: YepConfig.NotificationName.oauthResult, object: NSNumber(value: 0 as Int32))
        }
        
        if MonkeyKing.handleOpenURL(url) {
            return true
        }
        
        return false
    }
    
    // MARK: Public
    
    var inMainStory: Bool = true
    
    func startShowStory() {
        return
        let storyboard = UIStoryboard.yep_show
        window?.rootViewController = storyboard.instantiateInitialViewController()
        
        inMainStory = false
    }
    
    func startMainStory() {
        
        let storyboard = UIStoryboard.yep_main
        window?.rootViewController = storyboard.instantiateInitialViewController()
        
        inMainStory = true
    }
    
    func sync() {
        
        guard PositanoUserDefaults.isLogined else {
            return
        }
        
    }
    
    
    func registerThirdPartyPushWithDeciveToken(_ deviceToken: Data, pusherID: String) {
        
        guard notRegisteredThirdPartyPush else {
            return
        }
        
        notRegisteredThirdPartyPush = false
        
        JPUSHService.registerDeviceToken(deviceToken)
        
        let callbackSelector = #selector(AppDelegate.tagsAliasCallBack(_:tags:alias:))
        JPUSHService.setTags(Set(["iOS"]), alias: pusherID, callbackSelector: callbackSelector, object: self)
        
        println("registerThirdPartyPushWithDeciveToken: \(deviceToken), pusherID: \(pusherID)")
    }
    
    func unregisterThirdPartyPush() {
        
        defer {
            SafeDispatch.async { [weak self] in
                self?.clearNotifications()
            }
        }
        
        guard !notRegisteredThirdPartyPush else {
            return
        }
        
        notRegisteredThirdPartyPush = true
        
        JPUSHService.setAlias(nil, callbackSelector: nil, object: nil)
        
        println("unregisterThirdPartyPush")
    }
    
    @objc fileprivate func tagsAliasCallBack(_ iResCode: CInt, tags: NSSet, alias: NSString) {
        
        println("tagsAliasCallback: \(iResCode), \(tags), \(alias)")
    }
    
    // MARK: Private
    
    fileprivate func clearNotifications() {
        
        let application = UIApplication.shared
        
        application.applicationIconBadgeNumber = 1
        println("a badge: \(application.applicationIconBadgeNumber)")
        defer {
            application.applicationIconBadgeNumber = 0
            println("b badge: \(application.applicationIconBadgeNumber)")
        }
        application.cancelAllLocalNotifications()
    }
    
    fileprivate lazy var sendMessageSoundEffect: YepSoundEffect = {
        
        let bundle = Bundle.main
        guard let fileURL = bundle.url(forResource: "bub3", withExtension: "caf") else {
            fatalError("YepSoundEffect: file no found!")
        }
        return YepSoundEffect(fileURL: fileURL)
    }()
    
    fileprivate func configurePositanoKit() {
        
        PositanoKit.Config.updatedAccessTokenAction = {
            
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                // 注册或初次登录时同步数据的好时机
                appDelegate.sync()
                
                // 也是注册或初次登录时启动 Faye 的好时机
//                appDelegate.startFaye()
            }
        }
        
        PositanoKit.Config.updatedPusherIDAction = { pusherID in
            
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                if let deviceToken = appDelegate.deviceToken {
                    appDelegate.registerThirdPartyPushWithDeciveToken(deviceToken, pusherID: pusherID)
                }
            }
        }
        
        PositanoKit.Config.sentMessageSoundEffectAction = { [weak self] in
            
            self?.sendMessageSoundEffect.play()
        }
        
        PositanoKit.Config.timeAgoAction = { date in
            
            return date.timeAgo
        }
        
        PositanoKit.Config.isAppActive = {
            
            let state = UIApplication.shared.applicationState
            return state == .active
        }
    }
    
    fileprivate func configurePositanoNetworking() {
        
        PositanoNetworking.Manager.accessToken = {
            
            return PositanoUserDefaults.v1AccessToken.value
        }
        
        PositanoNetworking.Manager.authFailedAction = { statusCode, host in
            
            // 确保是自家服务
            guard host == PositanoBaseURL.host else {
                return
            }
            
            switch statusCode {
                
            case 401:
                SafeDispatch.async {
                    PositanoUserDefaults.maybeUserNeedRelogin(prerequisites: {
                        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, appDelegate.inMainStory else {
                            return false
                        }
                        return true
                        
                    }, confirm: { [weak self] in
                        self?.unregisterThirdPartyPush()
                        
                        cleanRealmAndCaches()
                        
                        if let rootViewController = self?.window?.rootViewController {
                            YepAlert.alert(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("User authentication error, you need to login again!", comment: ""), dismissTitle: NSLocalizedString("Relogin", comment: ""), inViewController: rootViewController, withDismissAction: { [weak self] in
                                
                                self?.startShowStory()
                            })
                        }
                    })
                }
                
            default:
                break
            }
        }
        
        PositanoNetworking.Manager.networkActivityCountChangedAction = { count in
            
            SafeDispatch.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = (count > 0)
            }
        }
    }

    

    fileprivate func customAppearce() {
        
        window?.backgroundColor = UIColor.white
        
        // Global Tint Color
        
        window?.tintColor = UIColor.yepTintColor()
        window?.tintAdjustmentMode = .normal
        
        // NavigationBar Item Style
        
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.yepTintColor()], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.yepTintColor().withAlphaComponent(0.3)], for: .disabled)
        
        // NavigationBar Title Style
        
        let shadow: NSShadow = {
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.lightGray
            shadow.shadowOffset = CGSize(width: 0, height: 0)
            return shadow
        }()
        let textAttributes: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.yepNavgationBarTitleColor(),
            NSShadowAttributeName: shadow,
            NSFontAttributeName: UIFont.navigationBarTitleFont()
        ]
        UINavigationBar.appearance().titleTextAttributes = textAttributes
        UINavigationBar.appearance().barTintColor = UIColor.white
        
        // TabBar
        
        UITabBar.appearance().tintColor = UIColor.yepTintColor()
        UITabBar.appearance().barTintColor = UIColor.white
    }
}

