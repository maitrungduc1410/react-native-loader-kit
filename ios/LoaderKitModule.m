//
//  LoaderKitModule.m
//  CocoaAsyncSocket
//
//  Created by Mai Trung Duc on 6/5/20.
//

#import "LoaderKitModule.h"

@interface RCT_EXTERN_MODULE(LoaderKitManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(size, NSNumber);

RCT_EXPORT_VIEW_PROPERTY(name, NSString);

RCT_EXPORT_VIEW_PROPERTY(color, NSNumber);

@end
