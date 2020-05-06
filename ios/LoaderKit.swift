//
//  LoaderKit.swift
//  LoaderKit
//
//  Created by Mai Trung Duc on 6/5/20.
//  Copyright © 2020 Facebook. All rights reserved.
//

import Foundation
import NVActivityIndicatorView

let animations = [
  "BallPulse": NVActivityIndicatorType.ballPulse,
  "BallGridPulse": NVActivityIndicatorType.ballGridPulse,
  "BallClipRotate": NVActivityIndicatorType.ballClipRotate,
  "SquareSpin": NVActivityIndicatorType.squareSpin,
  "BallClipRotatePulse": NVActivityIndicatorType.ballClipRotatePulse,
  "BallClipRotateMultiple": NVActivityIndicatorType.ballClipRotateMultiple,
  "BallPulseRise": NVActivityIndicatorType.ballPulseRise,
  "BallRotate": NVActivityIndicatorType.ballRotate,
  "CubeTransition": NVActivityIndicatorType.cubeTransition,
  "BallZigZag": NVActivityIndicatorType.ballZigZag,
  "BallZigZagDeflect": NVActivityIndicatorType.ballZigZagDeflect,
  "BallTrianglePath": NVActivityIndicatorType.ballTrianglePath,
  "BallScale": NVActivityIndicatorType.ballScale,
  "LineScale": NVActivityIndicatorType.lineScale,
  "LineScaleParty": NVActivityIndicatorType.lineScaleParty,
  "BallScaleMultiple": NVActivityIndicatorType.ballScaleMultiple,
  "BallPulseSync": NVActivityIndicatorType.ballPulseSync,
  "BallBeat": NVActivityIndicatorType.ballBeat,
  "BallDoubleBounce": NVActivityIndicatorType.ballDoubleBounce,
  "LineScalePulseOut": NVActivityIndicatorType.lineScalePulseOut,
  "LineScalePulseOutRapid": NVActivityIndicatorType.lineScalePulseOutRapid,
  "BallScaleRipple": NVActivityIndicatorType.ballScaleRipple,
  "BallScaleRippleMultiple": NVActivityIndicatorType.ballScaleRippleMultiple,
  "BallSpinFadeLoader": NVActivityIndicatorType.ballSpinFadeLoader,
  "LineSpinFadeLoader": NVActivityIndicatorType.lineSpinFadeLoader,
  "TriangleSkewSpin": NVActivityIndicatorType.triangleSkewSpin,
  "Pacman": NVActivityIndicatorType.pacman,
  "BallGridBeat": NVActivityIndicatorType.ballGridBeat,
  "SemiCircleSpin": NVActivityIndicatorType.semiCircleSpin,
  "BallRotateChase": NVActivityIndicatorType.ballRotateChase,
  "Orbit": NVActivityIndicatorType.orbit,
  "AudioEqualizer": NVActivityIndicatorType.audioEqualizer,
  "CircleStrokeSpin": NVActivityIndicatorType.circleStrokeSpin,
]

class LoaderKit: UIView {
    var loader: NVActivityIndicatorView!
    var currentSize = 48.0

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    let frameObj = CGRect(x: 0, y: 0, width: 200, height: 200)
    self.loader = NVActivityIndicatorView(frame: frameObj, type: NVActivityIndicatorView.DEFAULT_TYPE)
    self.addSubview(self.loader)
    self.loader.startAnimating()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
    
    @objc
    var size: NSNumber? {
      set {
        if newValue != nil {
            self.loader.stopAnimating()
            let frameObj = CGRect(x: 0, y: 0, width: newValue!.doubleValue, height: newValue!.doubleValue)
            self.loader.frame = frameObj
            self.loader.startAnimating()
            
            self.currentSize = newValue!.doubleValue
        }
      }
      get {
        return nil;
      }
    }
    
    @objc
    var name: NSString? {
      set {
        if newValue != nil && animations[newValue! as String] != nil {
            self.loader.stopAnimating()
            let frameObj = CGRect(x: 0, y: 0, width: self.currentSize, height: self.currentSize)
            self.loader.frame = frameObj
            self.loader.type = animations[newValue! as String]!
            self.loader.startAnimating()
            
        }
      }
      get {
        return nil;
      }
    }
    
    @objc
    var color: NSNumber? {
      set {
        if newValue != nil {
            self.loader.stopAnimating()
            let frameObj = CGRect(x: 0, y: 0, width: self.currentSize, height: self.currentSize)
            self.loader.frame = frameObj
            self.loader.color = RCTConvert.uiColor(newValue)
            self.loader.startAnimating()
        }
      }
      get {
        return nil;
      }
    }
}
