//
//  DNSAlert.swift
//  IDDAlert
//
//  Created by Jesse Deda on 3/3/24.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import IDDSwiftUI

@Reducer
struct DNSAlert<AlertAction: Equatable> {
    @ObservableState
    struct State: Equatable {
        /**
         The default value is one week in seconds, but you can tweak it by
         passing an argument -DNSAlert.timeToLive 60
        */
        private static var timeToLive: Int {
            let value = UserDefaults.standard.integer(forKey: "DNSAlert.timeToLive")
            if value <= 0 {
                return 30 * 24 * 60 * 60 // one month in seconds
            }
            return value
        }
        
        var alertState: AlertState<AlertAction>
        /**
         When false we revert to the old alert.
         There is no DNS bull shait.
         */
        let askForDNS: Bool
        var doNotShowAgainKey: String
        
        var lastAskDate: Date {
            get {
                let date = UserDefaults.standard.object(forKey: doNotShowAgainKey) as? Date
                return date ?? .distantPast
            }
            set {
                UserDefaults.standard.set(newValue, forKey: doNotShowAgainKey)
            }
        }
        
        /**
         When we show the panel we always start with false, other wise we dont evenr show this alert.
         */
        var doNotShowAgain: Bool {
            didSet {
                Log4swift[Self.self].info("doNotShowAgain: '\(doNotShowAgainKey).\(doNotShowAgain)'")
                UserDefaults.standard.set(doNotShowAgain ? Date() : .distantPast, forKey: doNotShowAgainKey)
            }
        }

        /**
         Creates the DNSAlert with the doNotShowAgain feature enabled.
         Failable initializer because alert may have persisted to not show again.
         lue which should be false.
         */
        init?(
            title: () -> TextState,
            message: (() -> TextState)? = nil,
            @ButtonStateBuilder<AlertAction> actions: () -> [ButtonState<AlertAction>] = { [] },
            doNotShowAgainKey: String,
            timeToLive: Int = Self.timeToLive
        ) {
            let doNotShowAgainKey = "DoNotShowAgain.\(doNotShowAgainKey)"
            self.alertState = .init(title: title, actions: actions, message: message)
            self.askForDNS = true
            self.doNotShowAgainKey = doNotShowAgainKey
            self.doNotShowAgain = false // the didSet will not get called here
            
            if Int(self.lastAskDate.elapsedTimeInSeconds) < min(timeToLive, Self.timeToLive) {
                // this corresponds to self.doNotShowAgain being true
                // in which case we just return nil
                // upstream we than interpret this as, go do your thing, user said do not show again
                Log4swift[Self.self].info("alert: '\(doNotShowAgainKey)' was told to DNS.")
                return nil
            }
        }
        
        init(
            title: () -> TextState,
            message: (() -> TextState)? = nil,
            @ButtonStateBuilder<AlertAction> actions: () -> [ButtonState<AlertAction>] = { [] }
        ) {
            self.alertState = .init(title: title, actions: actions, message: message)
            self.askForDNS = false
            self.doNotShowAgainKey = ""
            self.doNotShowAgain = false
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    enum Action: Equatable {
        case presented(AlertAction)
        case dismiss
        case setDoNotShowAgain(Bool)
        case toggleDoNotShowAgain
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            case .presented:
                return .none
                
            case .dismiss:
                return .run { _ in
                    await self.dismiss()
                }
                
            case let .setDoNotShowAgain(newValue):
                state.doNotShowAgain = newValue
                return .none
                
            case .toggleDoNotShowAgain:
                if state.askForDNS {
                    state.doNotShowAgain.toggle()
                }
                return .none
                
            }
        }
    }
}
