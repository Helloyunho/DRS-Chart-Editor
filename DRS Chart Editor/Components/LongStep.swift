//
//  LongStep.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/21.
//
import SwiftUI
@preconcurrency import DRSKit

struct LongStep: Shape {
    let step: Seq.Step

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let Wratio = rect.maxX / 65536
        let Hratio = rect.maxY / CGFloat(step.endTick - step.startTick)
        var lastY: CGFloat = rect.minY
        
        let longPoints = [Seq.Step.LongPoint(tick: step.startTick, leftPos: step.leftPos, rightPos: step.rightPos)] + step.longPoints
        
        for i in 0..<longPoints.count-1 {
            let curr = longPoints[i]
            let next = longPoints[i+1]
            var path_ = Path()
            path_.move(to: CGPoint(x: CGFloat(curr.leftEndPos ?? curr.leftPos) * Wratio, y: lastY))
            path_.addLine(to: CGPoint(x: CGFloat(curr.rightEndPos ?? curr.rightPos) * Wratio, y: lastY))
            lastY += CGFloat(next.tick - curr.tick) * Hratio
            path_.addLine(to: CGPoint(x: CGFloat(next.rightPos) * Wratio, y: lastY))
            path_.addLine(to: CGPoint(x: CGFloat(next.leftPos) * Wratio, y: lastY))
            path_.closeSubpath()
            if let leftEndPos = next.leftEndPos, let rightEndPos = next.rightEndPos {
                path_.move(to: CGPoint(x: CGFloat(next.leftPos) * Wratio, y: lastY))
                path_.addLine(to: CGPoint(x: CGFloat(leftEndPos) * Wratio, y: lastY))
                path_.addLine(to: CGPoint(x: CGFloat(rightEndPos) * Wratio, y: lastY))
                path_.closeSubpath()
            }
            path.addPath(path_)
        }
//        var lastPoint = CGPoint.zero
//        let y = rect.minY
//        var tempPath = Path()
//
//        path.move(to: CGPoint(x: CGFloat(step.leftPos) * Wratio, y: y))
//        lastPoint = CGPoint(x: CGFloat(step.rightPos) * Wratio, y: y)
//        path.addLine(to: lastPoint)
//
//        for (i, point) in step.longPoints.enumerated() {
//            let y = CGFloat(abs(step.startTick - point.tick)) * Hratio
//            var path = i == 0 ? path : tempPath
//            path.addLine(
//                to: CGPoint(
//                    x: CGFloat(point.rightPos) * Wratio,
//                    y: y))
//            lastPoint = CGPoint(
//                x: CGFloat(point.leftPos) * Wratio,
//                y: y)
//            path.addLine(to: lastPoint)
//            path.closeSubpath()
//            if let leftEndPos = point.leftEndPos,
//                let rightEndPos = point.rightEndPos
//            {
//                path.move(to: lastPoint)
//                lastPoint = CGPoint(
//                    x: CGFloat(leftEndPos) * Wratio,
//                    y: y)
//                path.addLine(
//                    to: lastPoint)
//                path.move(to: lastPoint)
//                lastPoint = CGPoint(
//                    x: CGFloat(rightEndPos) * Wratio,
//                    y: y)
//                path.addLine(to: lastPoint)
//            }
//            if i != 0 {
//                path.addPath(tempPath)
//                tempPath = Path()
//            }
//        }
//        path.closeSubpath()

        return path
    }
}

#Preview {
    LongStep(
        step: DRSKit.Seq.Step(
            startTick: 24960, endTick: 25440, leftPos: 45056, rightPos: 65536,
            longPoints: [
                DRSKit.Seq.Step.LongPoint(
                    tick: 25200, leftPos: 45056, rightPos: 65536, leftEndPos: Optional(32768),
                    rightEndPos: Optional(53248)),
                DRSKit.Seq.Step.LongPoint(
                    tick: 25440, leftPos: 32768, rightPos: 53248, leftEndPos: Optional(20480),
                    rightEndPos: Optional(40960)),
            ], kind: DRSKit.Seq.Step.Kind.right, playerID: DRSKit.Seq.Step.PlayerID.Player1)
    )
    .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
}
