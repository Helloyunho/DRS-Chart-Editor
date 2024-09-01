import DRSKit
//
//  DownStep.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/22.
//
import SwiftUI

struct DownStep: View {
    @Binding var step: Seq.Step
    let seq: Seq
    let speed: Double
    @State var showPopover = false
    @State var tick: Int32 = 0

    var body: some View {
        Circle()
            .fill(.yellow)
            .frame(width: 16, height: 16)
            .offset(
                y: tickToOffset(step.startTick, seq: seq, speed: speed) - 8
            )
            .sheet(isPresented: $showPopover) {
                VStack {
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
    struct DownStepPreview: View {
        var seq = testSeq!
        var step = Binding<Seq.Step>(
            get: { testSeq!.steps.first(where: { $0.kind == .down })! },
            set: { testSeq!.steps[testSeq!.steps.firstIndex(where: { $0.kind == .down })!] = $0 }
        )

        var body: some View {
            ScrollView {
                VStack {
                    DownStep(step: step, seq: seq, speed: 1.0)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    return DownStepPreview()
}
