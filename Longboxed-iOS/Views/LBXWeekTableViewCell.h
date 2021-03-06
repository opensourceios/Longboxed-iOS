//
//  LBXWeekTableViewCell.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LBXWeekTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *latestIssueImageView;
@property (nonatomic, weak) IBOutlet UILabel *imageViewSeparatorLabel;

@end
