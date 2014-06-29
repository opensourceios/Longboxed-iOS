//
//  ParallaxPhotoCell.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Jay Hickey. All rights reserved.
//

@import UIKit;

@interface ParallaxPhotoCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UIImageView *comicImageView;
@property (nonatomic, strong, readonly) UILabel *comicTitleLabel;
@property (nonatomic, strong, readonly) UILabel *comicPublisherLabel;
@property (nonatomic, strong, readonly) UILabel *comicIssueLabel;
@property (nonatomic, strong, readonly) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) CGFloat maxParallaxOffset;

@end
