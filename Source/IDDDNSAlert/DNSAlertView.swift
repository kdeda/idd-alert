//
//  DNSAlert.swift
//  IDDAlert
//
//  Created by Jesse Deda on 3/3/24.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import SwiftUINavigation
import IDDSwiftUI

public struct DNSAlertView<AlertAction: Equatable>: View {
    @Perception.Bindable var store: StoreOf<DNSAlert<AlertAction>>
    @State private var monitorID: Any?
    let alertState: AlertState<AlertAction>
    
    init(store: StoreOf<DNSAlert<AlertAction>>) {
        self.store = store
        self.alertState = store.withState { $0.alertState }
        self.monitorID = nil
        
        Log4swift[Self.self].info("title: \(String.init(state: alertState.title))")
    }
    
    private func handleAction(_ buttonState: ButtonState<AlertAction>, dismiss: Bool = true) {
        // Log4swift[Self.self].info("buttonState: \(buttonState.title)")
        switch buttonState.action.type {
        case let .send(action):
            if let action {
                store.send(.presented(action))
            } else if buttonState.role == .cancel {
                store.send(.dismiss)
            }
        case let .animatedSend(action, animation):
            if let action {
                store.send(.presented(action), animation: animation)
            }
        }
        if dismiss {
            store.send(.dismiss)
        }
    }
    
    public var body: some View {
        WithPerceptionTracking {
            AlertPanel(
                Text(store.alertState.title),
                message: (store.alertState.message).map(Text.init) ?? Text(verbatim: "")
            ) {
                VStack(spacing: 6) {
                    WithPerceptionTracking {
                        ForEach(store.alertState.buttons) { buttonState in
                            WithPerceptionTracking {
                                if store.askForDNS && buttonState.isDoNotAskAgain {
                                    HStack {
                                        Toggle(isOn: $store.doNotShowAgain.sending(\.setDoNotShowAgain)) {
                                            Text(buttonState.title)
                                                .font(.subheadline)
                                        }
                                        .toggleStyle(CheckboxToggleStyle())
                                        .focusable(false)
                                        // .keyboardShortcut(.space)

                                        Spacer()
                                    }
                                    .padding(6)
                                } else {
                                    Button(action: {
                                        // Log4swift[Self.self].info("buttonState \(buttonState)")
                                        handleAction(buttonState)
                                    }) {
                                        Text(buttonState.label)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(buttonState.alertButtonStyle(store.alertState.buttons))
                                    .help(buttonState.helpString(store.alertState.buttons))
                                    .focusable(false)
                                    
                                    // TODO: this works, but sometimes not !!!
                                    // Somehow when we use the NavigationSplitView these short keys do not work ...
                                    // https://stackoverflow.com/questions/68204982/how-to-detect-key-press-and-release-in-swiftui-macos/78078444#78078444
                                    //
                                    // .keyboardShortcut(buttonState.keyboardShortcut(store.alertState.buttons))
                                }
                            }
                        }
                    }
                }
                .onAppear(perform: {
                    // TODO: Maybe move this into the init?
                    self.monitorID = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                        if event.keyCode == .returnKey || event.keyCode == .enter {
                            Log4swift[Self.self].info(function: "NSEvent.addLocalMonitorForEvents", "[returnKey || enter]")
                            
                            let buttons = alertState.buttons.filter({ !$0.isDoNotAskAgain })
                            if let button = buttons.first {
                                handleAction(button)
                                return nil
                            }
                        } else if event.keyCode == .space {
                            Log4swift[Self.self].info(function: "NSEvent.addLocalMonitorForEvents", "[space]")
                            
                            if let _ = alertState.buttons.first(where: { $0.isDoNotAskAgain }) {
                                store.send(.toggleDoNotShowAgain)
                                // handleAction(button)
                                return nil
                            }
                        }
                        return event
                    }
                })
                .onDisappear(perform: {
                    if let id = self.monitorID {
                        // clean up or else we are called with older captured values
                        NSEvent.removeMonitor(id)
                    }
                })
            }
        }
    }
}

extension View {
    /**
     Allows us to display our very own AlertPanel.
     This panel can than for example incorporate a don't ask me again button.
     More of a sheet but that's the only way to punch a custom modal i know.
     */
    @ViewBuilder
    public func dnsAlert<Action>(
        _ item: Binding<Store<DNSAlert<Action>.State, DNSAlert<Action>.Action>?>
    ) -> some View where Action: Equatable {
        let store = item.wrappedValue
        let isPresent = item.isPresent()
        // let isPresent1 = Binding.init(unwrapping: item)
        // let isPresent2 = Binding.init(item)

        self.sheet(isPresented: isPresent) {
            if let store {
                DNSAlertView(store: store)
            }
        }
    }
}

#Preview {
    DNSAlertView<Never>(store: .init(
        initialState: DNSAlert<Never>.State.init(
            title: { TextState("Warning") },
            message: { TextState("Are you sure you want to delete the selected files?") },
            actions: {
                ButtonState(role: .cancel) {
                    TextState("Cancel")
                }
                ButtonState(role: .destructive) {
                    TextState("Confirm")
                }
            },
            doNotShowAgainKey: "deleteSelectedFiles12345"
        )!,
        reducer: DNSAlert.init
    ))
}
