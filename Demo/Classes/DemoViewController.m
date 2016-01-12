//
//  DemoViewController.m
//  Demo
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

#import "DemoViewController.h"
#import "RDProgressHUD.h"


@implementation DemoViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}


- (void)showSuccessWithHud:(RDProgressHUD *)hud {
  if( hud.text ) hud.text = @"Worked";
  [hud done];
}

- (void)showFailureWithHud:(RDProgressHUD *)hud {
  if( hud.text ) hud.text = @"Failed";
  [hud done:NO];
}

- (void)displayHUDWithMessage:(BOOL)withMessage willComplete:(BOOL)willComplete willSucceed:(BOOL)willSucceed {
  RDProgressHUD* hud = [[RDProgressHUD alloc] initWithFrame:CGRectZero];
  hud.doneVisibleDuration = 0.5;
  hud.removeFromSuperviewWhenHidden = YES;
  hud.text = withMessage ? @"Working..." : nil;
  [hud showInView:[self.view window]];
  
  if( !willComplete ) {
    [hud performSelector:@selector(hide) withObject:nil afterDelay:3.0];
  }
  else if( willSucceed ) {
    [self performSelector:@selector(showSuccessWithHud:) withObject:hud afterDelay:3.0];
  }
  else {
    [self performSelector:@selector(showFailureWithHud:) withObject:hud afterDelay:3.0];
  }
}

- (IBAction)displayHUDWithProgressOnly {
  [self displayHUDWithMessage:NO
                 willComplete:NO
                  willSucceed:NO];
}

- (IBAction)displayHUDWithProgressOnlyWillSucceed {
  [self displayHUDWithMessage:NO
                 willComplete:YES
                  willSucceed:YES];
}

- (IBAction)displayHUDWithProgressOnlyWillFail {
  [self displayHUDWithMessage:NO
                 willComplete:YES
                  willSucceed:NO];
}

- (IBAction)displayHUDWithProgressAndMessage {
  [self displayHUDWithMessage:YES
                 willComplete:NO
                  willSucceed:NO];
}

- (IBAction)displayHUDWithProgressAndMessageWillSucceed {
  [self displayHUDWithMessage:YES
                 willComplete:YES
                  willSucceed:YES];
}

- (IBAction)displayHUDWithProgressAndMessageWillFail {
  [self displayHUDWithMessage:YES
                 willComplete:YES
                  willSucceed:NO];
}


@end
