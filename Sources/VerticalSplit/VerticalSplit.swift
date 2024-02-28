//
//  SplitscreenContainer.swift
//  VerticalSplit
//
//  Created by Vedant Gurav on 03/02/2024.
//

import SwiftUI
import OSLog

let detentLogger = Logger(subsystem: "VerticalSplit", category: "Detents")
let actionLogger = Logger(subsystem: "VerticalSplit", category: "Accessories")

let spacing: CGFloat = 36
let lil: CGFloat =  58
let lil2: CGFloat = 58 * 3 / 2
let lil3: CGFloat = 58 * 2
let notches: Int = 6

let lightImpact = UIImpactFeedbackGenerator(style: .light)
let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
let softImpact = UIImpactFeedbackGenerator(style: .soft)

/// A container that presents two views stacked vertically with an adjustable split.
public struct VerticalSplit<
    TopView: View,
    BottomView: View,
    TopViewOverlay: View,
    BottomViewOverlay: View
>: View {
    @ViewBuilder var topView: () -> TopView
    @ViewBuilder var bottomView: () -> BottomView
    
    @ViewBuilder var topViewOverlay: () -> TopViewOverlay
    @ViewBuilder var bottomViewOverlay: () -> BottomViewOverlay
    
    let autoTopOverlay: Bool
    let autoBottomOverlay: Bool
    
    let topTitle: String
    let bottomTitle: String
    
    var leadingAccessories: [SplitAccessory] = []
    var trailingAccessories: [SplitAccessory] = []
    var menuAccessories: [MenuAccessory] = []
    var menuSymbol: String = "plus.circle.fill"
    
    var leadingCount: Int = 0
    var trailingCount: Int = 0
    
    @Binding var detent: SplitDetent
    @State var didSetInitialSplit = false
    
    var shouldLog = false
    var bgColor: Color = {
        Color(uiColor: .init(dynamicProvider: { trait in
            switch trait.userInterfaceStyle {
            case .dark:
                return .init(white: 0.16, alpha: 1)
            default:
                return .systemBackground
            }
        }))
    }()
    var textColor: Color = .primary
    
    @GestureState var isDragging: Bool = false
    
    @State var partition: CGFloat = 0
    @State var notchPartition: CGFloat = 0
    @State var initialPartition: CGFloat?
    @State var topHeight: CGFloat = (UIScreen.main.bounds.height - SafeAreaInsetsKey.defaultValue.vertical) / 2 - spacing / 2
    @State var currentSpacing: CGFloat = 36
    
    @State var hideTop = false
    @State var hideBottom = false
    
    @State var overscroll: CGFloat = 0
    @State var translationBeforeOverscroll: CGFloat = 0
    @State var initialMinimal = false
    @State var initialTop: Bool = false
    
    
    let bottomExtraOffset: CGFloat = {
        SafeAreaInsetsKey.defaultValue.bottom == 0 ? 16 : 0
    }()
    
    var cardHeight: CGFloat {
        (UIScreen.main.bounds.height - SafeAreaInsetsKey.defaultValue.vertical) / 2 - currentSpacing / 2
    }
    
    let range: CGFloat = {
        let defaultCardHeight = (UIScreen.main.bounds.height - SafeAreaInsetsKey.defaultValue.vertical) / 2 - spacing / 2
        return defaultCardHeight - lil
    }()
    
    let transaction: Transaction = {
        var transaction = Transaction(animation: .smooth(duration: 0.4))
        transaction.tracksVelocity = true
        transaction.isContinuous = true
        return transaction
    }()
    
    // MARK: Gesture
    
    var bossGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($isDragging) { _, s, _ in
                s = true
            }
            .onChanged { value in
                if initialPartition == nil {
                    initialPartition = partition
                    if hideTop || hideBottom {
                        initialMinimal = true
                        initialTop = hideTop
                        mediumImpact.impactOccurred(intensity: 0.6)
                    }
                }
       
                withTransaction(transaction) {
                    let translation = (initialPartition ?? 0) + value.translation.height
                    let minimalAdjustment = (initialMinimal ? (initialTop ? 8 - lil : lil - 8 - bottomExtraOffset) : 0)
                    let newPartition = min(cardHeight - lil, max(-cardHeight + lil, translation + minimalAdjustment))
                    
                    if translation < -cardHeight + lil {
                        if translationBeforeOverscroll == 0 {
                            translationBeforeOverscroll = translation
                            mediumImpact.impactOccurred(intensity: 0.8)
                        }
                        overscroll = (translation - translationBeforeOverscroll) * 0.75
                    } else if translation > cardHeight - lil {
                        if translationBeforeOverscroll == 0 {
                            translationBeforeOverscroll = translation
                            mediumImpact.impactOccurred(intensity: 0.8)
                        }
                        overscroll = (translation - translationBeforeOverscroll) * 0.75
                    } else {
                        translationBeforeOverscroll = 0
                        overscroll = 0
                    }
                    
                    hideTop = false
                    hideBottom = false
                    topHeight = cardHeight + newPartition
                    let oldPartition = partition
                    partition = newPartition
                    notchPartition = getSnappedPartition(for: getNotch(for: newPartition))
                    
                    if (oldPartition < notchPartition && notchPartition < partition) ||
                        (oldPartition > notchPartition && notchPartition > partition) {
                        rigidImpact.impactOccurred(intensity: 0.8)
                    }
                }
            }
            .onEnded { value in
                if value.translation.height < 2 {
                    withTransaction(transaction) {
                        if hideTop {
                            hideTop = false
                        } else {
                            hideBottom = false
                        }
                    }
                }
                let translation = (initialPartition ?? 0) + value.translation.height
                let minimalAdjustment = (initialMinimal ? (initialTop ? 8 - lil : lil - 8 - bottomExtraOffset) : 0)
                var newPartition = translation + minimalAdjustment
                
                var newSplit: SplitDetent
                
                if newPartition < -cardHeight + lil2 {
                    newPartition = lil - cardHeight
                    newSplit = .topMini
                } else if newPartition < -cardHeight + lil3 {
                    newPartition = lil3 - cardHeight
                    newSplit = .fraction(0)
                } else if newPartition > cardHeight - lil2 {
                    newPartition = cardHeight - lil
                    newSplit = .bottomMini
                } else if newPartition > cardHeight - lil3 {
                    newPartition = cardHeight - lil3
                    newSplit = .fraction(1)
                } else {
                    let notch = getNotch(for: newPartition)
                    newSplit = .fraction(CGFloat(notch) /  CGFloat(notches))
                    newPartition = getSnappedPartition(for: notch)
                }
                
                withTransaction(transaction) {
                    if initialMinimal && (hideTop || hideBottom) {
                        overscroll = 0
                        return
                    }
                    partition = newPartition
                    topHeight = cardHeight + newPartition
                    if overscroll < -20 {
                        hideTop = true
                        newSplit = .bottomFull
                        partition = -(cardHeight - lil)
                        hideBottom = false
                        mediumImpact.impactOccurred(intensity: 0.8)
                    } else if overscroll > 20 {
                        hideTop = false
                        newSplit = .topFull
                        partition = (cardHeight - lil)
                        hideBottom = true
                        mediumImpact.impactOccurred(intensity: 0.8)
                    } else {
                        hideTop = false
                        hideBottom = false
                        rigidImpact.impactOccurred(intensity: 0.8)
                    }
                    overscroll = 0
                    translationBeforeOverscroll = 0
                }
                initialPartition = nil
                initialMinimal = hideTop || hideBottom
                initialTop = false
                detent = newSplit
            }
    }
    
    // MARK: Body
    
    public var body: some View {
        let isAccessoriesPill: Bool = currentSpacing != spacing
        let isMinimalPill: Bool = hideTop || hideBottom
        ZStack {
            VStack(spacing: currentSpacing) {
                if !hideTop {
                    TopWrapper(
                        minimise: (min(lil3, topHeight + (isAccessoriesPill ? spacing / 2 : 0) ) - lil) / lil,
                        overscroll: overscroll,
                        isFull: hideBottom,
                        isShowingAccessories: isAccessoriesPill,
                        bgColor: bgColor,
                        content: topView,
                        overlay: {
                            topViewOverlay()
                                .padding(.horizontal, autoTopOverlay ? 16 : 0)
                                .fontWeight(autoTopOverlay ? .semibold : .regular)
                        }
                    )
                    .frame(height: hideBottom ? nil : topHeight + overscroll / 5 )
                    .transaction(value: hideBottom, { t in
                        t.animation = didSetInitialSplit ? .smooth(duration: 0.4) : .none
                    })
                    .transition(.offset(y: -topHeight - (partition > 0 ? 300 : 200) ))
                    .zIndex(1)
                }
                if !hideBottom {
                    BottomWrapper(
                        minimise: 1 - max(0, partition - cardHeight + lil3 - (isAccessoriesPill ? spacing / 2 : 0)) / lil,
                        overscroll: overscroll,
                        isFull: hideTop,
                        isShowingAccessories: isAccessoriesPill,
                        bgColor: bgColor,
                        content: bottomView,
                        overlay: {
                            bottomViewOverlay()
                                .padding(.horizontal, autoBottomOverlay ? 16 : 0)
                                .fontWeight(autoBottomOverlay ? .semibold : .regular)
                        }
                    )
                    .transaction(value: hideBottom, { t in
                        t.animation = didSetInitialSplit ? .smooth(duration: 0.4) : .none
                    })
                    .transition(.offset(y: -partition + range + (partition < 0 ? 300 : 200) ))
                    .zIndex(1)
                }
            }
            .animation(.smooth(duration: 0.45), value: hideTop)
            .animation(.smooth(duration: 0.45), value: hideBottom)
            .overlay {
                if currentSpacing != spacing {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withTransaction(transaction) {
                                currentSpacing = spacing
                                topHeight = cardHeight + partition
                            }
                            if shouldLog {
                                actionLogger.info("Menu dismissed")
                            }
                        }
                }
            }
            .zIndex(1)
            
            HStack(spacing: 8) {
                Spacer()
                    .frame(width: max(0, (20 + 8) * CGFloat(leadingCount) - 8))
                Text(isMinimalPill ? (hideTop ? topTitle : bottomTitle) : "")
                    .fontWeight(.medium)
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .opacity(0)
                    .foregroundStyle(.white)
                
                Spacer()
                    .frame(width: max(0, (20 + 8) * CGFloat(trailingCount) - 8))
                
            }
            .padding(.horizontal, 12)
            .frame(height: isMinimalPill ? 44 : currentSpacing)
            .frame(maxWidth: isMinimalPill ? nil : .infinity)
            .background(Capsule().fill(.black))
            .offset(
                y: (hideTop ? -lil + 8 : hideBottom ? lil - 8 - bottomExtraOffset : 0)
                + (partition + overscroll / (hideTop || hideBottom ? 1 : 5))
            )
            .zIndex(2)
            
            
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(leadingAccessories) { accessory in
                        Button(action: {
                            accessory.action()
                            if shouldLog {
                                actionLogger.info("Accessory item tapped: \(accessory.title)")
                            }
                        }) {
                            Image(systemName: accessory.systemName)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(accessory.color)
                                .frame(width: 20, height: 20)
                        }
                         .buttonStyle(ScaleDownButtonStyle())
                    }
                }
                
                Text(isMinimalPill ? (hideTop ? topTitle : bottomTitle) : (topHeight < cardHeight ? topTitle : bottomTitle))
                    .padding(.horizontal, 8)
                    .fixedSize()
                    .opacity(0)
                    .frame(maxWidth: isMinimalPill ? nil : .infinity)
                
                
                HStack(spacing: 8) {
                    ForEach(trailingAccessories) { accessory in
                        Button(action: accessory.action) {
                            Image(systemName: accessory.systemName)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(accessory.color)
                                .frame(width: 20, height: 20)
                        }
                         .buttonStyle(ScaleDownButtonStyle())
                    }
                    if !menuAccessories.isEmpty {
                        Button {
                            withTransaction(transaction) {
                                if currentSpacing == spacing {
                                    currentSpacing = spacing * 2
                                } else {
                                    currentSpacing = spacing
                                }
                                topHeight = cardHeight + partition
                                if shouldLog {
                                    actionLogger.info("Menu opened")
                                }
                            }
                        } label: {
                            Image(systemName: menuSymbol)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                         .buttonStyle(ScaleDownButtonStyle())
                    }
                }
            }
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, isMinimalPill ? 12 : 24 + abs(overscroll / 20))
            .frame(height: isMinimalPill ? 44 : currentSpacing)
            .scaleEffect(isAccessoriesPill ? 0.9 : 1)
            .blur(radius: isAccessoriesPill ? 12 : 0)
            .opacity(isAccessoriesPill ? 0 : 1)
            .frame(maxWidth: .infinity, alignment: .center)
            .overlay(alignment: .center) {
                HStack(spacing: 8) {
                    ForEach(menuAccessories) { accessory in
                        Button {
                            withTransaction(transaction) {
                                currentSpacing = spacing
                                topHeight = cardHeight + partition
                            }
                            if shouldLog {
                                actionLogger.info("Menu item tapped: \(accessory.title)")
                            }
                            accessory.action()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: accessory.systemName)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(accessory.color)
                                    .frame(width: 16, height: 16)
                                Text(accessory.title)
                                    .foregroundStyle(textColor)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(maxWidth: .infinity)
                            }
                            .fontWeight(.medium)
                            .padding(.leading, 14)
                            .padding(.trailing, 24)
                            .frame(maxHeight: .infinity)
                            .background(Capsule().fill(bgColor))
                        }
                         .buttonStyle(ScaleDownButtonStyle())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 14)
                .frame(height: spacing * 2)
                .scaleEffect(isAccessoriesPill ? 1 : 0.6)
                .blur(radius: isAccessoriesPill ? 0 : 8)
                .opacity(isAccessoriesPill ? 1 : 0)
                .offset(y: isAccessoriesPill ? 0 : hideTop ? -120 : hideBottom ? 120 : 0)
                .frame(height: currentSpacing)
                .frame(maxWidth: min(.infinity, 400))
            }
            .contentShape(.rect)
            .offset(
                y: (hideTop ? -lil + 8 : hideBottom ? lil - 8 - bottomExtraOffset : 0)
                + (partition + overscroll / (hideTop || hideBottom ? 1 : 5))
            )
            .gesture(currentSpacing == spacing ? bossGesture : nil)
            .zIndex(10)
            
            
            ZStack {
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(width: 56, height: 5)
                    .transaction({ t in
                        t.animation = .easeInOut(duration: 0.3)
                    }, body: { $0.scaleEffect(isDragging ? 0.9 : 1) })
                    .blur(radius: isMinimalPill ? 8 : 0)
                    .opacity(isMinimalPill ? 0 : 1)
                Text(isMinimalPill ? (hideTop ? topTitle : bottomTitle) : (topHeight < cardHeight ? topTitle : bottomTitle))
                    .fontWeight(.medium)
                    .fixedSize()
                    .scaleEffect(isMinimalPill ? 1 : 0.9)
                    .blur(radius: isMinimalPill ? 0 : 12)
                    .opacity(isMinimalPill ? 1 : 0)
                    .foregroundStyle(.white)
                    .offset(x: CGFloat(leadingCount - trailingCount) * (20 + 8) / 2)
            }
            .scaleEffect(1)
            .scaleEffect(isAccessoriesPill ? 0.9 : 1)
            .blur(radius: isAccessoriesPill ? 12 : 0)
            .opacity(isAccessoriesPill ? 0 : 1)
            .offset(
                y: (hideTop ? -lil + 8 : hideBottom ? lil - 8 - bottomExtraOffset : 0)
                + (partition + overscroll / (hideTop || hideBottom ? 1 : 5))
            )
            .zIndex(11)
            .allowsHitTesting(false)
            
        }
        .background(.black)
        .onAppear {
            didUpdateSplit(split: detent)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                didSetInitialSplit = true
            }
        }
        .onChange(of: detent) { _, newValue in
            guard !isAccessoriesPill else { return }
            var t = transaction
            t.animation = .smooth(duration: 0.5)
            withTransaction(t) {
               didUpdateSplit(split: detent)
            }
        }
    }
    
    // MARK: Functions
    
    func didUpdateSplit(split: SplitDetent) {
        detentLogger.info("SplitDetent: \(split.description)")
        currentSpacing = spacing
        hideTop = false
        hideBottom = false
        switch split {
        case .topFull:
            hideBottom = true
            partition = cardHeight - lil
        case .bottomFull:
            hideTop = true
            partition = -cardHeight + lil
        case .topMini:
            partition = -range
        case .bottomMini:
            partition = range
        case .fraction(let value):
            if value < 0 {
                detentLogger.warning("SplitDetent: Invalid value, fraction should be in range 0...1")
                self.detent = .bottomFull
            } else if value > 1 {
                detentLogger.warning("SplitDetent: Invalid value, fraction should be in range 0...1")
                self.detent = .topFull
            } else {
                let notch = Int(round(CGFloat(notches) * value))
                partition = getSnappedPartition(for: notch) + (value == 0 ? lil : value == 1 ? -lil : 0)
            }
        }
        topHeight = cardHeight + partition
    }
    
    func getNotch(for partition: CGFloat) -> Int {
        if partition < -range {
            return 0
        } else if partition > range {
            return notches
        }
        let progress = Int(round((partition + range) / (range * 2) * CGFloat(notches)))
        return progress
    }
    
    func getSnappedPartition(for notch: Int) -> CGFloat {
        let p = CGFloat(notch) / CGFloat(notches) * range * 2 - range
        return p
    }
    
    // MARK: Initialisers
    
    /// Creates a VerticalSplit with top and bottom views and a custom overlay for the top view when minimised.
    /// - Parameters:
    ///   - detent: A binding for controlling the split.
    ///   - topTitle: A title describing the top view, shown when the view is minimised.
    ///   - bottomTitle: A title describing the bottom view, shown when the view is minimised.
    ///   - topView: The content shown in the top view.
    ///   - bottomView: The content shown in the bottom view.
    ///   - topMiniOverlay: A custom overlay for the top view when minimised.
    ///   - bottomMiniOverlay: A custom overlay for the bottom view when minimised.
    public init(
        detent: Binding<SplitDetent> = .constant(.fraction(0.5)),
        topTitle: String,
        bottomTitle: String,
        topView: @escaping () -> TopView,
        bottomView: @escaping () -> BottomView,
        topMiniOverlay: @escaping () -> TopViewOverlay,
        bottomMiniOverlay: @escaping () -> BottomViewOverlay
    ) {
        self._detent = detent
        self.topView = topView
        self.bottomView = bottomView
        self.topViewOverlay = topMiniOverlay
        self.bottomViewOverlay = bottomMiniOverlay
        self.topTitle = topTitle
        self.bottomTitle = bottomTitle
        self.autoTopOverlay = false
        self.autoBottomOverlay = false
    }
    
    /// Creates a VerticalSplit with top and bottom views and a custom overlay for the top view when minimised.
    /// - Parameters:
    ///   - detent: A binding for controlling the split.
    ///   - topTitle: A title describing the top view, shown when the view is minimised.
    ///   - bottomTitle: A title describing the bottom view, shown when the view is minimised.
    ///   - topView: The content shown in the top view.
    ///   - bottomView: The content shown in the bottom view.
    ///   - topMiniOverlay: A custom overlay for the top view when minimised.
    init(
        detent: Binding<SplitDetent> = .constant(.fraction(0.5)),
        topTitle: String,
        bottomTitle: String,
        topView: @escaping () -> TopView,
        bottomView: @escaping () -> BottomView,
        topMiniOverlay: @escaping () -> TopViewOverlay
    ) where BottomViewOverlay == Text {
        self.topView = topView
        self.bottomView = bottomView
        self.topViewOverlay = topMiniOverlay
        self.bottomViewOverlay = { Text(bottomTitle) }
        self.topTitle = topTitle
        self.bottomTitle = bottomTitle
        self.autoTopOverlay = false
        self.autoBottomOverlay = true
        self._detent = detent
    }
    
    /// Creates a VerticalSplit with top and bottom views and a custom overlay for the bottom view when minimised.
    /// - Parameters:
    ///   - detent: A binding for controlling the split.
    ///   - topTitle: A title describing the top view, shown when the view is minimised.
    ///   - bottomTitle: A title describing the bottom view, shown when the view is minimised.
    ///   - topView: The content shown in the top view.
    ///   - bottomView: The content shown in the bottom view.
    ///   - bottomMiniOverlay: A custom overlay for the bottom view when minimised.
    init(
        detent: Binding<SplitDetent> = .constant(.fraction(0.5)),
        topTitle: String,
        bottomTitle: String,
        topView: @escaping () -> TopView,
        bottomView: @escaping () -> BottomView,
        bottomMiniOverlay: @escaping () -> BottomViewOverlay
    ) where TopViewOverlay == Text {
        self.topView = topView
        self.bottomView = bottomView
        self.topViewOverlay = { Text(topTitle) }
        self.bottomViewOverlay = bottomMiniOverlay
        self.topTitle = topTitle
        self.bottomTitle = bottomTitle
        self.autoTopOverlay = true
        self.autoBottomOverlay = false
        self._detent = detent
    }
    
    
    /// Creates a VerticalSplit with top and bottom views.
    /// - Parameters:
    ///   - detent: A binding for controlling the split.
    ///   - topTitle: A title describing the top view, shown when the view is minimised.
    ///   - bottomTitle: A title describing the bottom view, shown when the view is minimised.
    ///   - topView: The content shown in the top view.
    ///   - bottomView: The content shown in the bottom view.
    init(
        detent: Binding<SplitDetent> = .constant(.fraction(0.5)),
        topTitle: String,
        bottomTitle: String,
        topView: @escaping () -> TopView,
        bottomView: @escaping () -> BottomView
    ) where TopViewOverlay == Text, BottomViewOverlay == Text {
        self.topView = topView
        self.bottomView = bottomView
        self.topViewOverlay = { Text(topTitle) }
        self.bottomViewOverlay = { Text(bottomTitle) }
        self.topTitle = topTitle
        self.bottomTitle = bottomTitle
        self.autoTopOverlay = true
        self.autoBottomOverlay = true
        self._detent = detent
    }

}
