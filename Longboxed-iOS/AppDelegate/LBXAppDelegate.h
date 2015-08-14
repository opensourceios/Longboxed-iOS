//
//  LBXAppDelegate.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DDFileLogger.h>

#import "OnboardingViewController.h"

@interface LBXAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) DDFileLogger *fileLogger;

- (NSString *) getLogFilesContentWithMaxSize:(NSInteger)maxSize;
- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible;
- (void)setAPIErrorMessageVisible:(BOOL)setVisible withError:(NSError *)error;

- (OnboardingViewController *)generateOnboardingVC;
- (void)externallySetRootViewController:(id)viewController;
- (void)handleOnboardingCompletion;

@end
