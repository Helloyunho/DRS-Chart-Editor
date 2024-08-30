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
    @State var textBinding = "0"
    @FocusState var focused: Bool
    var intProxy: Binding<Double>{
        Binding<Double>(get: {
            return Double(value)
        }, set: {
            value = T($0)
        })
    }

    init(value: Binding<T>, range: ClosedRange<T>) {
        _value = value
        self.range = range
    }
    
    var body: some View {
        HStack {
            Slider(value: intProxy, in: Double(range.lowerBound)...Double(range.upperBound))
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
        }
        .onChange(of: textBinding) {
            value = T(textBinding) ?? value
        }
        .onChange(of: value) {
            textBinding = String(value)
        }
    }
}

struct SliderWithTextField<T>: View where T: BinaryFloatingPoint & LosslessStringConvertible, T.Stride: BinaryFloatingPoint {
    @Binding var value: T
    let range: ClosedRange<T>
    @State var textBinding = "0"
    @FocusState var focused: Bool
    
    init(value: Binding<T>, range: ClosedRange<T>) {
        _value = value
        self.range = range
    }

    var body: some View {
        HStack {
            Slider(value: $value, in: range)
            TextField(String(range.upperBound), text: $textBinding)
            #if os(iOS)
                .keyboardType(.decimalPad)
            #endif
                .submitLabel(.done)
                .focused($focused)
                .fixedSize()
                .onAppear {
                    textBinding = String(format: "%.1f", value as! CVarArg)
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
        }
        .onChange(of: textBinding) {
            value = T(textBinding) ?? value
        }
        .onChange(of: value) {
            textBinding = String(format: "%.1f", value as! CVarArg)
        }
    }
}

#Preview {
    struct SliderWithTextField_Preview: View {
        @State var test: Double = 1
        @State var testInt: Int = 1
        
        var body: some View {
            VStack {
                SliderWithTextField(value: $test, range: 0...65536)
                SliderWithTextFieldInt(value: $testInt, range: 0...65536)
            }
        }
    }
    
    return SliderWithTextField_Preview()
}
