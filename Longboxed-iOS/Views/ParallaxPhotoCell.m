//
//  ParallaxPhotoCell.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Jay Hickey. All rights reserved.
//

#import "ParallaxPhotoCell.h"
#import "ParallaxLayoutAttributes.h"

@interface ParallaxPhotoCell ()

@property (nonatomic, strong) NSLayoutConstraint *imageViewHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *imageViewCenterYConstraint;
@property (nonatomic, strong) NSLayoutConstraint *movieNameHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *movieNameCenterYConstraint;

@end


@implementation ParallaxPhotoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self == nil) {
        return nil;
    }

    self.clipsToBounds = YES;

    [self setupImageView];
    [self setupActivityIndicator]; // Must be added to view after imageview so
                                   // it isn't covered by black temp image
    [self setupComicLabel];
    [self setupPublisherLabel];
    [self setupIssueLabel];
    [self setupConstraints];
    [self setNeedsUpdateConstraints];
    
    return self;
}

- (void)setupImageView
{
    _comicImageView = [[UIImageView alloc] initWithImage:nil];
    _comicImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.comicImageView.bounds = self.contentView.bounds;
    [self.contentView addSubview:_comicImageView];
}

- (void)setupActivityIndicator
{
    _activityIndicator = [[UIActivityIndicatorView alloc]  initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.bounds = self.contentView.bounds;
    self.activityIndicator.center = self.contentView.center;
    [self.contentView addSubview:_activityIndicator];
}

- (void)setupComicLabel
{
    _comicTitleLabel = [UILabel new];
    self.comicTitleLabel.textColor = [UIColor whiteColor];
    self.comicTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.comicTitleLabel.backgroundColor = [UIColor clearColor];
    self.comicTitleLabel.frame = self.contentView.bounds;
    self.comicTitleLabel.center = self.contentView.center;
    [self.contentView addSubview:_comicTitleLabel];
}

// Bottom right corner label
- (void)setupPublisherLabel
{
    _comicPublisherLabel = [UILabel new];
    self.comicPublisherLabel.textColor = [UIColor whiteColor];
    self.comicPublisherLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
    self.comicPublisherLabel.textAlignment = NSTextAlignmentRight;
    self.comicPublisherLabel.backgroundColor = [UIColor clearColor];
    
    // TODO: Use autolayout for this
    self.comicPublisherLabel.frame = CGRectMake(self.contentView.frame.origin.x - 5, self.contentView.frame.origin.y + self.contentView.frame.size.height/2 - 12, self.contentView.frame.size.width, self.contentView.frame.size.height);
    [self.contentView addSubview:_comicPublisherLabel];
}

// Bottom left corner label
- (void)setupIssueLabel
{
    _comicIssueLabel = [UILabel new];
    self.comicIssueLabel.textColor = [UIColor whiteColor];
    self.comicIssueLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
    self.comicIssueLabel.textAlignment = NSTextAlignmentLeft;
    self.comicIssueLabel.backgroundColor = [UIColor clearColor];
    
    // TODO: Use autolayout for this
    self.comicIssueLabel.frame = CGRectMake(self.contentView.frame.origin.x + 5, self.contentView.frame.origin.y + self.contentView.frame.size.height/2 - 12, self.contentView.frame.size.width, self.contentView.frame.size.height);
    [self.contentView addSubview:_comicIssueLabel];
}

- (void)setupConstraints
{
    self.comicImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Horizontal constraints for image view
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.comicImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.comicImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    
    // Vertical constraints for image view
    self.imageViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.comicImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    self.imageViewCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.comicImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    [self.contentView addConstraint:self.imageViewHeightConstraint];
    [self.contentView addConstraint:self.imageViewCenterYConstraint];
}

- (void)updateConstraints
{
    [super updateConstraints];
    
    // Make sure image view is tall enough to cover maxParallaxOffset in both directions
    self.imageViewHeightConstraint.constant = 2 * self.maxParallaxOffset;
}

- (void)setMaxParallaxOffset:(CGFloat)maxParallaxOffset
{
    _maxParallaxOffset = maxParallaxOffset;
    [self setNeedsUpdateConstraints];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    [super applyLayoutAttributes:layoutAttributes];
    
    NSParameterAssert(layoutAttributes != nil);
    NSParameterAssert([layoutAttributes isKindOfClass:[ParallaxLayoutAttributes class]]);

    ParallaxLayoutAttributes *parallaxLayoutAttributes = (ParallaxLayoutAttributes *)layoutAttributes;
    self.imageViewCenterYConstraint.constant = parallaxLayoutAttributes.parallaxOffset.y;
}

@end
