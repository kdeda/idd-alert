//
//  AlertPanel.swift
//  IDDAlert
//
//  Created by Klajd Deda on 02/24/24.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
@preconcurrency import IDDSwiftUI

extension Double {
    internal static let alertPanelWidth: Double = 260
    internal static let alertPanelPadding: Double = 16
}

/**
 Verbatim apple, Alert button style
 February 2024
 */
public struct AlertPanelButtonStyle: ButtonStyle {
    private var primary: Bool = false
    
    public init(primary: Bool = false) {
        self.primary = primary
    }
    
    private var foregroundColor: Color {
        primary
        ? Color.white
        : Color.primary
    }
    
    private var primaryColor: Color {
        primary
        ? Color(NSColor.controlAccentColor)
        : Color(NSColor.unemphasizedSelectedContentBackgroundColor)
    }
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
        // magical number from finagling to make it fit
            .offset(x: 0, y: -1)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .foregroundColor(self.foregroundColor)
            .background(configuration.isPressed ? Color(NSColor.selectedControlColor) : self.primaryColor)
            .cornerRadius(6.0)
    }
}

/**
 Attempt at cloning Apple's Alert panel to be as close as possible.
 This allows us to drow our own componwnts inside the alert.
 */
public struct AlertPanel<Content>: View where Content: View {
    var title: Text
    var message: Text?
    private let content: () -> Content
    
    public init(_ title: Text, message: Text? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.message = message
        self.content = content
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 64, height: 64)
                .padding(.top, 5)
                .padding(.bottom, 10)
            // .border(Color.yellow)
            
            self.title
                .font(.headline)
                .fontWeight(.bold)
            // this will force the text to wrap ...
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
                .textSelection(.enabled)
            
            // .border(Color.yellow)
            self.message.map { honestMessage in
                // not sure what sort of sorcery is happening here apple.
                // but this view's size is WRONG and further WTF,
                // if i select it changes height ...
                // March 4, 2024
                honestMessage
                    .font(.subheadline)
                    // .frame(width: 224)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                // .border(.yellow)
                // .fixedSize()
            }
            content()
            // .frame(width: 224)
            // .border(Color.orange)
                .padding(.top, 6)
        }
        // magical numbers, february 2024
        .padding(Double.alertPanelPadding)
        .frame(width: Double.alertPanelWidth)
    }
}

struct AlertPanel_Previews: PreviewProvider {
    static var previews: some View {
        AlertPanel(
            Text("Do you want to permanently discard all changes to AlertPanel.swift?"),
            message: Text("You can't undo this action. You can't undo this action.\nYou can't undo this action. You can't undo this action. You can't undo this action. You can't undo this action. You can't undo this action. You can't undo this action.")
        ) {
            VStack(spacing: 6) {
                HStack {
                    Toggle(isOn: .constant(true)) {
                        Text("Do not ask again.")
                            .font(.subheadline)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    // .padding(.leading, 10)
                    Spacer()
                }
                .padding(6)
                // .border(.yellow)
                Button(action: {
                    Log4swift[Self.self].info("NOOP")
                }) {
                    Text("Do not ask again")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AlertPanelButtonStyle())
                Button(action: {
                    Log4swift[Self.self].info("NOOP")
                }) {
                    Text("Secondary")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AlertPanelButtonStyle())
                Button(action: { /* viewStore.send(.bzloginClick) */}) {
                    Text("OK")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AlertPanelButtonStyle(primary: true))
            }
        }
        .background(Color.windowBackgroundColor)
        .environment(\.colorScheme, .light)
        
        // 3 button alert panel
        AlertPanel(Text("Log4swift")) {
            VStack {
                Button(action: {
                    Log4swift[Self.self].info("NOOP")
                }) {
                    Text("Secondary")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AlertPanelButtonStyle())
                
                Button(action: { /* viewStore.send(.bzloginClick) */}) {
                    Text("Tertiary")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AlertPanelButtonStyle())
                
                Button(action: { /* viewStore.send(.bzloginClick) */}) {
                    Text("OK")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AlertPanelButtonStyle(primary: true))
            }
            .frame(width: .infinity)
        }
        .background(Color.windowBackgroundColor)
        .environment(\.colorScheme, .dark)
    }
}
