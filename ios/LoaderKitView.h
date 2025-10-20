#ifdef RCT_NEW_ARCH_ENABLED
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef LoaderKitViewNativeComponent_h
#define LoaderKitViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface LoaderKitView : RCTViewComponentView
@end

NS_ASSUME_NONNULL_END

#endif /* LoaderKitViewNativeComponent_h */

#else

#import "React/RCTViewManager.h"

@interface LoaderKitViewManager : RCTViewManager
@end

#endif
