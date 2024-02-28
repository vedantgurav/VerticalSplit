//
//  PhotoEditExample.swift
//  VerticalSplit
//
//  Created by Vedant Gurav on 26/02/2024.
//

import SwiftUI
import VerticalSplit

struct PhotoEditExample: View {
    @State var saturation: CGFloat = 0.5
    @State var contrast: CGFloat = 0.5
    @State var shadows: CGFloat = 0.5
    @State var rotate: CGFloat = 0.5
    
    @State var detent: SplitDetent = .topFull
    
    @State var isAuto = false
    @State var isFilled = false
    
    var body: some View {
        VerticalSplit(
            detent: $detent,
            topTitle: "Photo",
            bottomTitle: "Controls",
            topView: {
                ZStack {
                    Image("neist")
                        .resizable()
                        .aspectRatio(contentMode: isFilled ? .fill : .fit)
                        .saturation(saturation * 2.0)
                        .contrast(contrast * 2.0)
                        .brightness((shadows * 2.0 - 1.0) / 10.0)
                        .frame(maxWidth: 393, maxHeight: .infinity, alignment: .center)
                        .rotationEffect(.degrees(rotate * 10.0 - 5.0))
                        .scaleEffect(1 + abs(rotate - 0.5))
                }
                .frame(maxHeight: .infinity)
                .ignoresSafeArea(edges: .all)
            },
            bottomView: {
                ScrollView {
                    VStack(spacing: 20) {
                        CustomSlider(title: "Saturation", value: $saturation) {
                            String(format: "%.1f", $0 * 2 - 1)
                        }
                        
                        CustomSlider(title: "Contrast", value: $contrast) {
                            String(format: "%.1f", $0 * 2 - 1)
                        }
                        
                        CustomSlider(title: "Shadows", value: $shadows) {
                            String(format: "%.1f", $0 * 2 - 1)
                        }
                        
                        CustomSlider(title: "Straighten", value: $rotate) {
                            String(format: "%.1f", $0 * 10 - 5)
                        }
                    }
                    .padding()
                    .padding(.top)
                }
            },
            topMiniOverlay: {
                HStack {
                    Image(systemName: "photo.fill")
                    Text("Photo")
                        .fontWeight(.medium)
                }
                .font(.system(size: 20))
                .frame(maxWidth: .infinity)
            },
            bottomMiniOverlay: {
                HStack {
                    Image(systemName: "dial.medium.fill")
                    Text("Controls")
                        .fontWeight(.medium)
                }
                .font(.system(size: 20))
                .frame(maxWidth: .infinity)
            }
        )
        .leadingAccessories([
            .init(systemName: "arrow.uturn.backward.circle.fill", action: {}),
            .init(systemName: "arrow.uturn.forward.circle.fill", action: {})
        ])
        .trailingAccessories([
            .init(systemName: "arrow.counterclockwise.circle.fill", action: {
                withAnimation(.smooth(duration: 0.4)) {
                    saturation = 0.5
                    contrast = 0.5
                    shadows = 0.5
                    rotate = 0.5
                    isAuto = false
                }
            })
        ])
        .menuAccessories([
            .init(title: "Markup", systemName: "pencil.tip.crop.circle") {
                detent = .topFull
            },
            .init(
                title: isFilled ? "Fit" : "Fill",
                systemName: isFilled ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
            ) {
                withAnimation(.smooth(duration: 0.6)) {
                    isFilled.toggle()
                }
            },
            .init(
                title: isAuto ? "Manual" : "Auto",
                systemName: "wand.and.stars",
                color: isAuto ? .yellow : .white
            ) {
                withAnimation(.smooth(duration: 0.4)) {
                    if isAuto {
                        saturation = 0.5
                        contrast = 0.5
                        shadows = 0.5
                        rotate = 0.5
                    } else {
                        saturation = 0.65
                        contrast = 0.55
                        shadows = 0.8
                        rotate = 0.46
                    }
                    isAuto.toggle()
                }
            },
        ])
        .debug(true)
        .backgroundColor(.init(uiColor: UIColor(white: 0.16, alpha: 1)))
    }
}

struct CustomSlider: View {
    let title: String
    @Binding var value: CGFloat
    let makeLabel: (CGFloat) -> String
    @GestureState var initialValue: CGFloat?
    @State var width: CGFloat = 0
    let size: CGFloat = 32
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(makeLabel(value))
                    .contentTransition(.numericText(value: value))
                    .monospacedDigit()
            }
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .padding(.horizontal, size / 2)
            ZStack(alignment: .leading) {
                Color.primary.opacity(0.1)
                Color.primary.opacity(0.2)
                    .clipShape(.capsule)
                    .overlay(alignment: .trailing) {
                        Circle()
                            .fill(.white)
                            .shadow(color: .black.opacity(0.2), radius: 8)
                            .padding(4)
                    }
                    .frame(width: size + (width - size) * value)
            }
            .clipShape(.capsule)
            .background {
                GeometryReader(content: { geometry in
                    Color.clear.onAppear {
                        width = geometry.size.width
                    }
                })
            }
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .updating($initialValue, body: { v, s, _ in
                        if s == nil {
                            s = value
                        }
                    })
                    .onChanged({ v in
                        withAnimation(.smooth(duration: 0.2)) {
                            value = max(0, min(1, (initialValue ?? 0) + v.translation.width / (width - size)))
                        }
                    })
            )
            .frame(height: size)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PhotoEditExample()
}
