//
//  ChartView.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/21.
//

import DRSKit
import Kroma
import SwiftUI
import Combine

struct ChartView: View {
    let seq: Seq
    @State var speed: Double = 4.0
    @State private var position = ScrollPosition(edge: .top)
    @State var isPlaying = false
    @State var playBarOffset: CGFloat = 0.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        Lanes()
                            .frame(
                                height: timeToOffset(seq.info.endTick)
                            )
                            .padding([.horizontal], 32)
                        ForEach(seq.steps, id: \.self) { step in
                            switch step.kind {
                            case .down:
                                Circle()
                                    .fill(.yellow)
                                    .frame(width: 16, height: 16)
                                    .offset(
                                        y: timeToOffset(step.startTick))
                            case .jump:
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 16, height: 16)
                                    .offset(
                                        y: timeToOffset(step.startTick))
                            default:
                                // normal step
                                if step.longPoints.isEmpty {
                                    SingleStep(
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
                                        y: timeToOffset(step.startTick)
                                    )
                                    .padding([.horizontal], 32)
                                } else {
                                    ZStack(alignment: .topLeading) {
                                        LongStep(step: step)
                                            .fill(
                                                step.kind == .right
                                                    ? Color.blue.darker(
                                                        by: 0.1)
                                                    : Color.orange
                                                        .darker(
                                                            by: 0.1)
                                            )
                                            .frame(
                                                height: timeToOffset(
                                                    step.endTick)
                                                    - timeToOffset(
                                                        step.startTick)
                                            )
                                            .overlay(
                                                LongStep(step: step)
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
                                                y: timeToOffset(
                                                    step.startTick)
                                            )
                                            .padding([.horizontal], 32)
                                        SingleStep(
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
                                            y: timeToOffset(
                                                step.startTick)
                                        )
                                        .padding([.horizontal], 32)
                                    }
                                }
                            }
                        }
                        HorizontalLine()
                            .stroke(
                                .green,
                                style: StrokeStyle(
                                    lineWidth: 4, lineCap: .round, lineJoin: .round)
                            )
                            .frame(height: 4)
                            .offset(y: 2 + playBarOffset)
                    }
                    Spacer()
                        .frame(height: geometry.size.height)
                }
                .scrollPosition($position)
            }
        }
        .padding()
        .toolbar {
            ToolbarItemGroup {
                Button {
                    withAnimation {
                        position.scrollTo(edge: .top)
                    }
                } label: {
                    Label("Go Top", systemImage: "arrow.up.to.line")
                }
                .disabled(position.edge == .top)
                Button {
                    withAnimation {
                        position.scrollTo(edge: .bottom)
                    }
                } label: {
                    Label("Go Bottom", systemImage: "arrow.down.to.line")
                }
                .disabled(position.edge == .bottom)
                Menu {
                    Button {

                    } label: {
                        Label("Note", systemImage: "minus")
                    }
                    Button {

                    } label: {
                        Label(
                            "Long Note", systemImage: "rectangle.portrait.fill")
                    }
                    Button {

                    } label: {
                        Label("Down", systemImage: "arrowshape.down")
                    }
                    Button {

                    } label: {
                        Label("Jump", systemImage: "chevron.up.2")
                    }
                } label: {
                    Label("New", systemImage: "plus")
                }
                .disabled(isPlaying)

                if isPlaying {
                    Button {
                        withAnimation(.none) {
                            playBarOffset = 0
                        }
                        print(playBarOffset)
                        isPlaying = false
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                    }
                } else {
                    Button {
                        let songLength = Double(seq.info.endTick) / 1000
                        let currPosToTime =
                        Double(offsetToTime(playBarOffset)) / 1000
                        let animation = Animation.linear(
                            duration: 10)
                        withAnimation(animation) {
                            playBarOffset = timeToOffset(seq.info.endTick)
                        } completion: {
                            isPlaying = false
                            playBarOffset = 0
                        }
                        isPlaying = true
                    } label: {
                        Label("Play", systemImage: "play.fill")
                    }
                }
            }
        }
    }

    func timeToOffset(_ time: Int32) -> CGFloat {
        CGFloat(time) / CGFloat(seq.info.timeUnit) * 8 * 4.0 * speed
    }

    func offsetToTime(_ offset: CGFloat) -> Int32 {
        return Int32(offset / 8.0 / 4.0 / speed * CGFloat(seq.info.timeUnit))
    }

    func getBPMAndMeasure(by tick: Int32) -> (Seq.Info.BPM, Seq.Info.Measure) {
        let bpm = seq.info.bpm.enumerated().first(where: { (i, bpm) in
            i + 1 == seq.info.bpm.count
                || (bpm.tick <= tick && seq.info.bpm[i + 1].tick > tick)
        })!.element

        let measure = seq.info.measure.enumerated().first(where: {
            (i, measure) in
            i + 1 == seq.info.measure.count
                || (measure.tick <= tick && seq.info.measure[i + 1].tick > tick)
        })!.element

        return (bpm, measure)
    }
}

#Preview {
    struct ChartViewPreview: View {
        let seq = Seq(end: 120000, bpm: 120)

        var body: some View {
            NavigationStack {
                ChartView(seq: seq)
            }
        }
    }

    return ChartViewPreview()
}
