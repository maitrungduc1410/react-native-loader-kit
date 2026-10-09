#import "LoaderKitComponentView.h"

#import <React/RCTConversions.h>

#import <react/renderer/components/LoaderKitViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/LoaderKitViewSpec/Props.h>
#import <react/renderer/components/LoaderKitViewSpec/RCTComponentViewHelpers.h>

#if __has_include(<LoaderKit/LoaderKit-Swift.h>)
#import <LoaderKit/LoaderKit-Swift.h>
#else
#import "LoaderKit-Swift.h"
#endif

using namespace facebook::react;

static const std::shared_ptr<const LoaderKitViewProps> &LoaderKitDefaultProps()
{
  static const auto defaultProps = std::make_shared<const LoaderKitViewProps>();
  return defaultProps;
}

static NSString *LoaderKitString(const std::string &value)
{
  return RCTNSStringFromString(value) ?: @"";
}

static LoaderKitReduceMotion LoaderKitReduceMotionFromProp(LoaderKitViewReduceMotion value)
{
  switch (value) {
    case LoaderKitViewReduceMotion::Never:
      return LoaderKitReduceMotionNever;
    case LoaderKitViewReduceMotion::Always:
      return LoaderKitReduceMotionAlways;
    case LoaderKitViewReduceMotion::System:
      return LoaderKitReduceMotionSystem;
  }
  return LoaderKitReduceMotionSystem;
}

@interface LoaderKitComponentView () <RCTLoaderKitViewViewProtocol>
@end

@implementation LoaderKitComponentView {
  LoaderKitContentView *_loaderView;
  // The props pushed to _loaderView. `_props` cannot serve as the baseline: it survives recycling,
  // while _loaderView is reset.
  std::shared_ptr<const LoaderKitViewProps> _appliedProps;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<LoaderKitViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _props = LoaderKitDefaultProps();
    _appliedProps = LoaderKitDefaultProps();
    _loaderView = [[LoaderKitContentView alloc] initWithFrame:CGRectZero];
    self.contentView = _loaderView;
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *_appliedProps;
  const auto newProps = std::static_pointer_cast<const LoaderKitViewProps>(props);
  const auto &newViewProps = *newProps;

  BOOL sourceChanged = NO;
  if (oldViewProps.name != newViewProps.name) {
    _loaderView.name = LoaderKitString(newViewProps.name);
    sourceChanged = YES;
  }
  if (oldViewProps.specJson != newViewProps.specJson) {
    _loaderView.specJSON = LoaderKitString(newViewProps.specJson);
    sourceChanged = YES;
  }
  if (oldViewProps.paramsJson != newViewProps.paramsJson) {
    _loaderView.paramsJSON = LoaderKitString(newViewProps.paramsJson);
    sourceChanged = YES;
#if DEBUG
    if (_loaderView.paramsErrorMessage != nil) {
      NSLog(@"LoaderKitView: %@", _loaderView.paramsErrorMessage);
    }
#endif
  }
  if (oldViewProps.color != newViewProps.color) {
    _loaderView.color = RCTUIColorFromSharedColor(newViewProps.color);
  }
  if (oldViewProps.colors != newViewProps.colors) {
    NSMutableArray<UIColor *> *colors = [NSMutableArray arrayWithCapacity:newViewProps.colors.size()];
    for (const auto &color : newViewProps.colors) {
      [colors addObject:RCTUIColorFromSharedColor(color) ?: UIColor.whiteColor];
    }
    _loaderView.colors = colors;
  }
  if (oldViewProps.speed != newViewProps.speed) {
    _loaderView.speed = newViewProps.speed;
  }
  if (oldViewProps.animating != newViewProps.animating) {
    _loaderView.animating = newViewProps.animating;
  }
  if (oldViewProps.hidesWhenStopped != newViewProps.hidesWhenStopped) {
    _loaderView.hidesWhenStopped = newViewProps.hidesWhenStopped;
  }
  if (oldViewProps.cycleProgress != newViewProps.cycleProgress) {
    _loaderView.cycleProgress = newViewProps.cycleProgress;
  }
  if (oldViewProps.reduceMotion != newViewProps.reduceMotion) {
    _loaderView.reduceMotion = LoaderKitReduceMotionFromProp(newViewProps.reduceMotion);
  }

#if DEBUG
  if (sourceChanged && _loaderView.specErrorMessage != nil) {
    NSLog(@"LoaderKitView: nothing is drawn. %@", _loaderView.specErrorMessage);
  }
#endif

  _appliedProps = newProps;
  [super updateProps:props oldProps:oldProps];
}

- (void)prepareForRecycle
{
  [super prepareForRecycle];
  [_loaderView reset];
  _appliedProps = LoaderKitDefaultProps();
}

@end

Class<RCTComponentViewProtocol> LoaderKitViewCls(void)
{
  return LoaderKitComponentView.class;
}
