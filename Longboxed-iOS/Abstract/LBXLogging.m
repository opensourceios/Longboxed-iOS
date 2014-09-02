//
//  LBXLogging.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/1/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXLogging.h"
#import "DDLog.h"

#import <UICKeyChainStore.h>

@implementation LBXLogging

+ (void)beginLogging
{
    DDLogInfo(@"\nStarted logging for %@ (ID: %@)\n===========\n", [UICKeyChainStore stringForKey:@"username"], [UICKeyChainStore stringForKey:@"id"]);
}

+ (void)logLogin
{
    DDLogInfo(@"\nLogged in with username: %@ (ID: %@)\n===========\n", [UICKeyChainStore stringForKey:@"username"], [UICKeyChainStore stringForKey:@"id"]);
}

+ (void)logLogout
{
    DDLogInfo(@"\nLogged out username: %@ (ID: %@)\n===========\n", [UICKeyChainStore stringForKey:@"username"], [UICKeyChainStore stringForKey:@"id"]);
}

+ (void)logMessage:(NSString *)message
{
    DDLogInfo(@"\n%@\n(Username: %@, User ID: %@)\n===========\n", message, [UICKeyChainStore stringForKey:@"username"], [UICKeyChainStore stringForKey:@"id"]);
}

@end
