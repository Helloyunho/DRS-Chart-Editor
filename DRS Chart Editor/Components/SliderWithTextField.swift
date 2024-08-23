//
//  SliderWithTextField.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/22.
//
import SwiftUI

struct SliderWithTextFieldInt<T>: View where T: BinaryInteger & LosslessStringConvertible, T.Stride: BinaryInteger {
    @Binding var value: T
    let range: ClosedRange<T>
    let step: T.Stride
    var intProxy: Binding<Double>{
        Binding<Double>(get: {
            return Double(value)
        }, set: {
            value = T($0)
        })
    }

    init(value: Binding<T>, range: ClosedRange<T>, step: T.Stride = 1) {
        _value = value
        self.range = range
        self.step = step
    }
    
    var body: some View {
        SliderWithTextField(value: intProxy, range: Double(range.lowerBound)...Double(range.upperBound), step: Double.Stride(step))
    }
}

struct SliderWithTextField<T>: View where T: BinaryFloatingPoint & LosslessStringConvertible, T.Stride: BinaryFloatingPoint {
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
            Slider(value: $value, in: range, step: step) { _ in
                textBinding = String(value)
            }
            TextField("", text: $textBinding)
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
        }
        .onChange(of: textBinding) {
            value = T(textBinding) ?? value
        }
    }
}
