//
//  LBXPullList.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXPullList.h"

@interface LBXPullList()

@property(nonatomic, copy) NSArray *pullList;

@end

@implementation LBXPullList

- (instancetype)initPullList:(NSArray *)pullList
{
    if (self) {
        self.pullList = pullList;
    }
    return self;
}

- (NSArray *)longboxedIDs
{
   return [self iterateThroughPullList:_pullList andMakeArrayWithKey:@"id"];
}

- (NSArray *)issueCount
{
   return [self iterateThroughPullList:_pullList andMakeArrayWithKey:@"issue_count"];
}

- (NSArray *)names
{
    return [self iterateThroughPullList:_pullList andMakeArrayWithKey:@"name"];
}

- (NSArray *)publishers
{
    return [self iterateThroughPullList:_pullList andMakeArrayWithKey:@"publsher"];
}

- (NSArray *)subscribers
{
    return [self iterateThroughPullList:_pullList andMakeArrayWithKey:@"subscribers"];
}



# pragma mark Private Methods

- (NSArray *)iterateThroughPullList:(NSArray *)pullList andMakeArrayWithKey:(id)key
{
    NSMutableArray *mutableArray = [NSMutableArray new];
    for (NSDictionary *series in pullList) {
        NSLog(@"%@", series);
        if (series[key] != (id)[NSNull null] || series[key] != nil) {
            [mutableArray addObject:[NSString stringWithFormat:@"%@",series[key]]];
        }
        else {
            [mutableArray addObject:@""];
        }
    }
    return mutableArray;
}

@end
