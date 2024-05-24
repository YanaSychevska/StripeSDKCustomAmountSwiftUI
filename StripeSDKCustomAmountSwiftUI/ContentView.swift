//
//  ContentView.swift
//  StripeSDKCustomAmountSwiftUI
//
//  Created by YanaSychevska on 09.05.24.
//

import SwiftUI
import StripePaymentSheet

struct ContentView: View {
    @FocusState var textFieldFocused: Bool
    @ObservedObject var model = StripePaymentHandler()
    
    @State private var enteredNumber = ""
    var enteredNumberFormatted: Double {
        return (Double(enteredNumber) ?? 0) / 100
    }
    
    var body: some View {
        VStack {
            Text("Enter the amount")
            ZStack(alignment: .center) {
                Text("$\(enteredNumberFormatted, specifier: "%.2f")").font(Font.system(size: 30))
                TextField("", text: $enteredNumber, onEditingChanged: { _ in
                    model.paymentAmount = Int(enteredNumberFormatted * 100)
                }, onCommit: {
                    textFieldFocused = false
                }).focused($textFieldFocused)
                    .keyboardType(.numberPad)
                    .foregroundColor(.clear)
                    .disableAutocorrection(true)
                    .accentColor(.clear)
            }
            Spacer()
            
            if let paymentSheet = model.paymentSheet, !textFieldFocused {
                PaymentSheet.PaymentButton(
                    paymentSheet: paymentSheet,
                    onCompletion: model.onPaymentCompletion
                ) {
                    payButton
                }
            }
        }
        .alert(model.alertText, isPresented: $model.showingAlert) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: textFieldFocused) {
            if !textFieldFocused {
                DispatchQueue.global(qos: .background).sync {
                    model.updatePaymentSheet()
                }
            }
        }
        .onAppear {
            model.preparePaymentSheet()
        }
        .padding(.horizontal)
        .padding(.top, 50)
        .padding(.bottom)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    textFieldFocused = false
                }
            }
        }
    }
    
    @ViewBuilder
    var payButton: some View {
        HStack {
            Spacer()
            Text("Pay $\(enteredNumberFormatted, specifier: "%.2f")")
            Spacer()
        }
        .padding()
        .foregroundColor(.white)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.indigo)
        )
    }
}

#Preview {
    ContentView()
}
