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

- (RKEntityMapping *)bundleMapping
{
    RKEntityMapping* bundleMapping = [RKEntityMapping mappingForEntityForName:@"LBXBundle" inManagedObjectStore:[RKManagedObjectStore defaultStore]];
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
    RKEntityMapping* userMapping = [RKEntityMapping mappingForEntityForName:@"LBXUser" inManagedObjectStore:[RKManagedObjectStore defaultStore]];
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
    RKEntityMapping* titleMapping = [RKEntityMapping mappingForEntityForName:@"LBXTitle" inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [titleMapping addAttributeMappingsFromDictionary:@{ @"id"          : @"titleID",
                                                        @"issue_count" : @"issueCount",
                                                        @"name"        : @"name",
                                                        @"subscribers" : @"subscribers"
                                                        }];
    
    RKEntityMapping *publisherMapping = [self publisherMapping];
    RKEntityMapping *issueMapping = [self issueMapping];
    [titleMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"publisher"
                                                                                 toKeyPath:@"publisher"
                                                                               withMapping:publisherMapping]];
    
    [titleMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"latest_issue"
                                                                                    toKeyPath:@"latestIssue"
                                                                                  withMapping:issueMapping]];
    
    titleMapping.identificationAttributes = @[ @"titleID" ];
    
    return titleMapping;
}

- (RKEntityMapping *)pullListMapping
{
    RKEntityMapping* pullListMapping = [RKEntityMapping mappingForEntityForName:@"LBXPullListTitle" inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [pullListMapping addAttributeMappingsFromDictionary:@{ @"id"          : @"titleID",
                                                           @"issue_count" : @"issueCount",
                                                           @"name"        : @"name",
                                                           @"subscribers" : @"subscribers"
                                                        }];
    
    RKEntityMapping *publisherMapping = [self publisherMapping];
    RKEntityMapping *issueMapping = [self issueMapping];
    [pullListMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"publisher"
                                                                                    toKeyPath:@"publisher"
                                                                                  withMapping:publisherMapping]];
    
    [pullListMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"latest_issue"
                                                                                    toKeyPath:@"latestIssue"
                                                                                  withMapping:issueMapping]];
    
    pullListMapping.identificationAttributes = @[ @"titleID" ];
    
    return pullListMapping;
}

- (RKEntityMapping *)publisherMapping
{
    RKEntityMapping* publisherMapping = [RKEntityMapping mappingForEntityForName:@"LBXPublisher" inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [publisherMapping addAttributeMappingsFromDictionary:@{ @"colors.primary"   : @"primaryColor",
                                                            @"colors.secondary" : @"secondaryColor",
                                                            @"id"               : @"publisherID",
                                                            @"issue_count"      : @"issueCount",
                                                            @"name"             : @"name",
                                                            @"title_count"      : @"titleCount",
                                                            @"logo_bw.lg"       : @"largeLogoBW",
                                                            @"logo_bw.md"       : @"mediumLogoBW",
                                                            @"logo_bw.sm"       : @"smallLogoBW",
                                                            @"logo.lg"          : @"largeLogo",
                                                            @"logo.md"          : @"mediumLogo",
                                                            @"logo.sm"          : @"smallLogo",
                                                            @"splash.lg"        : @"largeSplash",
                                                            @"splash.md"        : @"mediumSplash",
                                                            @"splash.sm"        : @"smallSplash"
                                                            }];
    publisherMapping.identificationAttributes = @[ @"publisherID" ];
    
    return publisherMapping;
}

- (RKEntityMapping *)issueMapping
{
    RKEntityMapping* issueMapping = [RKEntityMapping mappingForEntityForName:@"LBXIssue" inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [issueMapping addAttributeMappingsFromDictionary:@{ @"complete_title" : @"completeTitle",
                                                        @"cover_image"    : @"coverImage",
                                                        @"description"    : @"issueDescription",
                                                        @"diamond_id"     : @"diamondID",
                                                        @"id"             : @"issueID",
                                                        @"is_parent"      : @"isParent",
                                                        @"alternates"     : @"alternates",
                                                        @"issue_number"   : @"issueNumber",
                                                        @"other"          : @"subtitle",
                                                        @"price"          : @"price",
                                                        @"release_date"   : @"releaseDate"
                                                        }];
    
    RKEntityMapping *publisherMapping = [self publisherMappingForIssue];
    RKEntityMapping *titleMapping = [self titleMappingForIssue];
    
    [issueMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"publisher"
                                                                                 toKeyPath:@"publisher"
                                                                               withMapping:publisherMapping]];
    
    [issueMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"title"
                                                                                 toKeyPath:@"title"
                                                                               withMapping:titleMapping]];
    issueMapping.identificationAttributes = @[ @"issueID" ];
    
    return issueMapping;
}

- (RKEntityMapping *)titleMappingForIssue
{
    RKEntityMapping* titleMapping = [RKEntityMapping mappingForEntityForName:@"LBXTitle" inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [titleMapping addAttributeMappingsFromDictionary:@{ @"id"          : @"titleID",
                                                        @"issue_count" : @"issueCount",
                                                        @"name"        : @"name",
                                                        @"subscribers" : @"subscribers"
                                                        }];
    
    RKEntityMapping *publisherMapping = [self publisherMapping];
    [titleMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"publisher"
                                                                                 toKeyPath:@"publisher"
                                                                               withMapping:publisherMapping]];
    titleMapping.identificationAttributes = @[ @"titleID" ];
    
    return titleMapping;
}

- (RKEntityMapping *)publisherMappingForIssue
{
    RKEntityMapping* publisherMapping = [RKEntityMapping mappingForEntityForName:@"LBXPublisher" inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [publisherMapping addAttributeMappingsFromDictionary:@{ @"colors.primary"   : @"primaryColor",
                                                            @"colors.secondary" : @"secondaryColor",
                                                            @"id"               : @"publisherID",
                                                            @"issue_count"      : @"issueCount",
                                                            @"name"             : @"name",
                                                            @"title_count"      : @"titleCount",
                                                            @"logo_bw.lg"       : @"largeLogoBW",
                                                            @"logo_bw.md"       : @"mediumLogoBW",
                                                            @"logo_bw.sm"       : @"smallLogoBW",
                                                            @"logo.lg"          : @"largeLogo",
                                                            @"logo.md"          : @"mediumLogo",
                                                            @"logo.sm"          : @"smallLogo",
                                                            @"splash.lg"        : @"largeSplash",
                                                            @"splash.md"        : @"mediumSplash",
                                                            @"splash.sm"        : @"smallSplash"
                                                            }];
    publisherMapping.identificationAttributes = @[ @"publisherID" ];
    
    return publisherMapping;
}

@end
