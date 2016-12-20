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
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!


    var updatePrettyColorAction: ((UIColor) -> Void)?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

    }

    func configureWithUser(_ user: User) {

        updateAvatarWithAvatarURLString(user.avatarURLString)
    }

    func updateAvatarWithAvatarURLString(_ avatarURLString: String) {

        if avatarImageView.image == nil {
            avatarImageView.alpha = 0
        }

        let avatarStyle = AvatarStyle.original
        let plainAvatar = PlainAvatar(avatarURLString: avatarURLString, avatarStyle: avatarStyle)

        AvatarPod.wakeAvatar(plainAvatar) { [weak self] finished, image, _ in

            if finished {

            }

            SafeDispatch.async {
                self?.avatarImageView.image = image

                let avatarAvarageColor = image.yep_avarageColor
                let prettyColor = avatarAvarageColor.yep_profilePrettyColor
                self?.locationLabel.textColor = prettyColor

                self?.updatePrettyColorAction?(prettyColor)

                UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: { [weak self] in
                    self?.avatarImageView.alpha = 1
                }, completion: nil)
            }
        }
    }

    // MARK: Notifications
    
    func updateAddress() {
        locationLabel.text = YepLocationService.sharedManager.address
    }
}

