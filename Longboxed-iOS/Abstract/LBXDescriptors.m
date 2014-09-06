//
//  LBXDescriptor.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXDescriptors.h"
#import "LBXMap.h"
#import "LBXEndpoints.h"
#import "LBXUser.h"
#import "LBXTitle.h"

@implementation LBXDescriptors

// Descriptors for handling the JSON responses and creating objects
+ (NSArray *)GETResponseDescriptors
{
    LBXMap *mapper = [LBXMap new];
    // Instantiate the KVC mappings
    RKObjectMapping *userMapping = mapper.userMapping;
    RKObjectMapping *issueMapping = mapper.issueMapping;
    RKObjectMapping *publisherMapping = mapper.publisherMapping;
    RKObjectMapping *titleMapping = mapper.titleMapping;
    RKObjectMapping *pullListMapping = mapper.pullListMapping;
    RKObjectMapping *bundleMapping = mapper.bundleMapping;
    
    NSDictionary *endpointDict = [LBXEndpoints endpoints];
    // Issues
    RKResponseDescriptor *issuesCollectionResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:issueMapping
                                                 method:RKRequestMethodGET
                                            pathPattern:endpointDict[@"Issues Collection"]
                                                keyPath:@"issues"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *issuesCollectionForCurrentWeekResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:issueMapping
                                                 method:RKRequestMethodGET
                                            pathPattern:endpointDict[@"Issues Collection for Current Week"]
                                                keyPath:@"issues"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *issuesCollectionForNextWeekResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:issueMapping
                                                 method:RKRequestMethodGET
                                            pathPattern:endpointDict[@"Issues Collection for Next Week"]
                                                keyPath:@"issues"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *popularIssuesCurrentWeekResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:issueMapping
                                                 method:RKRequestMethodGET
                                            pathPattern:endpointDict[@"Popular Issues for Current Week"]
                                                keyPath:@"issues"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    
    RKResponseDescriptor *issueResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:issueMapping
                                                 method:RKRequestMethodGET
                                            pathPattern:endpointDict[@"Issue"]
                                                keyPath:@"issue"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    // Titles
    RKResponseDescriptor *titlesCollectionResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:titleMapping
                                                 method:RKRequestMethodGET
                                            pathPattern:endpointDict[@"Titles Collection"]
                                                keyPath:@"titles"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *titleResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:titleMapping
                                                 method:RKRequestMethodGET
                                            pathPattern:endpointDict[@"Title"]
                                                keyPath:@"title"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *issuesForTitleResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:issueMapping
                                                 method:RKRequestMethodGET
                                            pathPattern:endpointDict[@"Issues for Title"]
                                                keyPath:@"issues"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *autocompleteForTitlesResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:titleMapping
                                                 method:RKRequestMethodGET
                                            pathPattern:endpointDict[@"Autocomplete for Title"]
                                                keyPath:@"suggestions"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    // Publishers
    RKResponseDescriptor *publisherCollectionResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:publisherMapping
                                                 method:RKRequestMethodGET
                                            pathPattern:endpointDict[@"Publisher Collection"]
                                                keyPath:@"publishers"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *publisherResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:publisherMapping
                                                 method:RKRequestMethodGET
                                            pathPattern:endpointDict[@"Publisher"]
                                                keyPath:@"publisher"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *titlesForPublisherResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:titleMapping
                                                 method:RKRequestMethodGET
                                            pathPattern:endpointDict[@"Titles for Publisher"]
                                                keyPath:@"titles"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    // Users
    RKResponseDescriptor *loginResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:userMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Login"]
                                                keyPath:@"user"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *userPullListResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:pullListMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"User Pull List"]
                                                keyPath:@"pull_list"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *bundleResourcesForUserResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:bundleMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Bundle Resources for User"]
                                                keyPath:@"bundles"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *latestBundleResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:bundleMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Latest Bundle"]
                                                keyPath:nil
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    return @[issuesCollectionResponseDescriptor,
             issuesCollectionForCurrentWeekResponseDescriptor,
             popularIssuesCurrentWeekResponseDescriptor,
             issuesCollectionForNextWeekResponseDescriptor,
             issueResponseDescriptor,
             titlesCollectionResponseDescriptor,
             titleResponseDescriptor,
             issuesForTitleResponseDescriptor,
             autocompleteForTitlesResponseDescriptor,
             publisherCollectionResponseDescriptor,
             publisherResponseDescriptor,
             titlesForPublisherResponseDescriptor,
             loginResponseDescriptor,
             userPullListResponseDescriptor,
             bundleResourcesForUserResponseDescriptor,
             latestBundleResponseDescriptor
             ];
}

@end
