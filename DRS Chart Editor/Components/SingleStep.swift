import DRSKit
//
//  SingleStep.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/21.
//
import SwiftUI

struct SingleStepShape: Shape {
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

struct SingleStep: View {
    @Binding var step: Seq.Step
    let seq: Seq
    let speed: Double
    @State var showPopover = false
    @State var kind: Seq.Step.Kind = .left
    @State var tick: Int32 = 0
    @State var leftPos: Int32 = 0
    @State var rightPos: Int32 = 0

    var body: some View {
        Group {
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
                y: tickToOffset(step.startTick, seq: seq, speed: speed)
            )
            .padding([.horizontal], 32)
            .onTapGesture {
                showPopover = true
            }
        }
        .sheet(isPresented: $showPopover) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Tick")
                    Spacer()
                    CustomStepperWithTextField(value: $tick, maxValue: seq.info.endTick) {
                        tick = numTickWithMeasures(tick, seq: seq, direction: .next)
                    } onDecrement: {
                        tick = numTickWithMeasures(tick, seq: seq, direction: .previous)
                    }
                        .onAppear {
                            tick = step.startTick
                        }
                        .onChange(of: tick) {
                            step.startTick = tick
                            step.endTick = tick
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
            #if os(iOS)
            .presentationDetents([.medium, .large])
            #endif
        }
    }
}

#Preview {
    struct SingleStepPreview: View {
        var seq = testSeq!
        var step = Binding<Seq.Step>(
            get: { testSeq!.steps.first(where: { $0.kind == .left && $0.longPoints.isEmpty })! },
            set: { testSeq!.steps[testSeq!.steps.firstIndex(where: { $0.kind == .left && $0.longPoints.isEmpty })!] = $0 }
        )

        var body: some View {
            ScrollView {
                VStack {
                    SingleStep(step: step, seq: seq, speed: 1.0)
                }
                .frame(height: tickToOffset(seq.info.endTick, seq: seq, speed: 1.0))
                .frame(maxWidth: .infinity)
            }
        }
    }

    return SingleStepPreview()
}
