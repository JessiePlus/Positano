//
//  ProfileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
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


final class ProfileViewController: SegueViewController, CanScrollsToTop {
    
    var profileUser: ProfileUser?
    
    fileprivate var profileUserIsMe = true {
        didSet {
            if !profileUserIsMe {
                sayHiView.tapAction = { [weak self] in
                    self?.sayHi()
                }
                
                profileTableView.contentInset.bottom = sayHiView.bounds.height
                
            } else {
                sayHiView.isHidden = true
                
                let settingsBarButtonItem = UIBarButtonItem(image: UIImage.yep_iconSettings, style: .plain, target: self, action: #selector(ProfileViewController.showSettings(_:)))
                
                customNavigationItem.rightBarButtonItem = settingsBarButtonItem
                
            }
        }
    }
    
    
    
    #if DEBUG
    private lazy var profileFPSLabel: FPSLabel = {
    let label = FPSLabel()
    return label
    }()
    #endif
    
    fileprivate var statusBarShouldLight = false
    
    fileprivate var noNeedToChangeStatusBar = false

    @IBOutlet fileprivate weak var profileTableView: UITableView! {
        didSet {
            profileTableView.registerNibOf(ProfileHeaderCell.self)
            profileTableView.registerNibOf(ProfileFooterCell.self)

//            profileTableView.registerHeaderNibOf(ProfileSectionHeaderReusableView.self)
//            profileTableView.registerFooterClassOf(UICollectionReusableView.self)
            
            profileTableView.alwaysBounceVertical = true
        }
    }
    
    // CanScrollsToTop
    var scrollView: UIScrollView? {
        return profileTableView
    }
    
    @IBOutlet fileprivate weak var sayHiView: BottomButtonView!
    
    fileprivate lazy var customNavigationItem: UINavigationItem = UINavigationItem(title: "Details")
    fileprivate lazy var customNavigationBar: UINavigationBar = {
        
        let bar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 64))
        
        bar.tintColor = UIColor.white
        bar.tintAdjustmentMode = .normal
        bar.alpha = 0
        bar.setItems([self.customNavigationItem], animated: false)
        
