//
//  MapsExample.swift
//  VerticalSplit
//
//  Created by Vedant Gurav on 27/02/2024.
//

import SwiftUI
import VerticalSplit

struct MapsExample: View {
    @State var detent = SplitDetent.bottomMini
    
    var body: some View {
        VerticalSplit(
            detent: $detent,
            topTitle: "Map",
            bottomTitle: "Directions",
            topView: {
                ZStack {
                    Image("map")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 393, maxHeight: .infinity, alignment: .center)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .ignoresSafeArea(.all)
            },
            bottomView: {
                ScrollView {
                    VStack(alignment: .leading, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/) {
                        Text("Directions")
                            .font(.title.bold())
                            .padding(.top)
                        Image("directions")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .clipShape(.rect(cornerRadius: 8))
                    }
                    .padding(16)
                }
            },
            topMiniOverlay: {
                Text("7 stops · 10 min walk · in 12 min")
                    .font(.system(size: 18, design: .rounded))
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
            },
            bottomMiniOverlay: {
                Text("Walk to South Kensington Museums stop")
                    .font(.system(size: 18, design: .rounded))
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
            }
        )
        .leadingAccessories([
            .init(systemName: "figure.walk", color: .gray, action: {}),
            .init(systemName: "car", color: .gray, action: {}),
            .init(systemName: "tram", action: {})
        ])
        .trailingAccessories([
            .init(systemName: "mountain.2.fill", action: {}),
            .init(systemName: "arrow.up.circle.fill", action: {})
        ])
    }
}

#Preview {
    MapsExample()
}
