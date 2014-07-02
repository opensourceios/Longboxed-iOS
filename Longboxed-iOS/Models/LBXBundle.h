//
//  LBXBundles.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/1/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBXBundle : NSObject

@property(nonatomic, copy, readonly) NSArray *longboxedIDs;
@property(nonatomic, copy, readonly) NSArray *issues;
@property(nonatomic, copy, readonly) NSArray *lastUpdatedDates;
@property(nonatomic, copy, readonly) NSArray *releaseDates;

- (instancetype)initBundle:(NSArray *)bundle;

@end
