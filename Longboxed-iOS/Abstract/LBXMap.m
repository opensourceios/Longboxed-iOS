//
//  LBXMapper.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXMap.h"

#import "LBXUser.h"
#import "LBXIssue.h"
#import "LBXPublisher.h"
#import "LBXTitle.h"
#import "LBXBundle.h"

#import "LBXAppDelegate.h"

@implementation LBXMap

static LBXMap *map;

// Singleton for accessing the same instance in multiple view controllers
+ (void)initialize
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        map = [[LBXMap alloc] init];
    }
}

+ (LBXMap *)map
{
    [self initialize];
    return map;
}

- (RKEntityMapping *)bundleMapping
{
    RKEntityMapping* bundleMapping = [RKEntityMapping mappingForEntityForName:@"Bundle" inManagedObjectStore:self.managedObjectStore];
    [bundleMapping addAttributeMappingsFromDictionary:@{ @"id"           : @"bundleID",
                                                         @"last_updated" : @"lastUpdatedDate",
                                                         @"release_date" : @"releaseDate"
                                                         }];
    
    RKEntityMapping *issueMapping = [self issueMapping];
    [bundleMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"issues"
                                                                                  toKeyPath:@"issues"
                                                                                withMapping:issueMapping]];
    bundleMapping.identificationAttributes = @[ @"bundleID" ];
    
    return bundleMapping;
}

- (RKEntityMapping *)userMapping
{
    RKEntityMapping* userMapping = [RKEntityMapping mappingForEntityForName:@"User" inManagedObjectStore:self.managedObjectStore];
    [userMapping addAttributeMappingsFromDictionary:@{ @"email"     : @"email",
                                                       @"first_name": @"firstName",
                                                       @"id"        : @"userID",
                                                       @"last_name" : @"lastName"
                                                       }];
    [userMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"roles"]];
    userMapping.identificationAttributes = @[ @"userID" ];
    return userMapping;
}

- (RKEntityMapping *)titleMapping
{
    RKEntityMapping* titleMapping = [RKEntityMapping mappingForEntityForName:@"Title" inManagedObjectStore:self.managedObjectStore];
    [titleMapping addAttributeMappingsFromDictionary:@{ @"id"   : @"titleID",
                                                        @"issue_count" : @"issueCount",
                                                        @"name" : @"name",
                                                        @"subscribers" : @"subscribers"
                                                        }];
    
    RKEntityMapping *publisherMapping = [self publisherMapping];
    [titleMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"publisher"
                                                                                 toKeyPath:@"publisher"
                                                                               withMapping:publisherMapping]];
    titleMapping.identificationAttributes = @[ @"titleID" ];
    //[titleMapping addConnectionForRelationship:@"publisher" connectedBy:@{@"publisherID": @"publisher.publisherID"}];
    return titleMapping;
}

- (RKEntityMapping *)publisherMapping
{
    RKEntityMapping* publisherMapping = [RKEntityMapping mappingForEntityForName:@"Publisher" inManagedObjectStore:self.managedObjectStore];
    [publisherMapping addAttributeMappingsFromDictionary:@{ @"id"          : @"publisherID",
                                                            @"issue_count" : @"issueCount",
                                                            @"name"        : @"name",
                                                            @"title_count" : @"titleCount"
                                                            }];
    publisherMapping.identificationAttributes = @[ @"publisherID" ];
    return publisherMapping;
}

- (RKEntityMapping *)issueMapping
{
    RKEntityMapping* issueMapping = [RKEntityMapping mappingForEntityForName:@"Issue" inManagedObjectStore:self.managedObjectStore];
    [issueMapping addAttributeMappingsFromDictionary:@{ @"complete_title" : @"completeTitle",
                                                        @"cover_image"    : @"coverImage",
                                                        @"description"    : @"issueDescription",
                                                        @"diamond_id"     : @"diamondID",
                                                        @"id"             : @"issueID",
                                                        @"issue_number"   : @"issueNumber",
                                                        @"price"          : @"price",
                                                        @"release_date"   : @"releaseDate"
                                                        }];
    
    RKEntityMapping *publisherMapping = [self publisherMapping];
    RKEntityMapping *titleMapping = [self titleMapping];
    
    [issueMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"publisher"
                                                                                 toKeyPath:@"publisher"
                                                                               withMapping:publisherMapping]];
    
    [issueMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"title"
                                                                                 toKeyPath:@"title"
                                                                               withMapping:titleMapping]];
    issueMapping.identificationAttributes = @[ @"issueID" ];
//    [issueMapping addConnectionForRelationship:@"publisher" connectedBy:@{@"publisherID": @"publisherID"}];
//    [issueMapping addConnectionForRelationship:@"title" connectedBy:@{@"titleID": @"titleID"}];
    return issueMapping;
}

- (RKEntityMapping *)paginationMapping
{
    RKEntityMapping *paginationMapping = [RKEntityMapping mappingForClass:[RKPaginator class]];
    [paginationMapping addAttributeMappingsFromDictionary:@{
                                                            @"total" :   @"objectCount",
                                                            @"count" :   @"perPage"
                                                            }];
    return paginationMapping;
}

@end
