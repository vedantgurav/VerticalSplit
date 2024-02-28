//
//  Wrappers.swift
//  VerticalSplit
//
//  Created by Vedant Gurav on 28/02/2024.
//

import SwiftUI

struct TopWrapper<Content: View, Overlay: View>: View {
    var minimise: CGFloat
    var overscroll: CGFloat
    var isFull: Bool
    var isShowingAccessories: Bool
    var bgColor: Color
    @ViewBuilder var content: () -> Content
    @ViewBuilder var overlay: () -> Overlay
    
    let bottomSafeArea = SafeAreaInsetsKey.defaultValue.smartBottom
    let displayCornerRadius = UIScreen.main.displayCornerRadius
    let screenWidth = UIApplication.shared.screenSize.width
    
    var cornerRadius: CGFloat {
        isFull && !isShowingAccessories ? displayCornerRadius + overscroll * 2 : 22
    }
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                content()
            }
            .frame(maxWidth: screenWidth, maxHeight: .infinity, alignment: .top)
            .safeAreaPadding(.top, SafeAreaInsetsKey.defaultValue.top)
            .safeAreaPadding(.bottom, isFull && !isShowingAccessories ? lil + SafeAreaInsetsKey.defaultValue.bottom - 8 : 0)
        }
        .scaleEffect(1 - (1 - minimise) * 0.15, anchor: .top)
        .blur(radius: (1 - minimise) * 8)
        .overlay { bgColor.opacity(1 - minimise).allowsHitTesting(false) }
        .overlay(alignment: .bottom, content: {
            overlay()
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: lil)
                .opacity(1 - minimise)
                .blur(radius: minimise * 8)
                .offset(y: 16 * minimise)
                .scaleEffect(1 + minimise * 0.15)
                .allowsHitTesting(minimise == 0)
        })
        .mask { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }
        .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(bgColor)
                .padding(.top, -200)
        }
        .offset(y: isShowingAccessories && isFull ? -(spacing * 2 + bottomSafeArea) : 0)
        .scaleEffect(isFull ? 1 : 1 + min(0, overscroll / 800), anchor: isFull ? .center : .bottom)
        .ignoresSafeArea()
    }
}

struct BottomWrapper<Content: View, Overlay: View>: View {
    var minimise: CGFloat
    var overscroll: CGFloat
    var isFull: Bool
    var isShowingAccessories: Bool
    var bgColor: Color
    @ViewBuilder var content: () -> Content
    @ViewBuilder var overlay: () -> Overlay
    
    let topSafeArea = SafeAreaInsetsKey.defaultValue.top
    let displayCornerRadius = UIScreen.main.displayCornerRadius
    let screenWidth = UIApplication.shared.screenSize.width
    
    var cornerRadius: CGFloat {
        isFull && !isShowingAccessories ? displayCornerRadius - overscroll * 2 : 22
    }
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                content()
            }
            .frame(maxWidth: screenWidth, maxHeight: .infinity, alignment: .top)
            .safeAreaPadding(.top, isFull && !isShowingAccessories ? lil + SafeAreaInsetsKey.defaultValue.top - 8 : 0)
            .safeAreaPadding(.bottom, SafeAreaInsetsKey.defaultValue.bottom)
        }
        .scaleEffect(1 - (1 - minimise) * 0.15, anchor: .bottom)
        .blur(radius: (1 - minimise) * 8)
        .overlay { bgColor.opacity(1 - minimise).allowsHitTesting(false) }
        .overlay(alignment: .top, content: {
            overlay()
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: lil)
                .opacity(1 - minimise)
                .blur(radius: minimise * 8)
                .offset(y: -16 * minimise)
                .scaleEffect(1 + minimise * 0.15)
                .allowsHitTesting(minimise == 0)
        })
        .mask { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }
        .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(bgColor)
                .padding(.bottom, -200)
        }
        .offset(y: isShowingAccessories && isFull ? (spacing * 2 + topSafeArea) : 0)
        .scaleEffect(isFull ? 1 : 1 - max(0, overscroll / 800), anchor: isFull ? .center : .top)
        .ignoresSafeArea()
    }
}
