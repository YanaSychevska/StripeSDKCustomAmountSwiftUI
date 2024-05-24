//
//  StripePaymentHandler.swift
//  StripeSDKCustomAmountSwiftUI
//
//  Created by YanaSychevska on 09.05.24.
//

import StripePaymentSheet
import SwiftUI

class StripePaymentHandler: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var showingAlert: Bool = false
    
    private let backendtUrl = URL(string: "http://localhost:4242")!
    private var configuration = PaymentSheet.Configuration()
    private var clientSecret = ""
    private var paymentIntentID: String = ""
    
    var alertText: String = ""
    var paymentAmount: Int = 0
    
    func preparePaymentSheet() {
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        let url = backendtUrl.appendingPathComponent("prepare-payment-sheet")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                  let customerId = json["customer"] as? String,
                  let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                  let clientSecret = json["clientSecret"] as? String,
                  let paymentIntentID = json["paymentIntentID"] as? String,
                  let publishableKey = json["publishableKey"] as? String,
                  let self = self else {
                // Handle error
                return
            }
            
            self.clientSecret = clientSecret
            self.paymentIntentID = paymentIntentID
            STPAPIClient.shared.publishableKey = publishableKey
            
            // MARK: Create a PaymentSheet instance
            configuration.merchantDisplayName = "Example, Inc."
            configuration.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
            configuration.allowsDelayedPaymentMethods = true
            configuration.applePay = .init(
              merchantId: "merchant.com.your_app_name",
              merchantCountryCode: "US"
            )
            configuration.returnURL = "your-app://stripe-redirect"
        })
        task.resume()
    }
    
    func updatePaymentSheet() {
        DispatchQueue.main.async {
           self.paymentSheet = nil
        }
        
        let bodyProperties: [String: Any] = [
            "paymentIntentID": paymentIntentID,
            "amount": paymentAmount
        ]
        
        let url = backendtUrl.appendingPathComponent("update-payment-sheet")
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyProperties)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let self = self else {
                // Handle error
                return
            }
            DispatchQueue.main.async {
               self.paymentSheet = PaymentSheet(paymentIntentClientSecret: self.clientSecret, configuration: self.configuration)
            }
        })
        task.resume()
    }
    
    func onPaymentCompletion(result: PaymentSheetResult) {
        switch result {
        case .completed:
            self.alertText = "Payment complete!"
        case .canceled:
            self.alertText = "Payment canceled!"
        case .failed(let error):
            self.alertText = "Payment failed \(error.localizedDescription)"
        }
        
        showingAlert = true
    }
}

