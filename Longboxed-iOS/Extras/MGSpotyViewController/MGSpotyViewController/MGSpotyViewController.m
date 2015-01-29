//
//  MGSpotyViewController.m
//  MGSpotyView
//
//  Created by Matteo Gobbi on 25/06/2014.
//  Copyright (c) 2014 Matteo Gobbi. All rights reserved.
//

#import "MGSpotyViewController.h"
#import "UIImageView+LBBlurredImage.h"
#import "LBXTitleDetailView.h"
#import "LBXControllerServices.h"
#import "LBXClient.h"
#import "PaintCodeImages.h"

#import "UIImage+LBXCreateImage.h"

#import <UIImageView+AFNetworking.h>
#import "UIFont+LBXCustomFonts.h"

CGFloat const kMGOffsetEffects = 40.0;
CGFloat const kMGOffsetBlurEffect = 2.0;

@implementation MGSpotyViewController {
    CGPoint _startContentOffset;
    CGPoint _lastContentOffsetBlurEffect;
}

- (instancetype)initWithTitle:(LBXTitle *)title
{
    if(self = [super init]) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setFrameAgain)
                                                     name:@"setFrameAgain"
                                                   object:nil];
        
        _foregroundImage = [UIImage imageNamed:@"black"];
        _backgroundImage = [UIImage imageNamed:@"black"];
        [_mainImageView setImageToBlur:_backgroundImage blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:nil];
        [self getLatestIssueImageForTitle:title withCompletion:^(UIImage *image) {
            if ([UIImagePNGRepresentation(image) isEqual:UIImagePNGRepresentation([UIImage defaultCoverImage])]) {
                _foregroundImage = [UIImage defaultCoverImageWithWhiteBackground];
                _backgroundImage = [UIImage imageNamed:@"black"];
            }
            else {
                _foregroundImage = image;
                _backgroundImage = [image copy];
            }
        
            UIImageView *imageView = [UIImageView new];
            __block typeof(imageView) bImageView = imageView;
            __block typeof(self) bself = self;
            [imageView setImageToBlur:_backgroundImage blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:^ {
                [UIView transitionWithView:_mainImageView
                                  duration:0.3f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    bself.mainImageView.image = bImageView.image;
                                } completion:nil];
                
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"setTitleDetailForegroundImage"
                 object:self userInfo:nil];
            }];
        }];
        
        _mainImageView = [UIImageView new];
        _overView = [UIView new];
        _tableView = [UITableView new];
    }
    
    return self;
}

- (void)setFrameAgain
{
    [_mainImageView setFrame:CGRectMake(0, 0, _frameRect.size.width, _frameRect.size.height)];
    if (_backgroundImage) [_mainImageView setImageToBlur:_backgroundImage blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:nil];
    [_overView setFrame:CGRectMake(_mainImageView.bounds.origin.x, _mainImageView.bounds.origin.y, _mainImageView.frame.size.width, _mainImageView.frame.size.height + self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height)];
    [_whiteView setFrame:CGRectMake(_overView.frame.origin.x, _overView.frame.size.height, _overView.bounds.size.width, self.view.frame.size.height - _overView.frame.size.height)];
    
    [self.view setNeedsLayout];
}

- (void)loadView
{
    //Create the view
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].origin.x, [[UIScreen mainScreen] bounds].origin.y , [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    view.backgroundColor = [UIColor whiteColor];
    
    [_mainImageView setFrame:CGRectMake(0, 0, _frameRect.size.width, _frameRect.size.height)];
    [_mainImageView setContentMode:UIViewContentModeScaleAspectFill];
    if (_backgroundImage) [_mainImageView setImageToBlur:_backgroundImage blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:nil];
    [view addSubview:_mainImageView];

    [_overView setFrame:_mainImageView.bounds];
    [_overView setBounds:CGRectMake(_mainImageView.bounds.origin.x, _mainImageView.bounds.origin.y, _mainImageView.frame.size.width, _mainImageView.frame.size.height)];
    [view addSubview:_overView];
    
    [_tableView setFrame:CGRectMake([[UIScreen mainScreen] bounds].origin.x, self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height - self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height)];
    _startContentOffset = _tableView.contentOffset;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.navigationController.navigationBar.frame.size.height - 4, 0);
    
    [_tableView setShowsVerticalScrollIndicator:YES];
    [_tableView setBackgroundColor:[UIColor clearColor]];
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
    [view insertSubview:_tableView belowSubview:_overView];

    _whiteView = [[UIView alloc] initWithFrame:CGRectMake(_overView.frame.origin.x, _overView.frame.size.height + self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height, _overView.bounds.size.width, view.frame.size.height - _overView.frame.size.height)];
    [_whiteView setBackgroundColor:[UIColor whiteColor]];
    [view insertSubview:_whiteView belowSubview:_tableView];
    
    //Set the view
    self.view = view;
}

- (void)getLatestIssueImageForTitle:(LBXTitle *)title withCompletion:(void (^)(UIImage *))completion
{
    UIImageView *imageView = [UIImageView new];
    LBXClient *client = [LBXClient new];
    [client fetchIssuesForTitle:title.titleID page:@1 count:@1 withCompletion:^(NSArray *issueArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            if (issueArray.count) {
                for (LBXIssue *issue in issueArray) {
                    if ([issue.isParent isEqualToNumber:@1]) {
                        [imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[UIImage defaultCoverImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                            completion(image);
                            
                        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                            completion([UIImage defaultCoverImage]);
                        }];
                        return;
                    }
                }
            }
            else completion([UIImage defaultCoverImage]);
        }
        else {
            completion([UIImage defaultCoverImage]);
        }
    }];
}

