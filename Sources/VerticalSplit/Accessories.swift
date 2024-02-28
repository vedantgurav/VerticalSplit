//
//  Accessories.swift
//  VerticalSplit
//
//  Created by Vedant Gurav on 28/02/2024.
//

import SwiftUI

/// Accessory buttons shown on each side of the drag indicator in the VerticalSplit.
public struct SplitAccessory: Identifiable {
    public var id: String { title + systemName }
    let title: String
    let systemName: String
    let color: Color
    let action: () -> Void
    
    /// Creates an accessory with the associated action.
    /// - Parameters:
    ///   - title: Name of the accessory.
    ///   - systemName: SFSymbol for the label of the button.
    ///   - color: Foreground color applied to the label of the button.
    ///   - action: Action to be performed when accessory is tapped.
    public init(title: String? = nil, systemName: String, color: Color = .white, action: @escaping () -> Void) {
        self.systemName = systemName
        self.action = action
        self.color = color
        self.title = title ?? systemName
    }
}

/// Larger accessory buttons shown in a pop-out menu in the VerticalSplit.
public struct MenuAccessory: Identifiable {
    public var id: String { title + systemName }
    let title: String
    let systemName: String
    let color: Color
    let action: () -> Void
    
    /// Creates an accessory with the associated action.
    /// - Parameters:
    ///   - title: Name of the accessory, shown beside the symbol.
    ///   - systemName: SFSymbol for the label of the button.
    ///   - color: Foreground color applied to the label of the button.
    ///   - action: Action to be performed when accessory is tapped.
    public init(title: String? = nil, systemName: String, color: Color = Color(uiColor: .label), action: @escaping () -> Void) {
        self.systemName = systemName
        self.action = action
        self.color = color
        self.title = title ?? systemName
    }
}
