//
//  HorizontalTableViewCell.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/12/15.
//  Copyright (c) 2015 Longboxed. All rights reserved.
//

#import "HorizontalTableViewCell.h"

@implementation HorizontalTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if (!highlighted) {
        self.imgView.layer.opacity = 1.0;
        self.label.textColor = [UIColor blackColor];
    }
    else {
        [self.imageView.layer setBackgroundColor:[UIColor blackColor].CGColor];
        self.imgView.layer.opacity = 0.6;
        self.label.textColor = [UIColor lightGrayColor];
    }
}

@end