        bar.backgroundColor = UIColor.clear
        bar.isTranslucent = true
        bar.shadowImage = UIImage()
        bar.barStyle = UIBarStyle.blackTranslucent
        bar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        
        let textAttributes = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont.navigationBarTitleFont()
        ]
        
        bar.titleTextAttributes = textAttributes
        
        return bar
    }()
    
    fileprivate lazy var tableViewWidth: CGFloat = {
        return self.profileTableView.bounds.width
    }()
    fileprivate lazy var sectionLeftEdgeInset: CGFloat = {
        return YepConfig.Profile.leftEdgeInset
    }()
    fileprivate lazy var sectionRightEdgeInset: CGFloat = {
        return YepConfig.Profile.rightEdgeInset
    }()
    fileprivate lazy var sectionBottomEdgeInset: CGFloat = {
        return 0
    }()
    
    fileprivate var footerCellHeight: CGFloat {
        return 60
    }
    
    fileprivate struct Listener {
        let nickname: String
        let avatar: String
    }
    
    fileprivate lazy var listener: Listener = {
        
        let suffix = UUID().uuidString
        
        return Listener(
            nickname: "Profile.Title" + suffix,
            avatar: "Profile.Avatar" + suffix
        )
    }()
    
    // MARK: Life cycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        PositanoUserDefaults.nickname.removeListenerWithName(listener.nickname)
        PositanoUserDefaults.avatarURLString.removeListenerWithName(listener.avatar)
        
        profileTableView?.delegate = nil
        
        println("deinit Profile")
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        if statusBarShouldLight {
            return UIStatusBarStyle.lightContent
        } else {
            return UIStatusBarStyle.default
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("Profile", comment: "")
        
        view.addSubview(customNavigationBar)
        
        automaticallyAdjustsScrollViewInsets = false
        
        ImageCache.default.calculateDiskCacheSize { (size) in
            let cacheSize = Double(size)/1000000
            println(String(format: "Kingfisher.ImageCache cacheSize: %.2f MB", cacheSize))
            
            if cacheSize > 300 {
                ImageCache.default.cleanExpiredDiskCache()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.cleanForLogout(_:)), name: YepConfig.NotificationName.logout, object: nil)
        
        
        if let profileUser = profileUser {
            
            // 如果是 DiscoveredUser，也可能是好友或已存储的陌生人，查询本地 User 替换
            
            if let realm = try? Realm() {
                
                if let user = userWithUserID(profileUser.userID, inRealm: realm) {
                    
                    if user.friendState == UserFriendState.normal.rawValue {
                        sayHiView.title = String.trans_titleChat
                    }
                }
                
            }
            
        } else {
            
            // 为空的话就要显示自己
            
            if let me = me() {
                profileUser = ProfileUser.userType(me)
                
                
                updateProfileTableView()
            }
        }
        
        profileUserIsMe = profileUser?.isMe ?? false
        
        //Make sure when pan edge screen collectionview not scroll
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) {
                    profileTableView.panGestureRecognizer.require(toFail: recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }
        
        if let tabBarController = tabBarController {
            profileTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: tabBarController.tabBar.bounds.height, right: 0)
        }
        
        if let profileUser = profileUser {
            
            switch profileUser {
            case .userType(let user):
                customNavigationItem.title = user.nickname
                
                if user.friendState == UserFriendState.me.rawValue {
                    PositanoUserDefaults.nickname.bindListener(listener.nickname) { [weak self] nickname in
                        SafeDispatch.async {
                            self?.customNavigationItem.title = nickname
                            self?.updateProfileTableView()
                        }
                    }
                    
                    PositanoUserDefaults.avatarURLString.bindListener(listener.avatar) { [weak self] avatarURLString in
                        SafeDispatch.async {
                            let indexPath = IndexPath(item: 0, section: Section.header.rawValue)
                            if let cell = self?.profileTableView.cellForRow(at: indexPath) as? ProfileHeaderCell {
                                if let avatarURLString = avatarURLString {
                                    cell.updateAvatarWithAvatarURLString(avatarURLString)
                                }
                            }
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
                        
                        self?.updateProfileTableView()
                    }
                })
            }
        }
        
        if profileUserIsMe {
            
            proposeToAccess(.location(.whenInUse), agreed: {
                YepLocationService.turnOn()
                
                YepLocationService.sharedManager.afterUpdatedLocationAction = { [weak self] newLocation in
                    
                    let indexPath = IndexPath(item: 0, section: Section.footer.rawValue)
                    if let cell = self?.profileTableView.cellForRow(at: indexPath) as? ProfileFooterCell {
                        cell.location = newLocation
                    }
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        customNavigationBar.alpha = 1.0
        
        statusBarShouldLight = false
        
        if noNeedToChangeStatusBar {
            statusBarShouldLight = true
        }
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        statusBarShouldLight = true
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: Actions
    
    @objc fileprivate func showSettings(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "showSettings", sender: self)
    }
    
    func setBackButtonWithTitle() {
        let backBarButtonItem = UIBarButtonItem(image: UIImage.yep_iconBack, style: .plain, target: self, action: #selector(ProfileViewController.back(_:)))
        
        customNavigationItem.leftBarButtonItem = backBarButtonItem
    }
    
    @objc fileprivate func back(_ sender: AnyObject) {
        if let presentingViewController = presentingViewController {
            presentingViewController.dismiss(animated: true, completion: nil)
        } else {
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    @objc fileprivate func cleanForLogout(_ sender: Notification) {
        profileUser = nil
    }
    
    @objc fileprivate func updateUIForUsername(_ sender: Notification) {
        updateProfileTableView()
    }
    
    
    
    
    fileprivate func updateProfileTableView() {
        SafeDispatch.async { [weak self] in
            self?.profileTableView.reloadData()
            self?.profileTableView.layoutIfNeeded()
        }
    }
    
    fileprivate func sayHi() {
        
        if let profileUser = profileUser {
            
            guard let realm = try? Realm() else {
                return
            }
            
            switch profileUser {
            case .userType(let user):
                
                if user.friendState != UserFriendState.me.rawValue {
                    
                }
            }
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
            
        case "showProfileWithUsername":
            
            let vc = segue.destination as! ProfileViewController
            
            let profileUser = sender as! ProfileUser
            vc.prepare(withProfileUser: profileUser)
            
        default:
            break
        }
    }
}

// MARK: UITableView

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    enum Section: Int {
        case header
        case footer
        case separationLine
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let section = Section(rawValue: section) else {
            fatalError()
        }
        
        switch section {
            
        case .header:
            return 1
            
        case .footer:
            return 1
            
        case .separationLine:
            return 1
            
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }
        
        switch section {
            
        case .header:
            let cell: ProfileHeaderCell = tableView.dequeueReusableCell()
            
            if let profileUser = profileUser {
                switch profileUser {
                case .userType(let user):
                    cell.configureWithUser(user)
                }
            }
            
            cell.updatePrettyColorAction = { [weak self] prettyColor in
                self?.customNavigationBar.tintColor = prettyColor
                
                let textAttributes = [
                    NSForegroundColorAttributeName: prettyColor,
                    NSFontAttributeName: UIFont.navigationBarTitleFont()
                ]
                self?.customNavigationBar.titleTextAttributes = textAttributes
            }
            
            return cell
            
        case .footer://介绍
            let cell: ProfileFooterCell = tableView.dequeueReusableCell()
            
            if let profileUser = profileUser {
                cell.configureWithProfileUser(profileUser)
                
                cell.tapUsernameAction = { [weak self] username in
//                    self?.tryShowProfileWithUsername(username)
                }
            }
            
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }
        
        switch section {
            
        case .header:
            return tableViewWidth
            
        case .footer:
            return footerCellHeight
        
        default:
            return 0

        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }
        
        switch section {

        default:
            break
        }
    }
}


