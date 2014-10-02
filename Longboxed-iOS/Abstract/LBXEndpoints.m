//
//  LBXEndpoints.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXEndpoints.h"

@implementation LBXEndpoints

NSString *stagingURL = @"http://new.longboxed.com";
NSString *productionURL = @"http://longboxed.com";

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
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.longboxed.Longboxed-iOS-Staging"]) {
        return stagingURL;
    }
    else {
        return productionURL;
    }
}

+ (NSDictionary *)endpoints
{
  return  @{@"Issues Collection"                  : @"/api/v1/issues/",
            @"Issues Collection for Current Week" : @"/api/v1/issues/thisweek/",
            @"Issues Collection for Next Week"    : @"/api/v1/issues/nextweek/",
            @"Popular Issues for Current Week"    : @"/api/v1/issues/popular/",
            @"Issue"                              : @"/api/v1/issues/:issueID",
            @"Titles Collection"                  : @"/api/v1/titles/",
            @"Title"                              : @"/api/v1/titles/:titleID",
            @"Issues for Title"                   : @"/api/v1/titles/:titleID/issues/",
            @"Autocomplete for Title"             : @"/api/v1/titles/autocomplete/",
            @"Publisher Collection"               : @"/api/v1/publishers/",
            @"Publisher"                          : @"/api/v1/publishers/:publisherID",
            @"Titles for Publisher"               : @"/api/v1/publishers/:publisherID/titles/",
            @"Login"                              : @"/api/v1/users/login",
            @"User Pull List"                     : @"/api/v1/users/:userID/pull_list/",
            @"Add Title to Pull List"             : @"/api/v1/users/:userID/pull_list/",
            @"Remove Title from Pull List"        : @"/api/v1/users/:userID/pull_list/:titleID",
            @"Bundle Resources for User"          : @"/api/v1/users/:userID/bundles/",
            @"Latest Bundle"                      : @"/api/v1/users/:userID/bundles/latest"
            };
}

@end
