//
//  LBXBundle.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/7/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/CoreData.h>
#import "LBXIssue.h"

@interface LBXBundle : NSManagedObject

@property (nonatomic, retain) NSNumber *bundleID;
@property (nonatomic, retain) NSArray *issues;
@property (nonatomic, retain) NSDate *lastUpdatedDate;
@property (nonatomic, retain) NSDate *releaseDate;

@end
