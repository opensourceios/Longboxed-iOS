//
//  LBXThisWeekComics.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXThisWeeksComics.h"

@interface LBXThisWeeksComics()

@property(nonatomic, copy) NSArray *issues;

@end

@implementation LBXThisWeeksComics

- (instancetype)initThisWeeksComicsWithIssues:(NSArray *)issues
{
    if (self) {
        self.issues = issues;
    }
    return self;
}

- (NSArray *)completeTitles
{
    return [self iterateThroughIssues:_issues andMakeArrayWithKey:@"complete_title"];
}

- (NSArray *)coverImages
{
    return [self iterateThroughIssues:_issues andMakeArrayWithKey:@"cover_image"];
}

- (NSArray *)descriptions
{
    return [self iterateThroughIssues:_issues andMakeArrayWithKey:@"decription"];
}

- (NSArray *)diamondIDs
{
   return [self iterateThroughIssues:_issues andMakeArrayWithKey:@"diamond_id"];
}

- (NSArray *)longboxedIDs
{
   return [self iterateThroughIssues:_issues andMakeArrayWithKey:@"id"];
}

- (NSArray *)issueNumbers
{
   return [self iterateThroughIssues:_issues andMakeArrayWithKey:@"issue_number"];
}

- (NSArray *)prices
{
   return [self iterateThroughIssues:_issues andMakeArrayWithKey:@"price"];
}

- (NSArray *)publishers
{
    return [self iterateThroughIssues:_issues andMakeArrayWithKey:@"publisher"];
}

- (NSArray *)releaseDates
{
    return [self iterateThroughIssues:_issues andMakeArrayWithKey:@"release_date"];
}

- (NSArray *)titles
{
    return [self iterateThroughIssues:_issues andMakeArrayWithKey:@"title"];
}


# pragma mark Private Methods

- (NSArray *)iterateThroughIssues:(NSArray *)issues andMakeArrayWithKey:(id)key
{
    NSMutableArray *mutableArray = [NSMutableArray new];
    for (NSDictionary *issue in issues) {
        if (issue[key] != (id)[NSNull null]) {
            [mutableArray addObject:issue[key]];
        }
        else {
            [mutableArray addObject:@""];
        }
    }
    return mutableArray;
}

@end
