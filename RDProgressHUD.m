//
//  RDProgressHUD.m
//  RDProgressHUD
//
//  Created by Sixten Otto on 10/22/10.
//  Copyright 2010 Results Direct. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//  * Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//  * Neither the name of Results Direct nor the names of its
//    contributors may be used to endorse or promote products derived
//    from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
//  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
//  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
//  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <QuartzCore/QuartzCore.h>

#import "RDProgressHUD.h"

static const NSTimeInterval kRDAnimationDuration = 0.3;
static const NSTimeInterval kRDProgressAnimationDuration = 0.2;
static const CGFloat kRDDefaultFontSize = 16.0f;
static const CGFloat kRDIconSize = 37.0f;
static const CGFloat kRDMessagePadding = 10.0f;
static const CGFloat kRDBoxPadding = 16.0f;
static const CGFloat kRDBoxCornerRadius = 10.0f;
static const CGFloat kRDLineWidth = 2.0f;
static NSString *const kRDActivityAnimationKey = @"spinning";


@interface RDProgressActivityView : UIView

@property (assign, nonatomic, getter=isAnimating) BOOL animating;

- (void)startAnimating;
- (void)stopAnimating;

@end

@interface RDProgressView : UIView

@property (assign, nonatomic) float progress;

@end

@interface RDProgressBackgroundLayer : CALayer

@property (assign, nonatomic) float progress;

@end


#pragma mark -
@interface RDProgressHUD ()

@property (nonatomic, weak)   UIView *backgroundView;
@property (nonatomic, weak)   RDProgressActivityView *activityView;
@property (nonatomic, weak)   UILabel *messageLabel;
@property (nonatomic, weak)   RDProgressView *progressView;
@property (nonatomic, weak)   UIImageView *completionImageView;
@property (nonatomic, strong) NSTimer *graceTimer;

@end


@implementation RDProgressHUD

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if( self != nil ) {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //self.contentMode = UIViewContentModeRedraw;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.userInteractionEnabled = YES;
    self.positionInFrame = CGPointMake(0.5f, 0.5f);
    
    UIView* bgLayer = [[UIView alloc] initWithFrame:CGRectZero];
    bgLayer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.85f];
    bgLayer.layer.cornerRadius = kRDBoxCornerRadius;
    [self addSubview:bgLayer];
    self.backgroundView = bgLayer;
    
    RDProgressActivityView* indicator = [[RDProgressActivityView alloc] init];
    indicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:indicator];
    self.activityView = indicator;
    
    RDProgressView *progress = [[RDProgressView alloc] initWithFrame:[indicator frame]];
    [self addSubview:progress];
    self.progressView = progress;
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    label.font = [UIFont boldSystemFontOfSize:kRDDefaultFontSize];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = NO;
    [self addSubview:label];
    self.messageLabel = label;
    
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kRDIconSize, kRDIconSize)];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = [UIColor clearColor];
    imageView.opaque = NO;
    [self addSubview:imageView];
    self.completionImageView = imageView;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
  }
  return self;
}

- (void)dealloc
{
  [_graceTimer invalidate];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}


#pragma mark properties

- (NSString *)text {
  return self.messageLabel.text;
}

- (void)setText:(NSString *)text {
  self.messageLabel.text = text;
  [self setNeedsLayout];
}

- (CGFloat)fontSize {
  return self.messageLabel.font.pointSize;
}

- (void)setFontSize:(CGFloat)size {
  self.messageLabel.font = [UIFont boldSystemFontOfSize:size];
  [self setNeedsLayout];
}


#pragma mark private API

- (UIImage *)bundleImage:(NSString *)imageName {
  static NSString* fullPath = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    fullPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"RDProgressHUD.bundle"] stringByAppendingPathComponent:@"images"];
  });
  return [UIImage imageWithContentsOfFile:[fullPath stringByAppendingPathComponent:imageName]];
}

- (void)orientationChanged:(NSNotification *)notification {
  if( ![self.superview isKindOfClass:[UIWindow class]] ) {
    return;
  }
  
  UIDeviceOrientation o = [UIDevice currentDevice].orientation;
  CGFloat angle = 0;
  switch( o ) {
    case UIDeviceOrientationPortraitUpsideDown:
      angle = (CGFloat)M_PI;
      break;
    case UIDeviceOrientationLandscapeLeft:
      angle = (CGFloat)(M_PI / 2);
      break;
    case UIDeviceOrientationLandscapeRight:
      angle = (CGFloat)(-M_PI / 2);
      break;
    default:break;
  }
  
  self.transform = CGAffineTransformMakeRotation(angle);
  self.frame = self.superview.bounds;
  [self setNeedsLayout];
}


