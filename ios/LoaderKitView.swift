//
//  LoaderKitView.swift
//  LoaderKit
//
//  Created by Duc Trung Mai on 10/21/25.
//

import React

@objc(LoaderKitViewManager)
class LoaderKitViewManager: RCTViewManager {
    
    override func view() -> (NVActivityIndicatorView) {
      return NVActivityIndicatorView(frame: .zero)
    }
    
    @objc override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}
