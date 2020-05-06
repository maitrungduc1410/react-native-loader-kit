//
//  LoaderKitModule.h
//  CocoaAsyncSocket
//
//  Created by Mai Trung Duc on 6/5/20.
//

#import "RCTViewManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoaderKitModule : RCTViewManager
    
@property (nonatomic, assign) NSNumber *size;

@property (nonatomic, assign) NSString *name;

@property (nonatomic, assign) NSNumber *color;

@end

NS_ASSUME_NONNULL_END
