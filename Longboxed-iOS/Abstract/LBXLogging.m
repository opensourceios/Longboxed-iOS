//
//  LBXLogging.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/1/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXLogging.h"
#import "DDLog.h"

#import <Crashlytics/Crashlytics.h>
#import <UICKeyChainStore.h>

@implementation LBXLogging

+ (void)beginLogging
{
    CLS_LOG(@"\nStarted logging for %@ (ID: %@)\n===========\n", [UICKeyChainStore stringForKey:@"username"], [UICKeyChainStore stringForKey:@"id"]);
    DDLogInfo(@"\nStarted logging for %@ (ID: %@)\n===========\n", [UICKeyChainStore stringForKey:@"username"], [UICKeyChainStore stringForKey:@"id"]);
}

+ (void)logLogin
{
    CLS_LOG(@"\nLogged in with username: %@ (ID: %@)\n===========\n", [UICKeyChainStore stringForKey:@"username"], [UICKeyChainStore stringForKey:@"id"]);
    DDLogInfo(@"\nLogged in with username: %@ (ID: %@)\n===========\n", [UICKeyChainStore stringForKey:@"username"], [UICKeyChainStore stringForKey:@"id"]);
}

+ (void)logLogout
{
    CLS_LOG(@"\nLogged out username: %@ (ID: %@)\n===========\n", [UICKeyChainStore stringForKey:@"username"], [UICKeyChainStore stringForKey:@"id"]);
    DDLogInfo(@"\nLogged out username: %@ (ID: %@)\n===========\n", [UICKeyChainStore stringForKey:@"username"], [UICKeyChainStore stringForKey:@"id"]);
}

+ (void)logMessage:(NSString *)message
{
    CLS_LOG(@"\n%@\n(Username: %@, User ID: %@)\n===========\n", message, [UICKeyChainStore stringForKey:@"username"], [UICKeyChainStore stringForKey:@"id"]);
    DDLogInfo(@"\n%@\n(Username: %@, User ID: %@)\n===========\n", message, [UICKeyChainStore stringForKey:@"username"], [UICKeyChainStore stringForKey:@"id"]);
}

@end
