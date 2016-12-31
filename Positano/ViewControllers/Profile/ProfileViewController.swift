//
//  SettingsViewController.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import SafariServices
import CoreLocation
import RealmSwift
import PositanoNetworking
import PositanoKit
import MonkeyKing
import Navi
import Kingfisher
import Proposer

final class ProfileViewController: BaseViewController {

    var profileUser: ProfileUser?
    fileprivate var profileUserIsMe = true {
        didSet {
            
        }
    }

    @IBOutlet fileprivate weak var settingsTableView: UITableView! {
        didSet {
            settingsTableView.registerNibOf(SettingsUserCell.self)
            settingsTableView.registerNibOf(SettingsMoreCell.self)
            settingsTableView.registerClassOf(TitleSwitchCell.self)
        }
    }

    fileprivate var introduction: String {
        get {
            return PositanoUserDefaults.introduction.value ?? String.trans_promptNoSelfIntroduction
        }
    }

    struct Annotation {
        let name: String
        let segue: String
    }

    fileprivate let moreAnnotations: [Annotation] = [
        Annotation(
            name: String.trans_titleNotificationsAndPrivacy,
            segue: "showNotifications"
        ),
        Annotation(
            name: String.trans_titleFeedback,
            segue: "showFeedback"
        ),
        Annotation(
            name: String.trans_titleAbout,
            segue: "showAbout"
        ),
    ]

    fileprivate let introAttributes = [NSFontAttributeName: YepConfig.Settings.introFont]

    fileprivate struct Listener {
        let nickname: String
        let introduction: String
        let avatar: String
        let blog: String
    }
    
    fileprivate lazy var listener: Listener = {
        
        let suffix = UUID().uuidString
        
        return Listener(
            nickname: "Profile.Title" + suffix,
            introduction: "Profile.introductionText" + suffix,
            avatar: "Profile.Avatar" + suffix,
            blog: "Profile.Blog" + suffix
        )
    }()

    deinit {
        NotificationCenter.default.removeObserver(self)
        
        PositanoUserDefaults.nickname.removeListenerWithName(listener.nickname)
        PositanoUserDefaults.introduction.removeListenerWithName(listener.introduction)
        PositanoUserDefaults.avatarURLString.removeListenerWithName(listener.avatar)
        
        settingsTableView?.delegate = nil
        
        println("deinit Profile")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Profile", comment: "")
        
        
        
        
        
        
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) {
                    settingsTableView.panGestureRecognizer.require(toFail: recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }
        
        
        
        
        
        
        
        //有两种情况，一种是访问自己的个人中心，另一种是访问别人的个人中心
        if let profileUser = profileUser {
            //访问别人的个人中心
            // 如果是 DiscoveredUser，也可能是好友或已存储的陌生人，查询本地 User 替换
            
            switch profileUser {
                
            case .discoveredUserType(let discoveredUser):
                
                guard let realm = try? Realm() else {
                    break
                }
                
                if let user = userWithUserID(discoveredUser.userID, inRealm: realm) {
                    
                    self.profileUser = ProfileUser.userType(user)
                    
                    //更新界面
                    updateProfileTableView()
                }
                
            default:
                break
            }
            
            if let realm = try? Realm() {
                
                if let user = userWithUserID(profileUser.userID, inRealm: realm) {
                    

                }
                
            }
            
        } else {
            
            // 为空的话就要显示自己
            syncMyInfoAndDoFurtherAction {
                
                guard let me = me() else {
                    return
                }
                
            }
            
            if let me = me() {
                
                profileUser = ProfileUser.userType(me)
                
                //更新界面
                updateProfileTableView()
            }
        }
        
        //之后，profileUser已经有数据了
        profileUserIsMe = profileUser?.isMe ?? false
        
        if let profileUser = profileUser {
            
            switch profileUser {
                
            case .discoveredUserType(let discoveredUser):
                title = discoveredUser.nickname
                
            case .userType(let user):
                title = user.nickname
                
                if user.isMe {
                    PositanoUserDefaults.nickname.bindListener(listener.nickname) { [weak self] nickname in
                        SafeDispatch.async {
                            
                        }
                    }
                    
                    PositanoUserDefaults.avatarURLString.bindListener(listener.avatar) { [weak self] avatarURLString in
                        SafeDispatch.async {
                        //更新头像
                            
                            
                        }
                    }
                    
                    
                    NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.updateUIForUsername(_:)), name: YepConfig.NotificationName.newUsername, object: nil)
                }
            }
            
