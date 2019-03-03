/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "Application.h"

#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <React/RCTWindow.h>

@implementation Application
{
  RCTBridge *_bridge;
  RCTWindow *_window;
}

- (instancetype)init
{
  if (self = [super init]) {
    self.delegate = self;
  }
  return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  NSURL *sourceURL = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.macos"
                                                                    fallbackResource:nil];

  _bridge = [[RCTBridge alloc] initWithBundleURL:sourceURL
                                  moduleProvider:nil
                                   launchOptions:nil];

  _window = [[RCTWindow alloc] initWithBridge:_bridge
                                  contentRect:NSMakeRect(200, 500, 1000, 500)
                                    styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskClosable)
                                        defer:NO];

  _window.contentView = [[RCTRootView alloc] initWithBridge:_bridge
                                                 moduleName:@"RNSVGKitExample"
                                          initialProperties:nil];

  [_window makeKeyAndOrderFront:nil];
}

@end
