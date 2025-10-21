#import "LoaderKitView.h"

#ifdef RCT_NEW_ARCH_ENABLED

#import "React/RCTConvert.h"

#if __has_include(<LoaderKit/LoaderKit-Swift.h>)
// if use_frameworks! :static
#import <LoaderKit/LoaderKit-Swift.h>
#else
#import "LoaderKit-Swift.h"
#endif

#import <react/renderer/components/LoaderKitViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/LoaderKitViewSpec/EventEmitters.h>
#import <react/renderer/components/LoaderKitViewSpec/Props.h>
#import <react/renderer/components/LoaderKitViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

@interface LoaderKitView () <RCTLoaderKitViewViewProtocol>

@end

@implementation LoaderKitView {
    NVActivityIndicatorView * _indicatorView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<LoaderKitViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const LoaderKitViewProps>();
    _props = defaultProps;

    _indicatorView = [[NVActivityIndicatorView alloc] initWithFrame:CGRectZero];
        
    self.contentView = _indicatorView;
  }

  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
    const auto &oldViewProps = *std::static_pointer_cast<LoaderKitViewProps const>(_props);
    const auto &newViewProps = *std::static_pointer_cast<LoaderKitViewProps const>(props);

    if (oldViewProps.name != newViewProps.name) {
      _indicatorView.name = [[NSString alloc] initWithUTF8String: newViewProps.name.c_str()];
    }
    
    // Update color
    if (oldViewProps.color != newViewProps.color) {
        _indicatorView.color = [RCTConvert UIColor:[NSNumber numberWithInt:newViewProps.color]];
    }
    
    if (oldViewProps.animationSpeedMultiplier != newViewProps.animationSpeedMultiplier) {
        _indicatorView.animationSpeedMultiplier = newViewProps.animationSpeedMultiplier;
    }

    [super updateProps:props oldProps:oldProps];
}

Class<RCTComponentViewProtocol> LoaderKitViewCls(void)
{
    return LoaderKitView.class;
}

@end

#else

@interface RCT_EXTERN_MODULE(LoaderKitViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(name, NSString)

RCT_REMAP_VIEW_PROPERTY(color, colorRN, NSNumber) // map from "colorRN" of native view to "color" of react prop

RCT_REMAP_VIEW_PROPERTY(animationSpeedMultiplier, animationSpeedMultiplierRN, NSNumber) // map from "animationSpeedMultiplierRN" of native view to "animationSpeedMultiplier" of react prop

@end

#endif


