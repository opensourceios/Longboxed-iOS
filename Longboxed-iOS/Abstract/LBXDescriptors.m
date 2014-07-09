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

@implementation LBXDescriptors

// Descriptors for handling the JSON responses and creating objects
+ (NSArray *)responseDescriptors
{
    LBXMap *mapper = [LBXMap new];
    // Instantiate the KVC mappings
    RKObjectMapping *userMapping = mapper.userMapping;
    RKObjectMapping *issueMapping = mapper.issueMapping;
    RKObjectMapping *publisherMapping = mapper.publisherMapping;
    RKObjectMapping *titleMapping = mapper.titleMapping;
    RKObjectMapping *bundleMapping = mapper.bundleMapping;
    RKObjectMapping *paginationMapping = mapper.paginationMapping;
    
    NSDictionary *endpointDict = [LBXEndpoints endpoints];
//  TODO: Add pagination to the rest of the responses
    // Issues
    RKResponseDescriptor *issuesCollectionResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:issueMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Issues Collection"]
                                                keyPath:@"issues"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *issuesCollectionPaginationResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:paginationMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Issues Collection"]
                                                keyPath:nil
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]; // Pagination
    
    
    
    RKResponseDescriptor *issuesCollectionForCurrentWeekResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:issueMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Issues Collection for Current Week"]
                                                keyPath:@"issues"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    
    RKResponseDescriptor *issueResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:issueMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Issue"]
                                                keyPath:@"issue"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    // Titles
    RKResponseDescriptor *titlesCollectionResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:titleMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Titles Collection"]
                                                keyPath:@"titles"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *titleResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:titleMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Title"]
                                                keyPath:@"title"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *issuesForTitleResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:titleMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Issues for Title"]
                                                keyPath:@"issues"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *autocompleteForTitlesResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:titleMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Autocomplete for Titles"]
                                                keyPath:@"suggestions"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    // Publishers
    RKResponseDescriptor *publisherCollectionResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:publisherMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Publisher Collection"]
                                                keyPath:@"publishers"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *publisherResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:publisherMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Publisher"]
                                                keyPath:@"publisher"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *titlesForPublisherResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:publisherMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Titles for Publisher"]
                                                keyPath:@"titles"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    // Users
    
    // TODO: These will need modified for POST/DELETE
    RKResponseDescriptor *loginResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:userMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"login"]
                                                keyPath:@"user"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *userPullListResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:userMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"User Pull List"]
                                                keyPath:@"pull_list"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *userPullListDeleteDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:userMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Add Title to Pull List"]
                                                keyPath:@"pull_list"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *userPullListPostDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:userMapping
                                                 method:RKRequestMethodAny
                                            pathPattern:endpointDict[@"Remove Title from Pull List"]
                                                keyPath:@"pull_list"
                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *bundleResourcesForUserResponseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:publisherMapping
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
             issuesCollectionPaginationResponseDescriptor,
             issuesCollectionForCurrentWeekResponseDescriptor,
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
             userPullListPostDescriptor,
             userPullListDeleteDescriptor,
             bundleResourcesForUserResponseDescriptor,
             latestBundleResponseDescriptor
             ];
}

@end
