//
//  StepperWithTextField.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/22.
//
import SwiftUI

struct CustomStepperWithTextField<T: BinaryInteger & LosslessStringConvertible>: View {
    @Binding var value: T
    let maxValue: T
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    @State var textBinding = "0"
    @FocusState var focused: Bool
    
    init(value: Binding<T>, maxValue: T, onIncrement: @escaping () -> Void, onDecrement: @escaping () -> Void) {
        _value = value
        self.maxValue = maxValue
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
    }
    
    var body: some View {
        HStack {
            TextField(String(maxValue), text: $textBinding)
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
            Stepper("", onIncrement: onIncrement, onDecrement: onDecrement)
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
    struct CustomStepperWithTextField_Preview: View {
        @State var test: Int = 1
        
        var body: some View {
            CustomStepperWithTextField(value: $test, maxValue: 50000) {
                test += 1
            } onDecrement: {
                test -= 1
            }
        }
    }
    
    return CustomStepperWithTextField_Preview()
}
