//
//  LoaderKitManager.swift
//  CocoaAsyncSocket
//
//  Created by Mai Trung Duc on 6/5/20.
//

import Foundation

@objc(LoaderKitManager)
class LoaderKitManager : RCTViewManager {
  override func view() -> UIView! {
    return LoaderKit();
  }

  @objc override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}
