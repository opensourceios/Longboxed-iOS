//
//  LBXAppDelegate.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DDFileLogger.h>

@interface LBXAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) DDFileLogger *fileLogger;

- (NSString *) getLogFilesContentWithMaxSize:(NSInteger)maxSize;
@end
