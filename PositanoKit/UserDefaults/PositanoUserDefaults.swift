//
//  PositanoUserDefaults.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import CoreSpotlight
import CoreLocation
//import RealmSwift



public struct Listener<T>: Hashable {

    let name: String

    public typealias Action = (T) -> Void
    let action: Action

    public var hashValue: Int {
        return name.hashValue
    }
}

public func ==<T>(lhs: Listener<T>, rhs: Listener<T>) -> Bool {
    return lhs.name == rhs.name
}

final public class Listenable<T> {

    public var value: T {
        didSet {
            setterAction(value)

            for listener in listenerSet {
                listener.action(value)
            }
        }
    }

    public typealias SetterAction = (T) -> Void
    var setterAction: SetterAction

    var listenerSet = Set<Listener<T>>()

    public func bindListener(_ name: String, action: @escaping Listener<T>.Action) {
        let listener = Listener(name: name, action: action)

        listenerSet.insert(listener)
    }

    public func bindAndFireListener(_ name: String, action: @escaping Listener<T>.Action) {
        bindListener(name, action: action)

        action(value)
    }

    public func removeListenerWithName(_ name: String) {
        for listener in listenerSet {
            if listener.name == name {
                listenerSet.remove(listener)
                break
            }
        }
    }

    public func removeAllListeners() {
        listenerSet.removeAll(keepingCapacity: false)
    }

    public init(_ v: T, setterAction action: @escaping SetterAction) {
        value = v
        setterAction = action
    }
}

final public class PositanoUserDefaults {

    static let defaults = UserDefaults(suiteName: Config.appGroupID)!

    public static let appLaunchCountThresholdForTabBarItemTextEnabled: Int = 30

    public static var isLogined: Bool {

//        if let _ = PositanoUserDefaults.v1AccessToken.value {
//            return true
//        } else {
            return false
//        }
    }

    // MARK: ReLogin

    public class func cleanAllUserDefaults() {

        do {

        }

        do { // manually reset

            defaults.synchronize()
        }

        do { // reset standardUserDefaults
            let standardUserDefaults = UserDefaults.standard
            standardUserDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            standardUserDefaults.synchronize()
        }
    }


}

