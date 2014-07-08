//
//  LBXBundles.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/1/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXBundleOld.h"

@interface LBXBundleOld()

@property(nonatomic, copy) NSArray *bundle;

@end

@implementation LBXBundleOld

- (instancetype)initBundle:(NSArray *)bundle
{
    if (self) {
        self.bundle = bundle;
    }
    return self;
}

- (NSArray *)longboxedIDs
{
    return [self iterateThroughPullList:_bundle andMakeArrayWithKey:@"id"];
}

- (NSArray *)issues
{
    return [self iterateThroughPullList:_bundle andMakeArrayWithKey:@"issues"];
}

- (NSArray *)lastUpdatedDates
{
    return [self iterateThroughPullList:_bundle andMakeArrayWithKey:@"last_updated"];
}

- (NSArray *)releaseDates
{
    return [self iterateThroughPullList:_bundle andMakeArrayWithKey:@"release_date"];
}

# pragma mark Private Methods

- (NSArray *)iterateThroughPullList:(NSArray *)pullList andMakeArrayWithKey:(id)key
{
    NSMutableArray *mutableArray = [NSMutableArray new];
    for (NSDictionary *series in pullList) {
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
