//
//  LBXTitleServices.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBXTitle.h"
#import "LBXIssue.h"
#import "LBXPullListTableViewCell.h"

@interface LBXTitleServices : NSObject

+ (NSString *)timeSinceLastIssueForTitle:(LBXTitle *)title;
+ (NSNumber *)lastIssueNumberForTitle:(LBXTitle *)title;
+ (LBXIssue *)lastIssueForTitle:(LBXTitle *)title;
+ (void)setCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title;
+ (void)setCell:(LBXPullListTableViewCell *)cell withIssue:(LBXIssue *)issue;

@end
