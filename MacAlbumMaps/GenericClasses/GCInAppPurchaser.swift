//
//  GCInAppPurchaser.swift
//  MacAlbumMaps
//
//  Created by BobZhang on 2017/3/15.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa
import StoreKit

class GCInAppPurchaser: NSObject,SKProductsRequestDelegate,SKPaymentTransactionObserver {
    
    override init(){
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    private var isPurchaseAction = false
    
    // Keep a strong reference to the request.
    private var productsRequest: SKProductsRequest?
    private var productsDictionary = Dictionary<String,Int>()
    
    var didReceiveValidProductIdentifiers: ((_ invalidProductIdentifiers: [String]?) -> Void)?
    var purchaseCompletionHandler: ((_ productIdentifier: String?) -> Void)?
    var restoreCompletionHandler: ((_ productIdentifier: String?) -> Void)?
    
    func purchase(productsIdentifierQuantityDictionary: Dictionary<String,Int>) -> Void {
        isPurchaseAction = true
        productsDictionary = productsIdentifierQuantityDictionary
        
        let productIdentifiers = productsDictionary.keys.sorted()
        productsRequest = SKProductsRequest.init(productIdentifiers: Set.init(productIdentifiers))
        
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    func restore() -> Void {
        isPurchaseAction = false
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - SKProductsRequestDelegate protocol method
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        
        if products.count > 0 {
            let validProductIdentifiers = products.map({ (product) -> String in
                product.productIdentifier
            })
            didReceiveValidProductIdentifiers?(validProductIdentifiers)
            
            self.requestingPayment(products: products)
        }else{
            didReceiveValidProductIdentifiers?(nil)
        }
    }
    
    func requestingPayment(products: [SKProduct]) -> Void {
        for product in products {
            let payment = SKMutablePayment.init(product: product)
            if let quantity = productsDictionary[product.productIdentifier] {
                payment.quantity = quantity
            }
            SKPaymentQueue.default().add(payment)
        }
    }
    
    // MARK: - SKPaymentTransactionObserver protocol method
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                break
            case .deferred:
                break
            case .failed:
                self.completePurchaseTransaction(transaction: transaction, succeeded: false)
            case .purchased:
                self.completePurchaseTransaction(transaction: transaction, succeeded: true)
            case .restored:
                if isPurchaseAction {
                    // 用户已经购买过了，但是又选择购买，这时的交易状态 .restored
                    self.completePurchaseTransaction(transaction: transaction, succeeded: true)
                }else{
                    self.completeRestoreTransaction(transaction: transaction, succeeded: true)
                }
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        self.completeRestoreTransaction(transaction: nil, succeeded: false)
    }
    
    // MARK: - Result
    func completePurchaseTransaction(transaction: SKPaymentTransaction,succeeded: Bool){
        
        DispatchQueue.main.async {
            if succeeded {
                self.purchaseCompletionHandler?(transaction.payment.productIdentifier)
            }else{
                self.purchaseCompletionHandler?(nil)
            }
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    func completeRestoreTransaction(transaction: SKPaymentTransaction?,succeeded: Bool){
        
        DispatchQueue.main.async {
            if succeeded {
                self.restoreCompletionHandler?(transaction!.payment.productIdentifier)
                
            }else{
                self.restoreCompletionHandler?(nil)
            }
        }
        
        
        if transaction != nil{
            SKPaymentQueue.default().finishTransaction(transaction!)
        }
    }

}
