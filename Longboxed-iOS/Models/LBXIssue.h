//
//  LBXIssue.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/6/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBXPublisher.h"
#import "LBXTitle.h"

@interface LBXIssue : NSObject

@property (nonatomic, copy) NSString *completeTitle;
@property (nonatomic, copy) NSURL *coverImage;
@property (nonatomic, copy) NSString *issueDescription;
@property (nonatomic, copy) NSString *diamondID;
@property (nonatomic, copy) NSNumber *longboxedID;
@property (nonatomic, copy) NSNumber *issueNumber;
@property (nonatomic, copy) NSNumber *price;
@property (nonatomic, retain) LBXPublisher *publisher;
@property (nonatomic, copy) NSDate *releaseDate;
@property (nonatomic, retain) LBXTitle *title;

@end



