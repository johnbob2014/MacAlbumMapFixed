//
//  PurchaseShareAndBrowseVC.swift
//  MacAlbumMaps
//
//  Created by BobZhang on 2017/3/16.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa

class PurchaseShareAndBrowseVC: NSViewController {
    let purchaser = GCInAppPurchaser()

    @IBOutlet weak var checkButtonsContainer: NSView!
    
    @IBAction func cancelAction(_ sender: NSButton) {
        self.dismiss(nil)
    }
    
    @IBAction func restoreAction(_ sender: NSButton) {
        self.showProgressIndicator()
        
        purchaser.restoreCompletionHandler = { productID in
            self.hideProgressIndicator()
            
            if let id = productID {
                print("Restore succeeded: " + id)
                self.checkSucceeded(true)
            }else{
                print("Restore failed!")
                self.checkSucceeded(false)
            }
            
        }
        purchaser.restore()
    }
    
    @IBAction func purchaseAction(_ sender: NSButton) {
        self.showProgressIndicator()
        
        purchaser.didReceiveProducts = { products in
            if products.count > 0{
                print("Valid Products Count: \(products.count)")
                self.priceLabel.stringValue = NSLocalizedString("Price: ",comment:"价格：") + String.init(format: "%.2f", products.first!.price.floatValue)
            }else{
                print("No requested products in App Store!")
            }
        }
        
        purchaser.purchaseCompletionHandler = { productID in
            self.hideProgressIndicator()
            
            if let id = productID {
                print("Purchase succeeded: " + id)
                self.checkSucceeded(true)
            }else{
                print("Purchase failed!")
                self.checkSucceeded(false)
            }
        }
        
        purchaser.purchase(productsIdentifierQuantityDictionary: ["com.ZhangBaoGuo.MacAlbumMaps.ShareAndBrowse":1])
    }
    
    @IBOutlet weak var priceLabel: NSTextField!
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    func showProgressIndicator()  {
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
    }
    
    func hideProgressIndicator()  {
        progressIndicator.isHidden = true
        progressIndicator.stopAnimation(nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.title = NSLocalizedString("Purchase and Restore",comment:"购买和恢复")
        
        checkButtonsContainer.isHidden = true
        
        progressIndicator.isHidden = true
        
        priceLabel.isHidden = true
    }
    
    func checkSucceeded(_ succeeded: Bool){
        if succeeded {
            MAMSettingManager.hasPurchasedShareAndBrowse = true
            checkButtonsContainer.isHidden = false
        }
        
        if let window = self.view.window{
            NSAlert.createSimpleAlertAndBeginSheetModal(messageText: succeeded ? NSLocalizedString("Succeeded!",comment:"成功！") : NSLocalizedString("Failed!",comment:"失败"), for: window)
//            let alert = NSAlert.init()
//            alert.messageText =
//            alert.beginSheetModal(for: window)
        }
        
    }
}
