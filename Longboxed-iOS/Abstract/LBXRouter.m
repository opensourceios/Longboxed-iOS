//
//  LBXRouter.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXRouter.h"
#import "LBXEndpoints.h"
#import "NSString+URLQuery.h"

@implementation LBXRouter

// Routing
+ (RKRouter *)routerWithQueryParameters:(NSDictionary *)parameters
{
    NSString *urlString = @"http://www.longboxed.com";
    RKRouter *router = [[RKRouter alloc] initWithBaseURL:[NSURL URLWithString:urlString]];
    
    NSDictionary *endpointDict = [LBXEndpoints endpoints];
    
    // Issues
    [router.routeSet addRoute:[RKRoute routeWithName:@"Issues Collection"
                                         pathPattern:[NSString addQueryStringToUrlString:endpointDict[@"Issues Collection"]
                                                                          withDictionary:parameters]
                                              method:RKRequestMethodGET]]; // Required parameter is ?date=2014-06-25
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Issues Collection for Current Week"
                                         pathPattern:endpointDict[@"Issues Collection for Current Week"]
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Issue"
                                         pathPattern:endpointDict[@"Issue"]
                                              method:RKRequestMethodGET]];
    
    // Titles
    [router.routeSet addRoute:[RKRoute routeWithName:@"Titles Collection"
                                         pathPattern:[NSString addQueryStringToUrlString:endpointDict[@"Titles Collection"]
                                                                          withDictionary:parameters]
                                              method:RKRequestMethodGET]]; // Optional parameter is ?page=2
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Title"
                                         pathPattern:endpointDict[@"Title"]
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Issues for Title"
                                         pathPattern:[NSString addQueryStringToUrlString:endpointDict[@"Issues for Title"]
                                                                          withDictionary:parameters]
                                              method:RKRequestMethodGET]]; // Optional parameter is ?page=2
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Autocomplete for Titles"
                                         pathPattern:endpointDict[@"Autocomplete for Titles"]
                                              method:RKRequestMethodGET]]; // Required parameter is ?search=spider
    
    // Publishers
    [router.routeSet addRoute:[RKRoute routeWithName:@"Publisher Collection"
                                         pathPattern:endpointDict[@"Publisher Collection"]
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Publisher"
                                         pathPattern:endpointDict[@"Publisher"]
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Titles for Publisher"
                                         pathPattern:[NSString addQueryStringToUrlString:endpointDict[@"Titles for Publisher"]
                                                                          withDictionary:parameters]
                                              method:RKRequestMethodGET]]; // Optional parameter is ?page=2
    
    // Users
    [router.routeSet addRoute:[RKRoute routeWithName:@"Login"
                                         pathPattern:endpointDict[@"Login"]
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"User Pull List"
                                         pathPattern:endpointDict[@"User Pull List"]
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Add Title to Pull List"
                                         pathPattern:[NSString addQueryStringToUrlString:endpointDict[@"Add Title to Pull List"]
                                                                          withDictionary:parameters]
                                              method:RKRequestMethodPOST]]; // Required parameter is ?title_id=20
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Remove Title from Pull List"
                                         pathPattern:[NSString addQueryStringToUrlString:endpointDict[@"Remove Title from Pull List"]
                                                                          withDictionary:parameters]
                                              method:RKRequestMethodDELETE]]; // Required parameter is ?title_id=20
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Bundle Resources for User"
                                         pathPattern:endpointDict[@"Bundle Resources for User"]
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Latest Bundle"
                                         pathPattern:endpointDict[@"Latest Bundle"]
                                              method:RKRequestMethodGET]];
    
    return router;
}


@end
