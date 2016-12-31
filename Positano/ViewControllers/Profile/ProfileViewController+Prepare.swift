//
//  ProfileViewController+Prepare.swift
//  Yep
//
//  Created by NIX on 16/7/4.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import PositanoKit

extension ProfileViewController {
    
    func prepare(withUser user: User) {
        
        if user.userID != PositanoUserDefaults.userID.value {
            self.profileUser = ProfileUser.userType(user)
        }
        
    }
    
    func prepare(withProfileUser profileUser: ProfileUser) {
        
        self.profileUser = profileUser
        
    }

}

