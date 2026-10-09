#import "LoaderKitProgressComponentView.h"

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

static const std::shared_ptr<const LoaderKitProgressViewProps> &LoaderKitProgressDefaultProps()
{
  static const auto defaultProps = std::make_shared<const LoaderKitProgressViewProps>();
  return defaultProps;
}

static NSString *LoaderKitProgressString(const std::string &value)
{
  return RCTNSStringFromString(value) ?: @"";
}

@interface LoaderKitProgressComponentView () <RCTLoaderKitProgressViewViewProtocol>
@end

@implementation LoaderKitProgressComponentView {
  LoaderKitProgressContentView *_progressView;
  // The props pushed to _progressView. `_props` cannot serve as the baseline: it survives
  // recycling, while _progressView is reset.
  std::shared_ptr<const LoaderKitProgressViewProps> _appliedProps;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<LoaderKitProgressViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _props = LoaderKitProgressDefaultProps();
    _appliedProps = LoaderKitProgressDefaultProps();
    _progressView = [[LoaderKitProgressContentView alloc] initWithFrame:CGRectZero];
    self.contentView = _progressView;
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *_appliedProps;
  const auto newProps = std::static_pointer_cast<const LoaderKitProgressViewProps>(props);
  const auto &newViewProps = *newProps;

  // Options and smooth first, so a new value is drawn and glided with them.
  if (oldViewProps.smooth != newViewProps.smooth) {
    _progressView.smooth = newViewProps.smooth;
  }
  if (oldViewProps.type != newViewProps.type) {
    _progressView.type = LoaderKitProgressString(newViewProps.type);
  }
  if (oldViewProps.variant != newViewProps.variant) {
    _progressView.variant = LoaderKitProgressString(newViewProps.variant);
  }
  if (oldViewProps.thickness != newViewProps.thickness) {
    _progressView.thickness = newViewProps.thickness;
  }
  if (oldViewProps.trackGap != newViewProps.trackGap) {
    _progressView.trackGap = newViewProps.trackGap;
  }
  if (oldViewProps.segments != newViewProps.segments) {
    _progressView.segments = newViewProps.segments;
  }
  if (oldViewProps.showLabel != newViewProps.showLabel) {
    _progressView.showLabel = newViewProps.showLabel;
  }
  if (oldViewProps.stopIndicator != newViewProps.stopIndicator) {
    _progressView.stopIndicator = newViewProps.stopIndicator;
  }
  if (oldViewProps.strokeCap != newViewProps.strokeCap) {
    _progressView.strokeCap = LoaderKitProgressString(newViewProps.strokeCap);
  }
  if (oldViewProps.amplitude != newViewProps.amplitude) {
    _progressView.amplitude = newViewProps.amplitude;
  }
  if (oldViewProps.wavelength != newViewProps.wavelength) {
    _progressView.wavelength = newViewProps.wavelength;
  }
  if (oldViewProps.waveSpeed != newViewProps.waveSpeed) {
    _progressView.waveSpeed = newViewProps.waveSpeed;
  }
  if (oldViewProps.sweepAngle != newViewProps.sweepAngle) {
    _progressView.sweepAngle = newViewProps.sweepAngle;
  }
  if (oldViewProps.cornerRadius != newViewProps.cornerRadius) {
    _progressView.cornerRadius = newViewProps.cornerRadius;
  }
  if (oldViewProps.speed != newViewProps.speed) {
    _progressView.speed = newViewProps.speed;
  }
  if (oldViewProps.color != newViewProps.color) {
    _progressView.color = RCTUIColorFromSharedColor(newViewProps.color);
  }
  if (oldViewProps.trackColor != newViewProps.trackColor) {
    _progressView.trackColor = RCTUIColorFromSharedColor(newViewProps.trackColor);
  }
  if (oldViewProps.labelColor != newViewProps.labelColor) {
    _progressView.labelColor = RCTUIColorFromSharedColor(newViewProps.labelColor);
  }
  if (oldViewProps.reduceMotion != newViewProps.reduceMotion) {
    _progressView.respectsReduceMotion = newViewProps.reduceMotion == LoaderKitProgressViewReduceMotion::System;
  }
  if (oldViewProps.progressAccessibilityLabel != newViewProps.progressAccessibilityLabel) {
    _progressView.progressAccessibilityLabel = LoaderKitProgressString(newViewProps.progressAccessibilityLabel);
  }
  if (oldViewProps.buffer != newViewProps.buffer) {
    _progressView.buffer = newViewProps.buffer;
  }
  if (oldViewProps.value != newViewProps.value) {
    _progressView.value = newViewProps.value;
  }

  _appliedProps = newProps;
  [super updateProps:props oldProps:oldProps];
}

- (void)prepareForRecycle
{
  [super prepareForRecycle];
  [_progressView reset];
  _appliedProps = LoaderKitProgressDefaultProps();
}

@end

Class<RCTComponentViewProtocol> LoaderKitProgressViewCls(void)
{
  return LoaderKitProgressComponentView.class;
}
