//
//  LBXPullList.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBXPullList : NSObject

@property(nonatomic, copy, readonly) NSArray *longboxedIDs;
@property(nonatomic, copy, readonly) NSArray *issueCount;
@property(nonatomic, copy, readonly) NSArray *names;
@property(nonatomic, copy, readonly) NSArray *publishers;
@property(nonatomic, copy, readonly) NSArray *subscribers;

- (instancetype)initPullList:(NSArray *)pullList;

@end
