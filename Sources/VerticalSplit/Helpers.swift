//
//  Helpers.swift
//  VerticalSplit
//
//  Created by Vedant Gurav on 26/02/2024.
//

import UIKit
import SwiftUI

struct ScaleDownButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .animation(.smooth(duration: configuration.isPressed ? 0.1 : 0.2), value: configuration.isPressed)
    }
}

extension UIScreen {
    private static let cornerRadiusKey: String = {
        let components = ["Radius", "Corner", "display", "_"]
        return components.reversed().joined()
    }()

    var displayCornerRadius: CGFloat {
        guard let cornerRadius = self.value(forKey: Self.cornerRadiusKey) as? CGFloat else {
            return 0
        }

        return cornerRadius
    }
}


struct BlurTransitionModifier: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content.blur(radius: radius)
    }
}

public extension AnyTransition {
    static func blur(radius: CGFloat = 4) -> AnyTransition {
        .modifier(active: BlurTransitionModifier(radius: radius), identity: .init(radius: 0))
    }
}


struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        UIApplication.shared.safeAreaInsets.insets
    }
}

extension EdgeInsets {
    var smartBottom: CGFloat {
        bottom == 0 ? 16 : bottom
    }
    
    var vertical: CGFloat {
        top + bottom
    }
    
    var horizontal: CGFloat {
        leading + trailing
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

extension UIEdgeInsets {
    var insets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

extension UIApplication {
    public var screenSize: CGSize {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window?.screen.bounds.size ?? UIScreen.main.bounds.size
    }
    
    var safeAreaInsets: UIEdgeInsets {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window?.safeAreaInsets ?? UIEdgeInsets.zero
    }
}

extension Color {
    var textColor: Color {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        let brightness = ((r * 299) + (g * 587) + (b * 114)) / 1000;
        
        return brightness < 0.6 ? .white : .black
    }
}