#pragma mark public API

- (void)showWithCurrentFrameInView:(UIView *)view
{
  [self.graceTimer invalidate];
  
  if( [view isKindOfClass:[UIWindow class]] ) {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [self orientationChanged:nil];
  }
  else {
    self.transform = CGAffineTransformIdentity;
  }
  
  self.hidden = NO;
  if( self.superview != view ) {
    [view addSubview:self];
  }
  
  self.progressView.hidden = YES;
  self.completionImageView.hidden = YES;
  [self.activityView startAnimating];
  
  CGAffineTransform xform = self.transform;
  self.transform = CGAffineTransformConcat(xform, CGAffineTransformMakeScale(0.5, 0.5));
  self.alpha = 0;
  
  [UIView animateWithDuration:kRDAnimationDuration animations:^{
    self.transform = xform;
    self.alpha = 1.0;
  }];
}

- (void)showInView:(UIView *)view
{
  self.frame = view.bounds;
  [self showWithCurrentFrameInView:view];
}

- (void)showInView:(UIView *)view afterDelay:(NSTimeInterval)delay
{
  if( 0 < delay ) {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(showInView:)]];
    [invocation setSelector:@selector(showInView:)];
    [invocation setTarget:self];
    [invocation setArgument:&view atIndex:2];
    self.graceTimer = [NSTimer scheduledTimerWithTimeInterval:delay invocation:invocation repeats:NO];
  }
  else {
    [self showInView:view];
  }
}

- (void)setProgressValue:(float)progress
{
  self.progressView.progress = progress;
  if( 0.f <= progress ) {
    self.progressView.hidden = NO;
    [self.activityView stopAnimating];
  }
  else {
    self.progressView.hidden = YES;
    if( !self.isHidden ) {
      [self.activityView startAnimating];
    }
  }
}

- (void)hide
{
  [self.graceTimer invalidate];
  
  if( [self.superview isKindOfClass:[UIWindow class]] ) {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
  }
  
  CGAffineTransform originalTransform = self.transform;
  CGAffineTransform expandedTransform = CGAffineTransformConcat(originalTransform, CGAffineTransformMakeScale(1.5, 1.5));
  [UIView animateWithDuration:kRDAnimationDuration animations:^{
    self.transform = expandedTransform;
    self.alpha = 0.02f;
  } completion:^(BOOL finished) {
    self.hidden = YES;
    self.transform = originalTransform;
    if( self.removeFromSuperviewWhenHidden ) {
      [self removeFromSuperview];
    }
  }];
}

- (void)done
{
  [self done:YES];
}

- (void)done:(BOOL)succeeded
{
  UIImage* img = [self bundleImage:(succeeded ? @"done-good.png" : @"done-fail.png")];
  
  self.progressView.hidden = YES;
  [self.activityView stopAnimating];
  self.completionImageView.image = img;
  self.completionImageView.hidden = NO;
  
  self.graceTimer = [NSTimer scheduledTimerWithTimeInterval:self.doneVisibleDuration target:self selector:@selector(hide) userInfo:nil repeats:NO];
}


#pragma mark UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  CGPoint center = CGPointMake(truncf(self.bounds.size.width * self.positionInFrame.x), truncf(self.bounds.size.height * self.positionInFrame.y));
  
  if( [self.messageLabel.text length] > 0 ) {
    CGRect frame = self.messageLabel.frame;
    frame.size = [self.messageLabel sizeThatFits:frame.size];
    frame.size.width  = ceilf(frame.size.width)  + ((long)ceilf(frame.size.width)  % 2);
    frame.size.height = ceilf(frame.size.height) + ((long)ceilf(frame.size.height) % 2);
    frame.origin = CGPointMake(center.x - frame.size.width/2, center.y + kRDMessagePadding/2);
    
    self.messageLabel.frame = frame;
    self.messageLabel.hidden = NO;
    
    center.y -= ceilf((self.activityView.frame.size.height + kRDMessagePadding) / 2);
  }
  else {
    self.messageLabel.hidden = YES;
  }
  
  center = CGPointMake(center.x+0.5f, center.y+0.5f);
  self.activityView.center = center;
  self.progressView.center = center;
  self.completionImageView.center = center;
  
  // calculate the bounding box for the elements, and re-size the background
  CGRect box = self.activityView.frame;
  if( !self.messageLabel.hidden ) {
    box = CGRectUnion(box, self.messageLabel.frame);
  }
  box = CGRectIntegral(CGRectInset(box, -kRDBoxPadding, -kRDBoxPadding));
  self.backgroundView.frame = box;
}

@end


#pragma mark -
@implementation RDProgressActivityView

+ (Class)layerClass {
  return [CAShapeLayer class];
}

