//
//  SplitDetent.swift
//  VerticalSplit
//
//  Created by Vedant Gurav on 28/02/2024.
//

import Foundation

/// A type that represents how the top and bottom views are split in the VerticalSplit.
public enum SplitDetent: Equatable {
    /// A detent when the top view fills the entirety of the screen. A pill is shown at the bottom of the screen with accessories and the title of the bottom view.
    case topFull
    /// A detent when the bottom view fills the entirety of the screen. A pill is shown at the top of the screen with accessories and the title of the top view.
    case bottomFull
    /// A detent when the bottom view fills the mosy of the screen. The mini overlay for the top view is shown.
    case topMini
    /// A detent when the top view fills the mosy of the screen. The mini overlay for the vottom view is shown.
    case bottomMini
    /// A detent where the specified value represents the proportion of the screen occupied by the top view. The value is within 0 and 1.
    case fraction(_ value: Double)
    
    /// A textual representation of the detent.
    var description: String {
        if case let .fraction(value) = self {
            return String(format: "fraction(%.3f)", value)
        }
        return "\(self)"
    }
}
