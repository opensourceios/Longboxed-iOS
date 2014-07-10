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

@implementation LBXMap

- (RKObjectMapping *)bundleMapping
{
    RKObjectMapping* bundleMapping = [RKObjectMapping mappingForClass:[LBXUser class]];
    [bundleMapping addAttributeMappingsFromDictionary:@{ @"id"           : @"bundleID",
                                                         @"last_updated" : @"lastUpdatedDate",
                                                         @"release_date" : @"releaseDate"
                                                         }];
    
    RKObjectMapping *issueMapping = [self issueMapping];
    // TODO: Note that this is an array of issues. Read how to handle this. I don't believe this is correct
    [bundleMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"issues"
                                                                                  toKeyPath:@"issues"
                                                                                withMapping:issueMapping]];
    return bundleMapping;
}

- (RKObjectMapping *)userMapping
{
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[LBXUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"email"     : @"email",
                                                       @"first_name": @"firstName",
                                                       @"id"        : @"userID",
                                                       @"last_name" : @"lastName"
                                                       }];
    [userMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"roles"]];
    return userMapping;
}

- (RKObjectMapping *)titleMapping
{
    RKObjectMapping* titleMapping = [RKObjectMapping mappingForClass:[LBXTitle class]];
    [titleMapping addAttributeMappingsFromDictionary:@{ @"id"   : @"titleID",
                                                        @"issue_count" : @"issueCount",
                                                        @"name" : @"name",
                                                        @"subscribers" : @"subscribers"
                                                        }];
    
    RKObjectMapping *publisherMapping = [self publisherMapping];
    [titleMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"publisher"
                                                                                 toKeyPath:@"publisher"
                                                                               withMapping:publisherMapping]];
    return titleMapping;
}

- (RKObjectMapping *)publisherMapping
{
    RKObjectMapping* publisherMapping = [RKObjectMapping mappingForClass:[LBXPublisher class]];
    [publisherMapping addAttributeMappingsFromDictionary:@{ @"id"          : @"publisherID",
                                                            @"issue_count" : @"issueCount",
                                                            @"name"        : @"name",
                                                            @"title_count" : @"titleCount"
                                                            }];
    return publisherMapping;
}

- (RKObjectMapping *)issueMapping
{
    RKObjectMapping* issueMapping = [RKObjectMapping mappingForClass:[LBXIssue class]];
    [issueMapping addAttributeMappingsFromDictionary:@{ @"complete_title" : @"completeTitle",
                                                        @"cover_image"    : @"coverImage",
                                                        @"description"    : @"issueDescription",
                                                        @"diamond_id"     : @"diamondID",
                                                        @"id"             : @"issueID",
                                                        @"issue_number"   : @"issueNumber",
                                                        @"price"          : @"price",
                                                        @"release_date"   : @"releaseDate"
                                                        }];
    
    RKObjectMapping *publisherMapping = [self publisherMapping];
    RKObjectMapping *titleMapping = [self titleMapping];
    
    [issueMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"publisher"
                                                                                 toKeyPath:@"publisher"
                                                                               withMapping:publisherMapping]];
    
    [issueMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"title"
                                                                                 toKeyPath:@"title"
                                                                               withMapping:titleMapping]];
    return issueMapping;
}

- (RKObjectMapping *)paginationMapping
{
    RKObjectMapping *paginationMapping = [RKObjectMapping mappingForClass:[RKPaginator class]];
    [paginationMapping addAttributeMappingsFromDictionary:@{
                                                            @"total" :   @"objectCount",
                                                            @"count" :   @"perPage"
                                                            }];
    return paginationMapping;
}

@end
