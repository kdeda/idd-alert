//
//  Binding+isPresent.swift
//
//
//  Created by Klajd Deda on 5/19/24.
//

import SwiftUI

// TODO:
// ask to make this public
// swift-composable-architecture/Sources/ComposableArchitecture/Internal/Binding+IsPresent.swift
//
public extension Binding {
    func isPresent<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
        self._isPresent
    }
}

extension Optional {
    fileprivate var _isPresent: Bool {
        get { self != nil }
        set {
            guard !newValue else { return }
            self = nil
        }
    }
}
