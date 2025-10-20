#import "LoaderKitView.h"
#import "NVActivityIndicatorView.h"
#import "React/RCTConvert.h"

static const NSDictionary *nameToTypeMap = @{
    @"BallPulse": @(NVActivityIndicatorTypeBallPulse),
    @"BallGridPulse": @(NVActivityIndicatorTypeBallGridPulse),
    @"BallClipRotate": @(NVActivityIndicatorTypeBallClipRotate),
    @"SquareSpin": @(NVActivityIndicatorTypeSquareSpin),
    @"BallClipRotatePulse": @(NVActivityIndicatorTypeBallClipRotatePulse),
    @"BallClipRotateMultiple": @(NVActivityIndicatorTypeBallClipRotateMultiple),
    @"BallPulseRise": @(NVActivityIndicatorTypeBallPulseRise),
    @"BallRotate": @(NVActivityIndicatorTypeBallRotate),
    @"CubeTransition": @(NVActivityIndicatorTypeCubeTransition),
    @"BallZigZag": @(NVActivityIndicatorTypeBallZigZag),
    @"BallZigZagDeflect": @(NVActivityIndicatorTypeBallZigZagDeflect),
    @"BallTrianglePath": @(NVActivityIndicatorTypeBallTrianglePath),
    @"BallScale": @(NVActivityIndicatorTypeBallScale),
    @"LineScale": @(NVActivityIndicatorTypeLineScale),
    @"LineScaleParty": @(NVActivityIndicatorTypeLineScaleParty),
    @"BallScaleMultiple": @(NVActivityIndicatorTypeBallScaleMultiple),
    @"BallPulseSync": @(NVActivityIndicatorTypeBallPulseSync),
    @"BallBeat": @(NVActivityIndicatorTypeBallBeat),
    @"LineScalePulseOut": @(NVActivityIndicatorTypeLineScalePulseOut),
    @"LineScalePulseOutRapid": @(NVActivityIndicatorTypeLineScalePulseOutRapid),
    @"BallScaleRipple": @(NVActivityIndicatorTypeBallScaleRipple),
    @"BallScaleRippleMultiple": @(NVActivityIndicatorTypeBallScaleRippleMultiple),
    @"BallSpinFadeLoader": @(NVActivityIndicatorTypeBallSpinFadeLoader),
    @"LineSpinFadeLoader": @(NVActivityIndicatorTypeLineSpinFadeLoader),
    @"TriangleSkewSpin": @(NVActivityIndicatorTypeTriangleSkewSpin),
    @"Pacman": @(NVActivityIndicatorTypePacman),
    @"BallGridBeat": @(NVActivityIndicatorTypeBallGridBeat),
    @"SemiCircleSpin": @(NVActivityIndicatorTypeSemiCircleSpin),
    @"BallRotateChase": @(NVActivityIndicatorTypeBallRotateChase),
    @"Orbit": @(NVActivityIndicatorTypeOrbit),
    @"AudioEqualizer": @(NVActivityIndicatorTypeAudioEqualizer),
    @"CircleStrokeSpin": @(NVActivityIndicatorTypeCircleStrokeSpin),
    @"BallDoubleBounce": @(NVActivityIndicatorTypeBallDoubleBounce)
};

#ifdef RCT_NEW_ARCH_ENABLED

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

    _indicatorView = [[NVActivityIndicatorView alloc] init];
    
    self.contentView = _indicatorView;
  }

  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
    const auto &oldViewProps = *std::static_pointer_cast<LoaderKitViewProps const>(_props);
    const auto &newViewProps = *std::static_pointer_cast<LoaderKitViewProps const>(props);

    if (oldViewProps.name != newViewProps.name) {
        NSString * indicatorName = [[NSString alloc] initWithUTF8String: newViewProps.name.c_str()];
        NVActivityIndicatorType type = [self getIndicatorTypeFromName:indicatorName];
        _indicatorView.type = type;
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

- (NVActivityIndicatorType)getIndicatorTypeFromName:(NSString *)name
{
    if (!name) return NVActivityIndicatorTypeBallPulse;
        
    NSNumber *typeNumber = nameToTypeMap[name];
    if (typeNumber) {
        return (NVActivityIndicatorType)[typeNumber integerValue];
    }
    
    return NVActivityIndicatorTypeBallPulse; // Default fallback
}

@end

#else

@implementation LoaderKitViewManager

RCT_EXPORT_MODULE(LoaderKitView)

- (UIView *)view
{
  return [[NVActivityIndicatorView alloc] init];
}

- (NVActivityIndicatorType)getIndicatorTypeFromName:(NSString *)name
{
    if (!name) return NVActivityIndicatorTypeBallPulse;
    
    NSNumber *typeNumber = nameToTypeMap[name];
    if (typeNumber) {
        return (NVActivityIndicatorType)[typeNumber integerValue];
    }
    
    return NVActivityIndicatorTypeBallPulse;
}

RCT_CUSTOM_VIEW_PROPERTY(name, NSString, NVActivityIndicatorView)
{
    NSString *indicatorName = [RCTConvert NSString:json];
    if (indicatorName) {
        NVActivityIndicatorType type = [self getIndicatorTypeFromName:indicatorName];
        view.type = type;
    }
}

RCT_CUSTOM_VIEW_PROPERTY(color, UIColor, NVActivityIndicatorView)
{
    UIColor *color = [RCTConvert UIColor:json];
    if (color) {
        view.color = color;
    }
}

RCT_CUSTOM_VIEW_PROPERTY(animationSpeedMultiplier, CGFloat, NVActivityIndicatorView)
{
    CGFloat speedMultiplier = [RCTConvert CGFloat:json];
    view.animationSpeedMultiplier = speedMultiplier;
}

@end

#endif


