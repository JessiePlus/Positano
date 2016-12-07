//
//  UIStoryboard+Yep.swift
//  Yep
//
//  Created by NIX on 16/8/9.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension UIStoryboard {

    static var yep_show: UIStoryboard {
        return UIStoryboard(name: "Show", bundle: nil)
    }

    static var yep_main: UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }

    struct Scene {


        static var registerPickName: RegisterPickNameViewController {
            return UIStoryboard(name: "Intro", bundle: nil).instantiateViewController(withIdentifier: "RegisterPickNameViewController") as! RegisterPickNameViewController
        }

    }
}

