//
//  LBXIssue.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/6/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/CoreData.h>
#import "LBXPublisher.h"
#import "LBXTitle.h"

@interface LBXIssue : NSManagedObject

@property (nonatomic, retain) NSString *completeTitle;
@property (nonatomic, retain) NSString *coverImage;
@property (nonatomic, retain) NSString *issueDescription;
@property (nonatomic, retain) NSString *diamondID;
@property (nonatomic, retain) NSNumber *issueID;
@property (nonatomic, retain) NSNumber *isParent;
@property (nonatomic, retain) NSArray *alternates;
@property (nonatomic, retain) NSNumber *issueNumber;
@property (nonatomic, retain) NSNumber *price;
@property (nonatomic, retain) LBXPublisher *publisher;
@property (nonatomic, retain) NSDate *releaseDate;
@property (nonatomic, retain) LBXTitle *title;

@end



