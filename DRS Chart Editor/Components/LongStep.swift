@preconcurrency import DRSKit
//
//  LongStep.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/21.
//
import SwiftUI

struct LongStepShape: Shape {
    let step: Seq.Step

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let Wratio = rect.maxX / 65536
        let Hratio = rect.maxY / CGFloat(step.endTick - step.startTick)
        var lastY: CGFloat = rect.minY

        let longPoints =
            [Seq.Step.LongPoint(tick: step.startTick, leftPos: step.leftPos, rightPos: step.rightPos)] + step.longPoints

        for i in 0..<longPoints.count - 1 {
            let curr = longPoints[i]
            let next = longPoints[i + 1]
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

        return path
    }
}

struct LongStep: View {
    @Binding var step: Seq.Step
    let seq: Seq
    let speed: Double
    @State var showPopover = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            LongStepShape(step: step)
                .fill(
                    step.kind == .right
                        ? Color.blue.darker(
                            by: 0.1)
                        : Color.orange
                            .darker(
                                by: 0.1)
                )
                .frame(
                    height: tickToOffset(
                        step.endTick, seq: seq, speed: speed)
                        - tickToOffset(
                            step.startTick, seq: seq, speed: speed)
                )
                .overlay(
                    LongStepShape(step: step)
                        .stroke(
                            step.kind
                                == .right
                                ? Color.blue
                                    .darker(
                                        by:
                                            0.1
                                    )
                                : Color
                                    .orange
                                    .darker(
                                        by:
                                            0.1
                                    ),
                            style:
                                StrokeStyle(
                                    lineWidth:
                                        8,
                                    lineCap:
                                        .round,
                                    lineJoin:
                                        .round
                                )
                        )
                )
                .offset(
                    y: tickToOffset(
                        step.startTick, seq: seq, speed: speed)
                )
                .padding([.horizontal], 32)
            SingleStepShape(
                leftPos: step.leftPos,
                rightPos: step.rightPos
            )
            .stroke(
                step.kind == .right
                    ? .blue : .orange,
                style: StrokeStyle(
                    lineWidth: 8,
                    lineCap: .round,
                    lineJoin: .round)
            )
            .frame(height: 4)
            .offset(
                y: tickToOffset(
                    step.startTick, seq: seq, speed: speed)
            )
            .padding([.horizontal], 32)
        }
    }
}

#Preview {
    LongStepShape(
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
