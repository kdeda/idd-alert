//
//  DNSAlert.swift
//  IDDAlert
//
//  Created by Jesse Deda on 3/3/24.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

@Reducer
public struct DNSAlert<AlertAction> where AlertAction: Equatable, AlertAction: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        /**
         The default value is three month in seconds, but you can tweak it by
         passing an argument -DNSAlert.timeToLive 60
         */
        public static var timeToLive: Int {
            let value = UserDefaults.standard.integer(forKey: "DNSAlert.timeToLive")
            if value <= 0 {
                return 3 * 30 * 24 * 60 * 60 // three month in seconds
            }
            return value
        }

        /**
         Helper to allow access from outside
         */
        public static func setDoNotShow(_ newValue: Bool, _ doNotShowAgainKey: String) {
            var lastAskDate: LastAskDate = .init(propertyName: doNotShowAgainKey)
            lastAskDate.date = newValue ? Date().addingTimeInterval(Double(Self.timeToLive)) : .distantPast
        }

        var alertState: AlertState<AlertAction>
        /**
         When false we revert to the old alert.
         There is no DNS bull shait.
         */
        let askForDNS: Bool
        var doNotShowAgainKey: String {
            lastAskDate.propertyName
        }
        var lastAskDate: LastAskDate
        var timeToLive: Int

        /**
         When we show the panel we always start with false, other wise we wont even show this alert.
         */
        var doNotShowAgain: Bool

        /**
         Creates the DNSAlert with the doNotShowAgain feature enabled.
         This func will insert the ButtonState.doNotAskAgain() at the top to make the ui hack work.
         Failable initializer because alert may have persisted to not show again.
         lue which should be false.
         */
        public init?(
            title: () -> TextState,
            message: (() -> TextState)? = nil,
            @ButtonStateBuilder<AlertAction> actions: () -> [ButtonState<AlertAction>] = { [] },
            doNotShowAgainKey: String,
            timeToLive: Int = Self.timeToLive
        ) {
            func hackedActions() -> [ButtonState<AlertAction>] {
                var rv = actions()
                if let index = rv.firstIndex(where: { $0.isDoNotAskAgain == true }) {
                    rv.remove(at: index)

                }

                let newDate = Date().addingTimeInterval(Double(Self.timeToLive))
                let untilDateString = newDate.string(withFormat: "MMMM d, yyyy")
                rv.insert(ButtonState.doNotAskAgain(labelString: "Do not ask again until\n\(untilDateString)"), at: 0)
                return rv
            }

            self.alertState = .init(title: title, actions: hackedActions, message: message)
            self.askForDNS = true
            self.lastAskDate = .init(propertyName: doNotShowAgainKey)
            self.doNotShowAgain = false
            self.timeToLive = timeToLive

            let flags = MainActor.assumeIsolated {
                NSApp.currentEvent?.modifierFlags ?? NSEvent.ModifierFlags(rawValue: 0)
            }
            if flags.contains([.option]) {
                // option click
                // ignore dns
                Log4swift[Self.self].info("key: '\(lastAskDate.propertyName)' option+click detected ...")
                self.lastAskDate.date = .distantPast
            }

            if self.lastAskDate.doNotShow {
                return nil
            }
        }

        public init(
            title: () -> TextState,
            message: (() -> TextState)? = nil,
            @ButtonStateBuilder<AlertAction> actions: () -> [ButtonState<AlertAction>] = { [] }
        ) {
            self.alertState = .init(title: title, actions: actions, message: message)
            self.askForDNS = false
            self.lastAskDate = .init(propertyName: "")
            self.doNotShowAgain = false
            self.timeToLive = Self.timeToLive
        }
    }

    public enum Action: Equatable, Sendable {
        case presented(AlertAction)
        case dismiss
        case setDoNotShowAgain(Bool)
        case toggleDoNotShowAgain
    }
    

    public init() {
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            case .presented:
                return .none
                
            case .dismiss:
                return .run { _ in
                    @Dependency(\.dismiss) var dismiss
                    await dismiss()
                }

            case let .setDoNotShowAgain(newValue):
                state.doNotShowAgain = newValue
                state.lastAskDate.date = state.doNotShowAgain ?  Date().addingTimeInterval(Double(state.timeToLive)) : .distantPast
                return .none
                
            case .toggleDoNotShowAgain:
                if state.askForDNS {
                    state.doNotShowAgain.toggle()
                    state.lastAskDate.date = state.doNotShowAgain ?  Date().addingTimeInterval(Double(state.timeToLive)) : .distantPast
                }
                return .none
                
            }
        }
    }
}