- (void)setCustomBackgroundImageWithImage:(UIImage *)image
{
    [UIView transitionWithView:_mainImageView
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        _mainImageView.image = image;
                    }
                    completion:NULL];
    
    _backgroundImage = image;
}

- (void)setCustomBlurredBackgroundImageWithImage:(UIImage *)image
{
    _backgroundImage = image;

    // Adjustment for images with a height that is less than _mainImageView
    if (image.size.height < _frameRect.size.height) {
        int verticalAdjustment = (self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height);
        _mainImageView.frame = CGRectMake(0,  -verticalAdjustment + self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height, _frameRect.size.width, _frameRect.size.height+verticalAdjustment);
        _mainImageView.clipsToBounds = YES;
        
    }
    [_mainImageView setImageToBlur:_backgroundImage blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:nil];
}

- (void)setCustomForegroundImageWithImage:(UIImage *)image
{
    _foregroundImage = image;
}

#pragma mark - Properties Methods

- (void)setOverView:(UIView *)overView {
    static NSUInteger subviewTag = 100;
    UIView *subView = [overView viewWithTag:subviewTag];
    
    if(![subView isEqual:overView]) {
        [subView removeFromSuperview];
        [_overView addSubview:overView];
    }
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(scrollView.contentOffset.y <= _startContentOffset.y) {
        // Image size effects
        CGFloat absoluteY = ABS(scrollView.contentOffset.y);
        CGFloat diff = _startContentOffset.y - scrollView.contentOffset.y;

        // Adjustment for images with a height that is less than _mainImageView
        CGFloat verticalAdjustment = (self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height);
        
        [_mainImageView setFrame:CGRectMake(0.0 - diff/2.0, 0, _overView.frame.size.width + absoluteY, _overView.frame.size.width + absoluteY + verticalAdjustment)];
        [_overView setFrame:CGRectMake(0.0, 0.0+absoluteY, _overView.frame.size.width, _overView.frame.size.height)];
        // +18 for the height of the header
        _whiteView.frame = CGRectMake(_overView.frame.origin.x, _overView.frame.size.height + absoluteY, _overView.bounds.size.width, self.view.frame.size.height - _overView.frame.size.height);
        
        
        if(scrollView.contentOffset.y < _startContentOffset.y-kMGOffsetEffects) {
            diff = kMGOffsetEffects;
        }
        
        // Image blur effects
        CGFloat scale = kLBBlurredImageDefaultBlurRadius/kMGOffsetEffects;
        CGFloat newBlur = kLBBlurredImageDefaultBlurRadius - diff*scale;
        
        __block typeof (_overView) overView = _overView;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Blur effects
            if(ABS(_lastContentOffsetBlurEffect.y-scrollView.contentOffset.y) >= kMGOffsetBlurEffect) {
                _lastContentOffsetBlurEffect = scrollView.contentOffset;
                [_mainImageView setImageToBlur:_backgroundImage blurRadius:newBlur completionBlock:nil];
            }
            
            // Opacity overView
            CGFloat scale = 1.0/kMGOffsetEffects;
            [overView setAlpha:1.0 - diff*scale];
        });
    }
    if (scrollView.contentOffset.y > _startContentOffset.y + 80) {
        [self.view insertSubview:_tableView aboveSubview:_overView];
        CGFloat diff =  scrollView.contentOffset.y - _startContentOffset.y-80;
        CGFloat scale = (kLBBlurredImageDefaultBlurRadius/kMGOffsetEffects) / 55;
        [_overView setAlpha:1.0 - diff*scale];
        
    }
    if (scrollView.contentOffset.y > _startContentOffset.y + 18) {
        [self.view insertSubview:_tableView aboveSubview:_overView];
        CGFloat diff =  scrollView.contentOffset.y - _startContentOffset.y-18;
        CGFloat scale = (kLBBlurredImageDefaultBlurRadius/kMGOffsetEffects) / 25;
        for (UIView *subView in _overView.subviews) {
            if ([subView isKindOfClass:[LBXTitleDetailView class]]) {
                for (UIView *subSubView in subView.subviews) {
                    if ([subSubView isKindOfClass:[UIButton class]]) {
                        UIButton *button = (UIButton *)subSubView;
                        if (button.subviews.count != 2) {
                            subSubView.hidden = NO;
                            UIButton *label = (UIButton *)subSubView;
                            [label setAlpha:1.0 - diff*scale];
                        }
                        
                    }
                }
            }
        }
    }
    else {
        [self.view insertSubview:_overView aboveSubview:_tableView];
        for (UIView *subView in _overView.subviews) {
            if ([subView isKindOfClass:[LBXTitleDetailView class]]) {
                for (UIView *subSubView in subView.subviews) {
                    if ([subSubView isKindOfClass:[UIButton class]]) {
                        UIButton *button = (UIButton *)subSubView;
                        if (button.subviews.count != 2) {
                            subSubView.hidden = NO;
                            UIButton *label = (UIButton *)subSubView;
                            [label setAlpha:1.0];
                        }
                    }
                }
            }
        }
    }
}


#pragma mark - UITableView Delegate & Datasource

/* To override */

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        UIView *transparentView = [[UIView alloc] initWithFrame:CGRectMake(_overView.frame.origin.x, _overView.frame.origin.y - (self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height), _overView.frame.size.width, _overView.frame.size.height)];
        [transparentView setBackgroundColor:[UIColor clearColor]];
        return transparentView;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return _overView.frame.size.height - (self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height);
    
    return 0.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 1)
        return 20;
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"CellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        [cell setBackgroundColor:[UIColor whiteColor]];
        [cell.textLabel setTextColor:[UIColor whiteColor]];
    }
    
    [cell.textLabel setText:@"Cell"];
    
    return cell;
}



@end
