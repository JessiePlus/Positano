//
//  URL+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/11/9.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import Foundation
import PositanoKit

extension URL {

    fileprivate var allQueryItems: [URLQueryItem] {

        if let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems {
            return queryItems
        }

        return []
    }

    fileprivate func queryItemForKey(_ key: String) -> URLQueryItem? {

        let predicate = NSPredicate(format: "name=%@", key)
        return (allQueryItems as NSArray).filtered(using: predicate).first as? URLQueryItem
    }
    

    // make sure put it in last

}

extension URL {

    var yep_isNetworkURL: Bool {

        guard let scheme = scheme else {
            return false
        }

        switch scheme {
        case "http", "https":
            return true
        default:
            return false
        }
    }

    var yep_validSchemeNetworkURL: URL? {

        let scheme = self.scheme ?? ""

        if scheme.isEmpty {

            guard var URLComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
                return nil
            }

            URLComponents.scheme = "http"

            return URLComponents.url

        } else {
            if yep_isNetworkURL {
                return self

            } else {
                return nil
            }
        }
    }
}