- (instancetype)init {
  self = [super initWithFrame:CGRectMake(0, 0, kRDIconSize, kRDIconSize)];
  if( nil != self ) {
    CAShapeLayer *shapeLayer = (CAShapeLayer *)self.layer;
    shapeLayer.strokeColor = UIColor.whiteColor.CGColor;
    shapeLayer.fillColor = nil;
    shapeLayer.lineWidth = kRDLineWidth;
    shapeLayer.lineCap = kCALineCapRound;
    
    CGPoint center = CGPointMake(kRDIconSize/2.f, kRDIconSize/2.f);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:(center.y - 1.f) startAngle:(2 * M_PI / 6) endAngle:(2 * M_PI) clockwise:YES];
    shapeLayer.path = path.CGPath;
  }
  return self;
}

- (void)startAnimating {
  self.animating = YES;
  [self updateIndicator];
}

- (void)stopAnimating {
  self.animating = NO;
  [self updateIndicator];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
  [super willMoveToWindow:newWindow];
  self.layer.contentsScale = newWindow.screen.scale ?: 1.f;
}

- (void)didMoveToWindow {
  [super didMoveToWindow];
  [self updateIndicator];
}

- (void)updateIndicator {
  // update visibility
  if( self.isAnimating ) {
    self.alpha = 1.f;
  }
  else {
    self.alpha = 0.f;
  }
  
  // update animation
  if( self.isAnimating && nil != self.window ) {
    if( nil == [self.layer animationForKey:kRDActivityAnimationKey] ) {
      CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
      animation.duration = 1.5;
      animation.toValue = [NSNumber numberWithDouble:(2 * M_PI)];
      animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
      animation.repeatCount = INFINITY;
      [self.layer addAnimation:animation forKey:kRDActivityAnimationKey];
    }
  }
  else {
    [self.layer removeAnimationForKey:kRDActivityAnimationKey];
  }
}

@end


#pragma mark -
@implementation RDProgressView

+ (Class)layerClass {
  return [RDProgressBackgroundLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.opaque = NO;
  }
  return self;
}

- (void)setProgress:(float)progress
{
  _progress = progress;
  [self updateProgressAnimated:YES];
}

- (void)updateProgressAnimated:(BOOL)animated {
  [CATransaction begin];
  [CATransaction setDisableActions:!animated];
  [(RDProgressBackgroundLayer *)self.layer setProgress:self.progress];
  [CATransaction commit];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
  [super willMoveToWindow:newWindow];
  self.layer.contentsScale = newWindow.screen.scale ?: 1.f;
}

@end


@implementation RDProgressBackgroundLayer

@dynamic progress;

- (instancetype)init
{
  self = [super init];
  if (self) {
  }
  return self;
}

- (instancetype)initWithLayer:(id)layer {
  self = [super initWithLayer:layer];
  if( nil != self ) {
    if( [layer isKindOfClass:[RDProgressBackgroundLayer class]] ) {
      self.progress = [(RDProgressBackgroundLayer *)layer progress];
    }
  }
  return self;
}

+ (BOOL)needsDisplayForKey:(NSString *)key {
  if( [@"progress" isEqual:key] ) {
    return YES;
  }
  return [super needsDisplayForKey:key];
}

- (id<CAAction>)actionForKey:(NSString *)event {
  if( [@"progress" isEqual:event] ) {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:event];
    animation.duration = kRDProgressAnimationDuration;
    animation.fromValue = [self.presentationLayer valueForKey:event] ?: [self valueForKey:event];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    return animation;
  }
  return [super actionForKey:event];
}

- (void)drawInContext:(CGContextRef)ctx {
  CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidX(self.bounds));
  CGFloat radius = center.y;
  
  // outer edge
  CGContextBeginPath(ctx);
  CGContextAddArc(ctx, center.x, center.y, radius, 0.f, (2 * M_PI), 1.f);
  CGContextClosePath(ctx);
  
  if( self.progress <= 0.99 ) {
    // punch a hole in the center of the disc for incomplete progress
    CGContextAddArc(ctx, center.x, center.y, radius-kRDLineWidth, 0.f, (2 * M_PI), 0.f);
    CGContextClosePath(ctx);
    
    // completed wedge
    CGFloat startAngle = -M_PI_2; // 12 o'clock
    CGFloat endAngle = startAngle + M_PI * 2 * self.progress;
    CGContextMoveToPoint(ctx, center.x, center.y);
    CGContextAddArc(ctx, center.x, center.y, radius-1, endAngle, startAngle, 1);
    CGContextClosePath(ctx);
  }
  
  // fill the whole thing in
  CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
  CGContextFillPath(ctx);
}

@end
