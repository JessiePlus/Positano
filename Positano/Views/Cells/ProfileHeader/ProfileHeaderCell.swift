//
//  ProfileHeaderCell.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import CoreLocation
import PositanoKit
import Proposer
import Navi

final class ProfileHeaderCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var userID: String? {
        didSet {
            
        }
    }
    
    var profileUserIsMe = false {
        didSet {
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    func configureWithProfileUser(_ profileUser: ProfileUser) {
        
        userID = profileUser.userID
        profileUserIsMe = profileUser.isMe
        
        configureWithNickname(profileUser.nickname, username: profileUser.username)
        
    }
    
    fileprivate func configureWithNickname(_ nickname: String?, username: String?) {
        
        nicknameLabel.text = nickname
        
        if let username = username {
            usernameLabel.text = "@" + username
        } else {
            usernameLabel.text = String.trans_promptNoUsername
        }
        
    }

    // MARK: Notifications
    
    func updateAddress() {
//        locationLabel.text = YepLocationService.sharedManager.address
    }
}

