//
//  LBXPullList.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/3/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/CoreData.h>
#import "LBXPublisher.h"
#import "LBXIssue.h"

@class LBXIssue;

@interface LBXPullListTitle : NSManagedObject

@property (nonatomic, retain) NSNumber *titleID;
@property (nonatomic, retain) NSNumber *issueCount;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) LBXPublisher *publisher;
@property (nonatomic, retain) NSNumber *subscribers;
@property (nonatomic, retain) LBXIssue *latestIssue;

@end
