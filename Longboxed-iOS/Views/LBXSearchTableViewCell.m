//
//  TMWCustomCellTableViewCell.m
//  ThatMovieWith
//
//  Created by johnrhickey on 4/16/14.
//  Copyright (c) 2014 Jay Hickey. All rights reserved.
//

#import "LBXSearchTableViewCell.h"

@implementation LBXSearchTableViewCell

// Creates circular images in table cells
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(self.textLabel.frame.origin.x + self.textLabel.frame.size.width - IMAGE_RIGHT_OFFSET,self.textLabel.frame.origin.y + IMAGE_TOP_OFFSET + IMAGE_SIZE/2, IMAGE_SIZE, IMAGE_SIZE);
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
   
    self.textLabel.frame = CGRectMake(self.textLabel.superview.frame.origin.x + IMAGE_RIGHT_OFFSET, self.textLabel.frame.origin.y, self.textLabel.superview.frame.size.width - (IMAGE_SIZE + IMAGE_TEXT_OFFSET), self.textLabel.superview.frame.size.height);
}

@end
