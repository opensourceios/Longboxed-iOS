//
//  LBXLogging.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/1/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBXLogging : NSObject

+ (void)beginLogging;
+ (void)logLogin;
+ (void)logLogout;
+ (void)logMessage:(NSString *)message;

@end
