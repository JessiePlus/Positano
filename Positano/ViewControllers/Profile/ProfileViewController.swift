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
        static let Introduction = "SettingsViewController.Introduction"
    }

    deinit {
        PositanoUserDefaults.introduction.removeListenerWithName(Listener.Introduction)

        settingsTableView?.delegate = nil

        println("deinit Settings")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Profile", comment: "")
        

        
        PositanoUserDefaults.introduction.bindAndFireListener(Listener.Introduction) { [weak self] introduction in
            SafeDispatch.async {
                self?.settingsTableView.reloadData()
            }
        }
        
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
            
        } else {
            //访问自己的个人中心，从数据库读取自己的信息
            if let me = me() {
                profileUser = ProfileUser.userType(me)
                
                println("loginUser: \(profileUser)")

            }
        }
        //之后，profileUser已经有数据了
        profileUserIsMe = profileUser?.isMe ?? false
        
        //根据profile配置界面
        
        
        
        
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

