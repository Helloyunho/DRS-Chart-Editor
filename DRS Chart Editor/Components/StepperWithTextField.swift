//
//  StepperWithTextField.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/22.
//
import SwiftUI

struct StepperWithTextField<T: BinaryInteger & LosslessStringConvertible>: View {
    @Binding var value: T
    let range: ClosedRange<T>
    let step: T.Stride
    @State var textBinding = "0"
    @FocusState var focused: Bool
    
    init(value: Binding<T>, range: ClosedRange<T>, step: T.Stride = 1) {
        _value = value
        self.range = range
        self.step = step
    }
    
    var body: some View {
        HStack {
            TextField(String(range.upperBound), text: $textBinding)
            #if os(iOS)
                .keyboardType(.decimalPad)
            #endif
                .submitLabel(.done)
                .focused($focused)
                .fixedSize()
                .onAppear {
                    textBinding = String(value)
                }
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        if focused {
                            HStack {
                                Spacer()
                                Button("Done") {
                                    focused = false
                                }
                            }
                        }
                    }
                }
                .onSubmit {
                    focused = false
                }
            Stepper("", value: $value, in: range, step: step)
                .labelsHidden()
        }
        .onChange(of: textBinding) {
            value = T(textBinding) ?? value
        }
        .onChange(of: value) {
            textBinding = String(value)
        }
    }
}

#Preview {
    struct StepperWithTextField_Preview: View {
        @State var test: Int = 1
        
        var body: some View {
            StepperWithTextField(value: $test, range: 0...100, step: 1)
        }
    }
    
    return StepperWithTextField_Preview()
}
