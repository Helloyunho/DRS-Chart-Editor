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

struct LongStepInnerView: View {
    @Binding var step: Seq.Step
    let seq: Seq
    let index: Int

    @State var tick: Int32 = 0
    @State var leftPos: Int32 = 0
    @State var rightPos: Int32 = 0
    @State var enableEndPos: Bool = false
    @State var leftEndPos: Int32 = 0
    @State var rightEndPos: Int32 = 0
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Tick")
                Spacer()
                CustomStepperWithTextField(
                    value: $tick,
                    maxValue: (index != (step.longPoints.count - 1) ? step.longPoints[index + 1].tick : step.endTick)
                ) {
                    let tempTick = numTickWithMeasures(tick, seq: seq, direction: .next)
                    if tempTick <= (index != (step.longPoints.count - 1) ? step.longPoints[index + 1].tick : step.endTick) {
                        tick = tempTick
                    }
                } onDecrement: {
                    let tempTick = numTickWithMeasures(tick, seq: seq, direction: .previous)
                    if tempTick >= (index != 0 ? step.longPoints[index - 1].tick : step.startTick) {
                        tick = tempTick
                    }
                }
                .onAppear {
                    tick = step.longPoints[index].tick
                }
                .onChange(of: tick) {
                    step.longPoints[index].tick = tick
                }
            }
            HStack {
                Text("Left Pos")
                Spacer()
                SliderWithTextFieldInt(value: $leftPos, range: 0...rightPos)
                    .onAppear {
                        leftPos = step.longPoints[index].leftPos
                    }
                    .onChange(of: leftPos) {
                        step.longPoints[index].leftPos = leftPos
                    }
            }
            HStack {
                Text("Right Pos")
                Spacer()
                SliderWithTextFieldInt(value: $rightPos, range: leftPos...65536)
                    .onAppear {
                        rightPos = step.longPoints[index].rightPos
                    }
                    .onChange(of: rightPos) {
                        step.longPoints[index].rightPos = rightPos
                    }
            }
            HStack {
                Text("Custom End Pos")
                Spacer()
                Toggle(isOn: $enableEndPos) {}
                    .onAppear {
                        enableEndPos =
                            step.longPoints[index].leftEndPos != nil && step.longPoints[index].rightEndPos != nil
                    }
                    .onChange(of: enableEndPos) {
                        if enableEndPos {
                            if step.longPoints[index].leftEndPos == nil {
                                step.longPoints[index].leftEndPos = 0
                            }
                            if step.longPoints[index].rightEndPos == nil {
                                step.longPoints[index].rightEndPos = 0
                            }
                        } else {
                            step.longPoints[index].leftEndPos = nil
                            step.longPoints[index].rightEndPos = nil
                        }
                    }
            }
            if enableEndPos {
                HStack {
                    Text("Left End Pos")
                    Spacer()
                    SliderWithTextFieldInt(value: $leftEndPos, range: 0...rightEndPos)
                        .onAppear {
                            leftEndPos = step.longPoints[index].leftEndPos ?? 0
                        }
                        .onChange(of: leftEndPos) {
                            step.longPoints[index].leftEndPos = leftEndPos
                        }
                }
                HStack {
                    Text("Right End Pos")
                    Spacer()
                    SliderWithTextFieldInt(value: $rightEndPos, range: leftEndPos...65536)
                        .onAppear {
                            rightEndPos = step.longPoints[index].rightEndPos ?? 0
                        }
                        .onChange(of: rightEndPos) {
                            step.longPoints[index].rightEndPos = rightEndPos
                        }
                }
            }
            Spacer()
        }
        .padding()
    }
}

