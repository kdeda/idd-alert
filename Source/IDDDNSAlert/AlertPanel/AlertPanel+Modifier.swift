//
//  AlertPanel+Modifier.swift
//  IDDAlert
//
//  Created by Klajd Deda on 02/24/24.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import SwiftUI
import Carbon
import ComposableArchitecture

/**
 The way to do backgrounds on macOS
 https://stackoverflow.com/questions/67304592/how-to-reliably-retrieve-a-windows-background-color-on-macos-with-swiftui
 */
public struct EffectView: NSViewRepresentable {
    @State var material: NSVisualEffectView.Material = .headerView
    @State var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

extension String {
    internal static let doNotAskAgain = "00000000-F00B-F00B-F00B-000000000000"
}

public extension ButtonState where Action: Equatable {
    internal static func doNotAskAgain(
        action: ButtonStateAction<Action> = .send(nil),
        labelString: String = "Do not ask again"
    ) -> Self {
        ButtonState(action: action, label: {
            TextState(String.doNotAskAgain) + TextState(labelString)
        })
    }

    var isDoNotAskAgain: Bool {
        String.init(state: label).hasPrefix(String.doNotAskAgain)
    }

    var title: String {
        String.init(state: label).replacingOccurrences(of: String.doNotAskAgain, with: "")
    }

    func keyboardShortcut(_ others: [ButtonState<Action>]) -> KeyboardShortcut? {
        let knownRoles = others.filter({ !$0.isDoNotAskAgain })

        if self.role == .cancel {
            return .cancelAction
        } else if let first = knownRoles.first {
            if first.id == self.id {
                return .defaultAction
            }
        }
        return .none
    }

    func helpString(_ others: [ButtonState<Action>]) -> String {
        let knownRoles = others.filter({ !$0.isDoNotAskAgain })

        if self.role == .cancel {
            return "Hit the esc key to invoke this button."
        } else if let first = knownRoles.first {
            if first.id == self.id {
                return "Hit the return key to invoke this button."
            }
        }
        return ""
    }

    @MainActor
    func alertButtonStyle(_ others: [ButtonState<Action>]) -> AlertPanelButtonStyle {
        let knowRoles = others.filter({ !$0.isDoNotAskAgain })
        return AlertPanelButtonStyle(primary: knowRoles.first == self)
    }
}

public struct AlertPanelView<Action>: View where Action: Equatable {
    let store: Store<AlertState<Action>, Action>
    @Binding var isPresent: Bool
    @State var monitorID: Any?
    let alertState: AlertState<Action>

    public init(
        store: Store<AlertState<Action>, Action>,
        isPresent: Binding<Bool>
    ) {
        self.store = store
        self.alertState = store.withState { $0 }
        self._isPresent = isPresent

        Log4swift[Self.self].info("title: \(String.init(state: alertState.title))")
    }

    fileprivate func handleAction(_ buttonState: ButtonState<Action>) {
        // Log4swift[Self.self].info("buttonState: \(buttonState.title)")
        switch buttonState.action.type {
        case let .send(action):
            if let action {
                store.send(action)
            } else if buttonState.role == .cancel {
                isPresent = false
            }
        case let .animatedSend(action, animation):
            if let action {
                store.send(action, animation: animation)
            }
        }
    }

    public var body: some View {
        AlertPanel(
            Text.init(alertState.title),
            message: (alertState.message).map(Text.init) ?? Text(verbatim: "")
        ) {
            VStack(spacing: 6) {
                ForEach(alertState.buttons) { buttonState in
                    if buttonState.isDoNotAskAgain {
                        HStack {
                            Toggle(isOn: Binding(get: {
                                false
                            }, set: { _ in
                                handleAction(buttonState)
                            })) {
                                Text(buttonState.title)
                                    .font(.subheadline)
                            }
                            .toggleStyle(CheckboxToggleStyle())
                            // .padding(.leading, 10)
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
                        .buttonStyle(buttonState.alertButtonStyle(alertState.buttons))
                        .help(buttonState.helpString(alertState.buttons))
                        // TODO: this works, but sometimes not !!!
                        // Somehow when we use the NavigationSplitView these short keys do not work ...
                        // https://stackoverflow.com/questions/68204982/how-to-detect-key-press-and-release-in-swiftui-macos/78078444#78078444
                        //
                        // .keyboardShortcut(buttonState.keyboardShortcut(alertState.buttons))
                    }
                }
            }
            .onAppear(perform: {
                self.monitorID = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if event.keyCode == kVK_Return || event.keyCode == kVK_ANSI_KeypadEnter {
                        Log4swift[Self.self].info(function: "NSEvent.addLocalMonitorForEvents", "[returnKey || enter]")

                        let buttons = alertState.buttons.filter({ !$0.isDoNotAskAgain })
                        if let button = buttons.first {
                            handleAction(button)
                            return .none
                        }
                    } else if event.keyCode == kVK_Space {
                        Log4swift[Self.self].info(function: "NSEvent.addLocalMonitorForEvents", "[space]")

                        if let button = alertState.buttons.first(where: { $0.isDoNotAskAgain }) {
                            handleAction(button)
                            return .none
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

//extension View {
//    /**
//     Allows us to display our very own AlertPanel.
//     This panel can than for example incorporate a don't ask me again button.
//     More of a sheet but that's the only way to punch a custom modal i know.
//     */
//    @ViewBuilder
//    public func alertPanel<Action>(
//        _ item: Binding<Store<AlertState<Action>, Action>?>
//    ) -> some View where Action: Equatable {
//        let store = item.wrappedValue
//        let isPresent = item.isPresent()
//
//        self.sheet(isPresented: isPresent) {
//            if let store {
//                // we should have a store here :-)
//                AlertPanelView(store: store, isPresent: isPresent)
//            }
//        }
//    }
//}

/**
post: https://stackoverflow.com/questions/68204982/how-to-detect-key-press-and-release-in-swiftui-macos/78078444#78078444
There's another way
```
struct Demo {
    // Convenience
    // https://gist.github.com/rdev/627a254417687a90c493528639465943
    //
    extension UInt16 {
        // Layout-independent Keys
        // eg.These key codes are always the same key on all layouts.
        static let returnKey: UInt16 = 0x24
        static let enter: UInt16 = 0x4C
        static let space: UInt16 = 0x31
    }

    struct MyView: View {
        @State var monitorID: Any?

        func handleAction(_ type: String) {
            // do your work here
        }

        var body: some View {
            VStack {
                Button(action: {
                    handleAction(".mouseClick")
                }) {
                    Text("Hit return")
                }
            }
            .onAppear(perform: {
                self.monitorID = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if event.keyCode == kVK_Return || event.keyCode == kVK_ANSI_KeypadEnter {
                        handleAction(".return")
                        return .none
                    } else if event.keyCode == kVK_Space {
                        handleAction(".space")
                        return .none
                    }
                    // allow others to handle this event
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
```
 */
