//
//  LBXPullListTableViewCell.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/5/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXPullListTableViewCell.h"

@implementation LBXPullListTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.imageViewSeparatorLabel.layer.borderColor = [UIColor lightGrayColor].CGColor;
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
    self.imageViewSeparatorLabel.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.imageViewSeparatorLabel.layer.borderWidth = 0.25;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
