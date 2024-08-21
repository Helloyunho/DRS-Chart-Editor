//
//  SingleStep.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/21.
//
import SwiftUI

struct SingleStep: Shape {
    let leftPos: Int32
    let rightPos: Int32

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let ratio = rect.maxX / 65536

        path.move(to: CGPoint(x: CGFloat(leftPos) * ratio, y: rect.minY))
        path.addLine(to: CGPoint(x: CGFloat(rightPos) * ratio, y: rect.minY))
        path.closeSubpath()

        return path
    }
}

#Preview {
    SingleStep(leftPos: 0, rightPos: 23310)
        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
}
