//
//  SliderWithTextField.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/22.
//
import SwiftUI
import Sliders

struct RangeSliderWithTextFieldInt<T>: View where T: FixedWidthInteger & LosslessStringConvertible, T.Stride: BinaryInteger {
    enum TextFieldFocusing {
        case start
        case end
    }
    
    @Binding var value: ClosedRange<T>
    let range: ClosedRange<T>
    let step: T.Stride
    @State var startTextBinding = "0"
    @State var endTextBinding = "0"
    @FocusState var focused: TextFieldFocusing?
    
    init(value: Binding<ClosedRange<T>>, range: ClosedRange<T>, step: T.Stride = 1) {
        _value = value
        self.range = range
        self.step = step
    }

    var body: some View {
        HStack {
            TextField("", text: $startTextBinding)
            #if os(iOS)
                .keyboardType(.decimalPad)
            #endif
                .submitLabel(.done)
                .focused($focused, equals: .start)
                .onAppear {
                    startTextBinding = String(value.lowerBound)
                }
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        HStack {
                            Spacer()
                            Button("Done") {
                                focused = nil
                            }
                        }
                    }
                }
                .onSubmit {
                    focused = nil
                }
            RangeSlider(range: $value, in: range, step: step) { _ in
                startTextBinding = String(value.lowerBound)
                endTextBinding = String(value.upperBound)
            }
            .frame(maxWidth: .infinity)
            TextField("", text: $endTextBinding)
            #if os(iOS)
                .keyboardType(.decimalPad)
            #endif
                .submitLabel(.done)
                .focused($focused, equals: .end)
                .onAppear {
                    endTextBinding = String(value.upperBound)
                }
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        HStack {
                            Spacer()
                            Button("Done") {
                                focused = nil
                            }
                        }
                    }
                }
                .onSubmit {
                    focused = nil
                }
        }
        .onChange(of: startTextBinding) {
            value = (T(startTextBinding) ?? value.lowerBound)...value.upperBound
        }
        .onChange(of: endTextBinding) {
            value = value.lowerBound...(T(endTextBinding) ?? value.upperBound)
        }
    }
}

struct RangeSliderWithTextField<T>: View where T: BinaryFloatingPoint & LosslessStringConvertible, T.Stride: BinaryFloatingPoint {
    enum TextFieldFocusing {
        case start
        case end
    }
    
    @Binding var value: ClosedRange<T>
    let range: ClosedRange<T>
    let step: T.Stride
    @State var startTextBinding = "0"
    @State var endTextBinding = "0"
    @FocusState var focused: TextFieldFocusing?
    
    init(value: Binding<ClosedRange<T>>, range: ClosedRange<T>, step: T.Stride = 0.001) {
        _value = value
        self.range = range
        self.step = step
    }

    var body: some View {
        HStack {
            TextField("", text: $startTextBinding)
            #if os(iOS)
                .keyboardType(.decimalPad)
            #endif
                .submitLabel(.done)
                .focused($focused, equals: .start)
                .onAppear {
                    startTextBinding = String(value.lowerBound)
                }
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        HStack {
                            Spacer()
                            Button("Done") {
                                focused = nil
                            }
                        }
                    }
                }
                .onSubmit {
                    focused = nil
                }
            RangeSlider(range: $value, in: range, step: step) { _ in
                startTextBinding = String(value.lowerBound)
                endTextBinding = String(value.upperBound)
            }
            .frame(maxWidth: .infinity)
            TextField("", text: $endTextBinding)
            #if os(iOS)
                .keyboardType(.decimalPad)
            #endif
                .submitLabel(.done)
                .focused($focused, equals: .end)
                .onAppear {
                    endTextBinding = String(value.upperBound)
                }
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        HStack {
                            Spacer()
                            Button("Done") {
                                focused = nil
                            }
                        }
                    }
                }
                .onSubmit {
                    focused = nil
                }
        }
        .onChange(of: startTextBinding) {
            value = (T(startTextBinding) ?? value.lowerBound)...value.upperBound
        }
        .onChange(of: endTextBinding) {
            value = value.lowerBound...(T(endTextBinding) ?? value.upperBound)
        }
    }
}
