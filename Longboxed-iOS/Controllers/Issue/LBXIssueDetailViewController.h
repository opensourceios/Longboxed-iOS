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

@property (nonatomic, retain) LBXIssue *issue;
@property (nonatomic) IBOutlet UIView *alternativeCoversArrowView;
@property (nonatomic) IBOutlet UIImageView *coverImageView;

- (instancetype)initWithMainImage:(UIImage *)image;
- (instancetype)initWithFrame:(CGRect)frame andIssue:(LBXIssue *)issue;

@end
