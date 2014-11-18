//
//  LBXMessageBar.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXMessageBar.h"
#import "LBXEndpoints.h"
#import <TWMessageBarManager.h>
#import <UICkeyChainStore.h>

@implementation LBXMessageBar

+ (void)displayError:(NSError *)error
{
    NSString *title = @"Connection Error!";
    NSString *description = [NSString stringWithFormat:@"Could not connect to %@", [UICKeyChainStore stringForKey:@"baseURLString"]];
    if ([error.localizedDescription rangeOfString:@"NSURLErrorDomain error -999"].location == NSNotFound) {
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:title
                                                       description:description
                                                              type:TWMessageBarMessageTypeError];
    }
    else {
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Network Error!"
                                                       description:error.localizedDescription
                                                              type:TWMessageBarMessageTypeError];
    }
}

+ (void)successfulLogin
{
      [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Log In Successful"
                                                                   description:@"Logged in successfully."
                                                                          type:TWMessageBarMessageTypeSuccess];
}

+ (void)successfulLogout
{
    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Logged Out"
                                                   description:@"Successfully logged out."
                                                          type:TWMessageBarMessageTypeSuccess];
}

+ (void)incorrectCredentials
{
    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Incorrect Credentials"
                                                   description:@"Your username or password is incorrect."
                                                          type:TWMessageBarMessageTypeError];
}

+ (void)longboxedWebPageError
{
    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Can't Open Webpage"
                                                   description:@"No Longboxed page exists for this movie."
                                                          type:TWMessageBarMessageTypeError];
}

+ (void)clearedCache
{
    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Cache Successfully Cleared"
                                                   description:@"All data in memory has been removed"
                                                          type:TWMessageBarMessageTypeInfo];
}

@end
