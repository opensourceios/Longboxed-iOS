//
//  LBXIssueDetailViewController.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/19/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LBXIssue.h"

@interface LBXIssueDetailViewController : UIViewController

@property (nonatomic, retain) NSNumber *issueID;

- (instancetype)initWithMainImage:(UIImage *)image andAlternates:(NSArray *)alternates;

@end
