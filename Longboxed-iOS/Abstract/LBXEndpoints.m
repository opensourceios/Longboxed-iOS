//
//  LBXEndpoints.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXEndpoints.h"

@implementation LBXEndpoints

NSString *stagingURL = @"https://dev.longboxed.com";
NSString *productionURL = @"https://longboxed.com";
NSString *versionAPI = @"v1";

+ (NSURL *)stagingURL
{
    return [NSURL URLWithString:stagingURL];
}

+ (NSURL *)productionURL
{
    return [NSURL URLWithString:productionURL];
}

+ (NSString *)baseURLString
{
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.longboxed.Longboxed-iOSDebug"]) {
        return stagingURL;
    }
    else {
        return productionURL;
    }
}

+ (NSDictionary *)endpoints
{
  return  @{@"Issues Collection"                  : [NSString stringWithFormat:@"/api/%@/issues/", versionAPI],
            @"Issues Collection for Current Week" : [NSString stringWithFormat:@"/api/%@/issues/thisweek/", versionAPI],
            @"Issues Collection for Next Week"    : [NSString stringWithFormat:@"/api/%@/issues/nextweek/", versionAPI],
            @"Popular Issues for Current Week"    : [NSString stringWithFormat:@"/api/%@/issues/popular/", versionAPI],
            @"Issue"                              : [NSString stringWithFormat:@"/api/%@/issues/:issueID", versionAPI],
            @"Titles Collection"                  : [NSString stringWithFormat:@"/api/%@/titles/", versionAPI],
            @"Title"                              : [NSString stringWithFormat:@"/api/%@/titles/:titleID", versionAPI],
            @"Issues for Title"                   : [NSString stringWithFormat:@"/api/%@/titles/:titleID/issues/", versionAPI],
            @"Autocomplete for Title"             : [NSString stringWithFormat:@"/api/%@/titles/autocomplete/", versionAPI],
            @"Publisher Collection"               : [NSString stringWithFormat:@"/api/%@/publishers/", versionAPI],
            @"Publisher"                          : [NSString stringWithFormat:@"/api/%@/publishers/:publisherID", versionAPI],
            @"Titles for Publisher"               : [NSString stringWithFormat:@"/api/%@/publishers/:publisherID/titles/", versionAPI],
            @"Register"                           : [NSString stringWithFormat:@"/api/%@/users/register", versionAPI],
            @"Delete Account"                     : [NSString stringWithFormat:@"/api/%@/users/delete", versionAPI],
            @"Login"                              : [NSString stringWithFormat:@"/api/%@/users/login", versionAPI],
            @"User Pull List"                     : [NSString stringWithFormat:@"/api/%@/users/:userID/pull_list/", versionAPI],
            @"Add Title to Pull List"             : [NSString stringWithFormat:@"/api/%@/users/:userID/pull_list/", versionAPI],
            @"Remove Title from Pull List"        : [NSString stringWithFormat:@"/api/%@/users/:userID/pull_list/:titleID", versionAPI],
            @"Bundle Resources for User"          : [NSString stringWithFormat:@"/api/%@/users/:userID/bundles/", versionAPI],
            @"Latest Bundle"                      : [NSString stringWithFormat:@"/api/%@/users/:userID/bundles/latest", versionAPI]
            };
}

@end