struct LongStepSheetView: View {
    @Environment(\.defaultMinListRowHeight) var minRowHeight
    @Binding var showPopover: Bool
    @Binding var step: Seq.Step
    let seq: Seq
    @State var startTick: Int32 = 0
    @State var endTick: Int32 = 0
    @State var kind: Seq.Step.Kind = .left
    @State var leftPos: Int32 = 0
    @State var rightPos: Int32 = 0
    @State var longPoints = [Seq.Step.LongPoint]()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Start Tick")
                    Spacer()
                    CustomStepperWithTextField(value: $startTick, maxValue: seq.info.endTick) {
                        startTick = numTickWithMeasures(startTick, seq: seq, direction: .next)
                    } onDecrement: {
                        startTick = numTickWithMeasures(startTick, seq: seq, direction: .previous)
                    }
                    .onAppear {
                        startTick = step.startTick
                    }
                    .onChange(of: startTick) {
                        step.startTick = startTick
                    }
                }
                HStack {
                    Text("End Tick")
                    Spacer()
                    CustomStepperWithTextField(value: $endTick, maxValue: seq.info.endTick) {
                        endTick = numTickWithMeasures(endTick, seq: seq, direction: .next)
                    } onDecrement: {
                        endTick = numTickWithMeasures(endTick, seq: seq, direction: .previous)
                    }
                    .onAppear {
                        endTick = step.endTick
                    }
                    .onChange(of: endTick) {
                        step.endTick = endTick
                    }
                }
                HStack {
                    Text("Style")
                    Spacer()
                    Picker("Style", selection: $kind) {
                        Text("Left").tag(Seq.Step.Kind.left)
                        Text("Right").tag(Seq.Step.Kind.right)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                    .labelsHidden()
                    .onAppear {
                        kind = step.kind
                    }
                    .onChange(of: kind) {
                        step.kind = kind
                    }
                }
                HStack {
                    Text("Left Pos")
                    SliderWithTextFieldInt(value: $leftPos, range: 0...rightPos)
                        .onAppear {
                            leftPos = step.leftPos
                        }
                        .onChange(of: leftPos) {
                            step.leftPos = leftPos
                        }
                }
                HStack {
                    Text("Right Pos")
                    SliderWithTextFieldInt(value: $rightPos, range: leftPos...65536)
                        .onAppear {
                            rightPos = step.rightPos
                        }
                        .onChange(of: rightPos) {
                            step.rightPos = rightPos
                        }
                }
                Text("Long Steps")
                    .font(.subheadline)
                    .padding(.top)
                List {
                    ForEach(Array(zip(longPoints.indices, longPoints)), id: \.0) { index, lp in
                        NavigationLink {
                            LongStepInnerView(step: $step, seq: seq, index: index)
                                .frame(height: 300)
                        } label: {
                            Text(String(lp.tick))
                                .listRowInsets(EdgeInsets())
                                .contextMenu {
                                    Button {
                                        if longPoints.count != 1 {
                                            longPoints.remove(at: index)
                                        }
                                    } label: {
                                        Text("Delete")
                                    }
                                    .disabled(longPoints.count == 1)
                                }
                        }
                    }
                    .onDelete { offset in
                        if longPoints.count != 1 {
                            step.longPoints.remove(atOffsets: offset)
                        }
                    }
                    #if os(iOS)
                        Button {
                            addNewPoint()
                        } label: {
                            Text("Add")
                        }
                    #endif
                }
                .onAppear {
                    longPoints = step.longPoints
                }
                .onChange(of: longPoints) {
                    step.longPoints = longPoints
                }
                .frame(height: minRowHeight * 3)
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .border(.separator, width: 1)
                .contextMenu {
                    Button {
                        addNewPoint()
                    } label: {
                        Text("Add")
                    }
                }
                Spacer()
                #if os(macOS)
                    HStack {
                        Spacer()
                        Button("OK") {
                            showPopover = false
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    .padding(.top)
                #endif
            }
            .padding()
        }
    }

    func addNewPoint() {
        longPoints.append(Seq.Step.LongPoint(tick: step.endTick, leftPos: 0, rightPos: 65536))
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
        .onTapGesture {
            showPopover = true
        }
        .sheet(isPresented: $showPopover) {
            LongStepSheetView(showPopover: $showPopover, step: $step, seq: seq)
                #if os(iOS)
                    .presentationDetents([.medium, .large])
                #endif
        }
    }
}

#Preview {
    struct LongStepPreview: View {
        var seq = testSeq!
        var step = Binding<Seq.Step>(
            get: { testSeq!.steps.first(where: { $0.kind == .left && !$0.longPoints.isEmpty })! },
            set: {
                testSeq!.steps[testSeq!.steps.firstIndex(where: { $0.kind == .left && !$0.longPoints.isEmpty })!] = $0
            }
        )

        var body: some View {
            ScrollView {
                VStack {
                    LongStep(step: step, seq: seq, speed: 1.0)
                }
                .frame(height: tickToOffset(seq.info.endTick, seq: seq, speed: 1.0))
                .frame(maxWidth: .infinity)
            }
        }
    }

    return LongStepPreview()
}
