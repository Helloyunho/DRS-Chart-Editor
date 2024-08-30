import DRSKit
//
//  JumpStep.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/22.
//
import SwiftUI

struct JumpStep: View {
    @Binding var step: Seq.Step
    let seq: Seq
    let speed: Double
    @State var showPopover = false
    @State var tick: Int32 = 0

    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: 16, height: 16)
            .offset(
                y: tickToOffset(step.startTick, seq: seq, speed: speed)
            )
            .sheet(isPresented: $showPopover) { // trust me i tried popover but it didnt end up well
                VStack {
                    HStack {
                        Text("Tick")
                        Spacer()
                        StepperWithTextField(value: $tick, range: 0...seq.info.endTick)
                            .onAppear {
                                tick = step.startTick
                            }
                            .onChange(of: tick) {
                                step.startTick = tick
                                step.endTick = tick
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
            .onTapGesture {
                showPopover = true
            }
    }
}

#Preview {
    struct JumpStepPreview: View {
        var seq = testSeq!
        var step = Binding<Seq.Step>(
            get: { testSeq!.steps.first(where: { $0.kind == .jump })! },
            set: { testSeq!.steps[testSeq!.steps.firstIndex(where: { $0.kind == .jump })!] = $0 }
        )

        var body: some View {
            ScrollView {
                VStack {
                    JumpStep(step: step, seq: seq, speed: 1.0)
                }
                .frame(height: tickToOffset(seq.info.endTick, seq: seq, speed: 1.0))
                .frame(maxWidth: .infinity)
            }
        }
    }

    return JumpStepPreview()
}
