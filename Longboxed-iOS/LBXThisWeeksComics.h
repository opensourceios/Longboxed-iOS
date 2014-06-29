//
//  LBXThisWeekComics.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBXThisWeeksComics : NSObject

@property(nonatomic, copy, readonly) NSArray *completeTitles;
@property(nonatomic, copy, readonly) NSArray *coverImages;
@property(nonatomic, copy, readonly) NSArray *descriptions;
@property(nonatomic, copy, readonly) NSArray *diamondIDs;
@property(nonatomic, copy, readonly) NSArray *longboxedIDs;
@property(nonatomic, copy, readonly) NSArray *issueNumbers;
@property(nonatomic, copy, readonly) NSArray *prices;
@property(nonatomic, copy, readonly) NSArray *publishers;
@property(nonatomic, copy, readonly) NSArray *releaseDates;
@property(nonatomic, copy, readonly) NSArray *titles;

- (instancetype)initThisWeeksComicsWithIssues:(NSArray *)issues;

@end
