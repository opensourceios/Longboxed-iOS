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

@interface LBXControllerServices : NSObject

+ (NSDate *)getLocalDate;
+ (NSString *)timeSinceLastIssueForTitle:(LBXTitle *)title;
+ (LBXIssue *)closestIssueForTitle:(LBXTitle *)title;
+ (NSString *)localTimeZoneStringWithDate:(NSDate *)date;
+ (NSString *)getSubtitleStringWithTitle:(LBXTitle *)title uppercase:(BOOL)uppercase;
+ (void)setPublisherCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title;
+ (void)setPullListCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title;
+ (void)setAddToPullListSearchCell:(LBXPullListTableViewCell *)cell
                         withTitle:(LBXTitle *)title
                       darkenImage:(BOOL)darken;
+ (void)setTitleCell:(LBXPullListTableViewCell *)cell withIssue:(LBXIssue *)issue;
+ (void)setLabel:(UILabel *)textView
      withString:(NSString *)string
            font:(UIFont *)font
  inBoundsOfView:(UIView *)view;
+ (UIImage *)generateImageForPublisher:(LBXPublisher *)publisher size:(CGSize)size;
+ (NSString *)getHashOfImage:(UIImage *)image;
+ (NSArray *)refreshTableView:(UITableView *)tableView withOldSearchResults:(NSArray *)oldResultsArray
                   newResults:(NSArray *)newResultsArray
                    animation:(UITableViewRowAnimation)animation;

@end
