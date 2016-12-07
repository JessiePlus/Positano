//
//  UIViewController+Yep.swift
//  Yep
//
//  Created by NIX on 15/7/27.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import SafariServices
import AutoReview
import MonkeyKing
import PositanoKit

// MARK: - Heights

extension UIViewController {

    var statusBarHeight: CGFloat {

        if let window = view.window {
            let statusBarFrame = window.convert(UIApplication.shared.statusBarFrame, to: view)
            return statusBarFrame.height

        } else {
            return 0
        }
    }

    var navigationBarHeight: CGFloat {

        if let navigationController = navigationController {
            return navigationController.navigationBar.frame.height

        } else {
            return 0
        }
    }

    var topBarsHeight: CGFloat {
        return statusBarHeight + navigationBarHeight
    }
}

// MARK: - openURL

extension UIViewController {

    func yep_openURL(_ url: URL) {

        if let url = url.yep_validSchemeNetworkURL {
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: true, completion: nil)

        } else {
            YepAlert.alertSorry(message: String.trans_promptInvalidURL, inViewController: self)
        }
    }
}

// MARK: - Review

extension UIViewController {

    func remindUserToReview() {

        let remindAction: ()->() = { [weak self] in

            guard self?.view.window != nil else {
                return
            }

            let info = AutoReview.Info(
                appID: "983891256",
                title: NSLocalizedString("Review Yep", comment: ""),
                message: String.trans_promptAskForReview,
                doNotRemindMeInThisVersionTitle: String.trans_titleDoNotRemindMeInThisVersion,
                maybeNextTimeTitle: String.trans_titleMaybeNextTime,
                confirmTitle: NSLocalizedString("Review now", comment: "")
            )
            self?.autoreview_tryReviewApp(withInfo: info)
        }

        _ = delay(3, work: remindAction)
    }
}

// MARK: - Alert

extension UIViewController {

    func alertSaveFileFailed() {
        YepAlert.alertSorry(message: NSLocalizedString("Yep can not save files!\nProbably not enough storage space.", comment: ""), inViewController: self)
    }
}

