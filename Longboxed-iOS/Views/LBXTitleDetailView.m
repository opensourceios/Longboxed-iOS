//
//  LBXTitleDetailView.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXTitleDetailView.h"
#import "LBXControllerServices.h"

@implementation LBXTitleDetailView

- (id)init {
    NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"LBXTitleDetailView" owner:self options:nil];
    id mainView = [subviewArray objectAtIndex:0];
    
    return mainView;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_latestIssueImageView
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:_latestIssueLabel
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1.0
                                                                   constant:-12.0];
    if (![LBXControllerServices isLoggedIn]) {
        [_addToPullListButton removeFromSuperview];
        [self addConstraint:constraint];
    }
    else {
        [self removeConstraint:constraint];
        [self addSubview:_addToPullListButton];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_addToPullListButton
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:_latestIssueImageView
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0
                                                          constant:22.0]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_addToPullListButton
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:_latestIssueLabel
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0
                                                          constant:-2.0]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_addToPullListButton
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeHeight
                                                        multiplier:1.0
                                                          constant:40.0]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_addToPullListButton
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0
                                                          constant:0.0]];
        
    }
}

@end
