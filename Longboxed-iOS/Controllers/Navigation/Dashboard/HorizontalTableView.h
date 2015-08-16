//
//  HorizontalTableView.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/12/15.
//  Copyright (c) 2015 Longboxed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HorizontalTableView : UITableView

@property (nonatomic, copy) NSArray *issuesArray;

- (void)setWidthConstraint:(CGFloat)width;

@end
