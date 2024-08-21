//
//  Lanes.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/21.
//

import SwiftUI

struct Lanes: View {
    var body: some View {
        HStack {
            VerticalLine()
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: 4)
                .offset(x: 2)
            Spacer()
            VerticalLine()
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 2)
                .offset(x: 1)
            Spacer()
            VerticalLine()
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 2)
                .offset(x: 1)
            Spacer()
            VerticalLine()
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 2)
                .offset(x: 1)
            Spacer()
            VerticalLine()
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: 4)
                .offset(x: 2)
        }
    }
}

#Preview {
    Lanes()
}
