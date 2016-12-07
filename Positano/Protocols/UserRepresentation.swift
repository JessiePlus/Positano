//
//  UserRepresentation.swift
//  Yep
//
//  Created by NIX on 16/4/8.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import PositanoKit

protocol UserRepresentation {

    var userID: String { get }
    var nickname: String { get }
    var mentionedUsername: String? { get }
    var avatarURLString: String { get }
    var userIntroduction: String? { get }

    var lastSignInUnixTime: TimeInterval { get }
}

extension User: UserRepresentation {

    var userIntroduction: String? {
        return introduction.isEmpty ? nil : introduction
    }
}


