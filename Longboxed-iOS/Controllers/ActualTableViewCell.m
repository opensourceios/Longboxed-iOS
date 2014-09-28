
//
//  ActualTableViewCell.m
//  HorizentalScrollSample
//
//  Created by Hb on 04/01/13.
//  Copyright (c) 2013 HB 23. All rights reserved.
//

#import "ActualTableViewCell.h"

#import "UIImage+ImageEffects.h"

@interface ActualTableViewCell ()

@property (nonatomic, copy) UIImage *originalImage;

@end

@implementation ActualTableViewCell
@synthesize coverImage,titleName;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self.titleName sizeToFit];
        _originalImage = [UIImage new];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if (!highlighted) {
        self.coverImage.layer.opacity = 1.0;
        self.titleName.textColor = [UIColor blackColor];
    }
    else {
        [self.imageView.layer setBackgroundColor:[UIColor blackColor].CGColor];
        self.coverImage.layer.opacity = 0.6;
        self.titleName.textColor = [UIColor lightGrayColor];
    }
}

@end
