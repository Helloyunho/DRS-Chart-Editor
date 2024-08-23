import DRSKit
//
//  StepView.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/22.
//
import SwiftUI

struct StepView: View {
    @Binding var step: Seq.Step
    let seq: Seq
    let speed: Double

    var body: some View {
        switch step.kind {
        case .down:
            DownStep(step: $step, seq: seq, speed: speed)
        case .jump:
            JumpStep(step: $step, seq: seq, speed: speed)
        default:
            // normal step
            if step.longPoints.isEmpty {
                SingleStep(step: $step, seq: seq, speed: speed)
            } else {
                LongStep(step: $step, seq: seq, speed: speed)
            }
        }
    }
}