            if !profileUserIsMe {
                
                let userID = profileUser.userID
                
                userInfoOfUserWithUserID(userID, failureHandler: nil, completion: { userInfo in
                    //println("userInfoOfUserWithUserID \(userInfo)")
                    
                    // 对非好友来说，必要
                    
                    SafeDispatch.async { [weak self] in
                        
                        if let realm = try? Realm() {
                            let _ = try? realm.write {
                                updateUserWithUserID(userID, useUserInfo: userInfo, inRealm: realm)
                            }
                        }
                        
                        if let discoveredUser = parseDiscoveredUser(userInfo) {
                            switch profileUser {
                            case .discoveredUserType:
                                self?.profileUser = ProfileUser.discoveredUserType(discoveredUser)
                            default:
                                break
                            }
                        }
                        
                        self?.updateProfileTableView()
                    }
                })
            }
            
        }
        
        if profileUserIsMe {
            
            proposeToAccess(.location(.whenInUse), agreed: {
                YepLocationService.turnOn()
                
                YepLocationService.sharedManager.afterUpdatedLocationAction = { [weak self] newLocation in
                    //更新地理位置
                    
                }
                
            }, rejected: {
                println("Yep can NOT get Location. :[\n")
            })
        }
        
        if profileUserIsMe {
            remindUserToReview()
        }
        
        #if DEBUG
            //view.addSubview(profileFPSLabel)
        #endif
  
    }
    
    fileprivate func updateProfileTableView() {
        SafeDispatch.async { [weak self] in
            self?.settingsTableView.reloadData()
            self?.settingsTableView.layoutIfNeeded()
        }
    }
    
    @objc fileprivate func updateUIForUsername(_ sender: Notification) {
        updateProfileTableView()
    }
}



extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {

    fileprivate enum Section: Int {
        case user
        case ui
        case more

        static let count = 3
    }

    fileprivate enum UIRow: Int {
        case tabBarTitleEnabled
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError("Invalide section!")
        }

        switch section {
        case .user:
            return 1
        case .ui:
            return 1
        case .more:
            return moreAnnotations.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalide section!")
        }

        switch section {

        case .user:
            let cell: SettingsUserCell = tableView.dequeueReusableCell()
            return cell

        case .ui:
            guard let row = UIRow(rawValue: indexPath.row) else {
                fatalError("Invalide row!")
            }

            switch row {
            case .tabBarTitleEnabled:
                let cell: TitleSwitchCell = tableView.dequeueReusableCell()
                cell.titleLabel.text = NSLocalizedString("Show Tab Bar Title", comment: "")
                
                
                
                //暂时注释2016-12-31 11:19:45
                
//                cell.toggleSwitch.isOn = PositanoUserDefaults.tabBarItemTextEnabled.value ?? !(PositanoUserDefaults.appLaunchCount.value > PositanoUserDefaults.appLaunchCountThresholdForTabBarItemTextEnabled)
//                cell.toggleSwitchStateChangedAction = { on in
//                    PositanoUserDefaults.tabBarItemTextEnabled.value = on
//                }
//                
                
                
                
                return cell
            }

        case .more:
            let cell: SettingsMoreCell = tableView.dequeueReusableCell()
            let annotation = moreAnnotations[indexPath.row]
            cell.annotationLabel.text = annotation.name
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalide section!")
        }

        switch section {

        case .user:

            let tableViewWidth = settingsTableView.bounds.width
            let introLabelMaxWidth = tableViewWidth - YepConfig.Settings.introInset

            let rect = introduction.boundingRect(with: CGSize(width: introLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: introAttributes, context: nil)

            let height = max(20 + 8 + 22 + 8 + ceil(rect.height) + 20, 20 + YepConfig.Settings.userCellAvatarSize + 20)

            return height

        case .ui:
            return 60

        case .more:
            return 60
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalide section!")
        }

        switch section {

        case .user:
            performSegue(withIdentifier: "showEditProfile", sender: nil)

        case .ui:
            break

        case .more:
            let annotation = moreAnnotations[indexPath.row]
            let segue = annotation.segue
            performSegue(withIdentifier: segue, sender: nil)
        }
    }
}

