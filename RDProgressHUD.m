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

#import "RDProgressHUD.h"

static const CGFloat kRDDefaultFontSize = 16.0f;
static const CGFloat kRDIconSize = 37.0f;
static const CGFloat kRDMessagePadding = 10.0f;
static const CGFloat kRDBoxPadding = 16.0f;
static const CGFloat kRDBoxCornerRadius = 10.0f;


@implementation RDProgressHUD

@synthesize doneVisibleDuration;
@synthesize removeFromSuperviewWhenHidden;


-(id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if( self != nil ) {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentMode = UIViewContentModeRedraw;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.userInteractionEnabled = YES;
    
    rdActivityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    rdActivityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    rdActivityView.hidesWhenStopped = YES;
    [self addSubview:rdActivityView];
    
    rdMessage = [[UILabel alloc] initWithFrame:CGRectZero];
    rdMessage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    rdMessage.font = [UIFont boldSystemFontOfSize:kRDDefaultFontSize];
    rdMessage.textColor = [UIColor whiteColor];
    rdMessage.textAlignment = UITextAlignmentCenter;
    rdMessage.backgroundColor = [UIColor clearColor];
    rdMessage.opaque = NO;
    [self addSubview:rdMessage];
    
    rdCompleteImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kRDIconSize, kRDIconSize)];
    rdCompleteImage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    rdCompleteImage.contentMode = UIViewContentModeScaleAspectFit;
    rdCompleteImage.backgroundColor = [UIColor clearColor];
    rdCompleteImage.opaque = NO;
    [self addSubview:rdCompleteImage];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
  }
  return self;
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [rdActivityView release];
  [rdMessage release];
  [rdCompleteImage release];
  [super dealloc];
}


#pragma mark -
#pragma mark properties

- (NSString *)text {
  return rdMessage.text;
}

- (void)setText:(NSString *)text {
  rdMessage.text = text;
  [self setNeedsLayout];
  [self setNeedsDisplay];
}

- (CGFloat)fontSize {
  return rdMessage.font.pointSize;
}

- (void)setFontSize:(CGFloat)size {
  rdMessage.font = [UIFont boldSystemFontOfSize:size];
  [self setNeedsLayout];
  [self setNeedsDisplay];
}


#pragma mark -
#pragma mark private API

- (UIImage *)bundleImage:(NSString *)imageName {
  static NSString* fullPath = nil;
  if( fullPath == nil ) {
    fullPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"RDProgressHUD.bundle/images"] retain];
  }
  return [UIImage imageWithContentsOfFile:[fullPath stringByAppendingPathComponent:imageName]];
}

- (void)orientationChanged:(NSNotification *)notification {
  UIDeviceOrientation o = [UIDevice currentDevice].orientation;
  CGFloat angle = 0;
  switch( o ) {
    case UIDeviceOrientationPortraitUpsideDown:
      angle = M_PI;
      break;
    case UIDeviceOrientationLandscapeLeft:
      angle = M_PI / 2;
      break;
    case UIDeviceOrientationLandscapeRight:
      angle = -M_PI / 2;
      break;
  }
  
  self.transform = CGAffineTransformMakeRotation(angle);
  self.frame = self.superview.bounds;
  [self setNeedsLayout];
}

- (void)hideAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
  self.hidden = YES;
  
  if( self.removeFromSuperviewWhenHidden ) {
    [self removeFromSuperview];
  }
}


#pragma mark -
#pragma mark public API

-(void)showInView:(UIView *)view {
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [self orientationChanged:nil];
  
  self.hidden = NO;
  self.frame = view.bounds;
  [view addSubview:self];
  
  rdCompleteImage.hidden = YES;
  [rdActivityView startAnimating];
  
  CGAffineTransform xform = self.transform;
  self.transform = CGAffineTransformConcat(xform, CGAffineTransformMakeScale(0.5, 0.5));
  self.alpha = 0;
  
  [UIView beginAnimations:@"RDProgressHUD show" context:NULL];
  [UIView setAnimationDuration:0.3];
  self.transform = xform;
  self.alpha = 1.0;
  [UIView commitAnimations];
}

-(void)hide {
  [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
  //self.hidden = YES;
  
  [UIView beginAnimations:@"RDProgressHUD hide" context:NULL];
  [UIView setAnimationDuration:0.3];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(hideAnimationDidStop:finished:context:)];
  self.transform = CGAffineTransformConcat(self.transform, CGAffineTransformMakeScale(1.5, 1.5));
  self.alpha = 0.02;
  [UIView commitAnimations];
}

-(void)done {
  [self done:YES];
}

-(void)done:(BOOL)succeeded {
  UIImage* img = [self bundleImage:(succeeded ? @"done-good.png" : @"done-fail.png")];
  
  [rdActivityView stopAnimating];
  rdCompleteImage.image = img;
  rdCompleteImage.hidden = NO;
  
  [self performSelector:@selector(hide) withObject:nil afterDelay:self.doneVisibleDuration];
}


#pragma mark -
#pragma mark UIView

-(void)layoutSubviews {
  [super layoutSubviews];
  CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
  
  if( [rdMessage.text length] > 0 ) {
    [rdMessage sizeToFit];
    rdMessage.hidden = NO;
    rdMessage.center = CGPointMake(center.x, center.y + (rdMessage.frame.size.height+kRDMessagePadding)/2);
    
    center.y -= (rdActivityView.frame.size.height + kRDMessagePadding) / 2;
  }
  else {
    rdMessage.hidden = YES;
  }
  
  rdActivityView.center = center;
  rdCompleteImage.center = center;
}

-(void)drawRect:(CGRect)rect {
  [super drawRect:rect];
  
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextSaveGState(ctx);
  
  // calculate the bounding box for the elements
  CGRect box = rdActivityView.frame;
  if( !rdMessage.hidden ) {
    box = CGRectUnion(box, rdMessage.frame);
  }
  box = CGRectInset(box, -kRDBoxPadding, -kRDBoxPadding);
  
  CGFloat left   = CGRectGetMinX(box);
  CGFloat right  = CGRectGetMaxX(box);
  CGFloat top    = CGRectGetMinY(box);
  CGFloat bottom = CGRectGetMaxY(box);
  
  // build a rounded rect path in that box
  CGContextBeginPath(ctx);
  CGContextMoveToPoint(ctx, left, top + kRDBoxCornerRadius);
  CGContextAddArcToPoint(ctx, left, top, left + kRDBoxCornerRadius, top, kRDBoxCornerRadius);
  CGContextAddLineToPoint(ctx, right - kRDBoxCornerRadius, top);
  CGContextAddArcToPoint(ctx, right, top, right, top + kRDBoxCornerRadius, kRDBoxCornerRadius);
  CGContextAddLineToPoint(ctx, right, bottom - kRDBoxCornerRadius);
  CGContextAddArcToPoint(ctx, right, bottom, right - kRDBoxCornerRadius, bottom, kRDBoxCornerRadius);
  CGContextAddLineToPoint(ctx, left + kRDBoxCornerRadius, bottom);
  CGContextAddArcToPoint(ctx, left, bottom, left, bottom - kRDBoxCornerRadius, kRDBoxCornerRadius);
  CGContextClosePath(ctx);
  
  // fill the path 
  CGContextSetRGBFillColor(ctx, 0, 0, 0, 0.85);
  CGContextFillPath(ctx);
  
  CGContextRestoreGState(ctx);
}

@end
