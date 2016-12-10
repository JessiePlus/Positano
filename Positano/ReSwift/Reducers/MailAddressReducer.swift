//
//  MobilePhoneReducer.swift
//  Yep
//
//  Created by NIX on 16/8/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import ReSwift

struct MailAddressReducer: Reducer {

    typealias ReducerStateType = AppState

    func handleAction(action: Action, state: ReducerStateType?) -> ReducerStateType {

        var state = state ?? AppState()

        switch action {

        case let x as MailAddressUpdateAction:
            state.mailAddress = x.mailAddress

        default:
            break
        }

        return state
    }
}

