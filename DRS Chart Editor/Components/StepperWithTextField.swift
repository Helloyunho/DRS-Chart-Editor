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
            TextField("", text: $textBinding)
                .fixedSize()
            #if os(iOS)
                .keyboardType(.decimalPad)
            #endif
                .submitLabel(.done)
                .focused($focused)
                .onAppear {
                    textBinding = String(value)
                }
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        HStack {
                            Spacer()
                            Button("Done") {
                                focused = false
                            }
                        }
                    }
                }
                .onSubmit {
                    focused = false
                }
            Stepper("", value: $value, in: range, step: step)
        }
        .onChange(of: textBinding) {
            value = T(textBinding) ?? value
        }
        .onChange(of: value) {
            textBinding = String(value)
        }
    }
}
