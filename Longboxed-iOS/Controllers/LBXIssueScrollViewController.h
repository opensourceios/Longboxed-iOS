//
//  LBXIssueScrollViewController.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/23/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LBXIssue.h"

@interface LBXIssueScrollViewController : UIViewController

- (instancetype)initWithIssue:(LBXIssue *)issue andImage:(UIImage *)image;

@end
