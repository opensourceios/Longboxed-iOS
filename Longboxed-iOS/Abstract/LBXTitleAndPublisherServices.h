//
//  LBXTitleServices.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXTitle.h"
#import "LBXIssue.h"
#import "LBXPullListTableViewCell.h"

#import <Foundation/Foundation.h>

@interface LBXTitleAndPublisherServices : NSObject

+ (NSString *)timeSinceLastIssueForTitle:(LBXTitle *)title;
+ (NSNumber *)lastIssueNumberForTitle:(LBXTitle *)title;
+ (LBXIssue *)lastIssueForTitle:(LBXTitle *)title;
+ (NSString *)localTimeZoneStringWithDate:(NSDate *)date;
+ (void)setPublisherCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title;
+ (void)setTitleCell:(LBXPullListTableViewCell *)cell withIssue:(LBXIssue *)issue;
+ (void)setPullListCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title;

@end