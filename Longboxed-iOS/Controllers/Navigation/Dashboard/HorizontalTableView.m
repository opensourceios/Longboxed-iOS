//
//  HorizontalTableView.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/12/15.
//  Copyright (c) 2015 Longboxed. All rights reserved.
//

#import "HorizontalTableView.h"

@interface HorizontalTableView ()

@end

@implementation HorizontalTableView

#pragma mark Overrides

- (void)makeHorizontal
{
    self.transform = CGAffineTransformMakeRotation(-M_PI * 0.5);
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self makeHorizontal];
        self.userInteractionEnabled = YES;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    if (self)
    {
        [self makeHorizontal];
        self.userInteractionEnabled = YES;
    }
    
    return self;
}

- (void)updateConstraints {
    [self setWidthConstraint:[[UIScreen mainScreen] bounds].size.width];
    [super updateConstraints];
}

#pragma mark Public Methods

- (void)setWidthConstraint:(CGFloat)width {
    
    // Set the width of the horizontal view
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                       attribute:NSLayoutAttributeHeight
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:nil
                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                      multiplier:1.0
                                                        constant:width]];
}

#pragma mark Private Methods


@end
