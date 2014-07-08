//
//  LBXBundle.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/7/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBXIssue.h"

@interface LBXBundle : NSObject

@property (nonatomic, copy) NSNumber *bundleID;
@property (nonatomic, copy) LBXIssue *issue;
@property (nonatomic, copy) NSDate *lastUpdatedDate;
@property (nonatomic, copy) NSDate *releaseDate;

@end
