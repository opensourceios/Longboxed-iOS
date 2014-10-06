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
#import "LBXClient.h"

#import <UIImageView+AFNetworking.h>

CGFloat const kMGOffsetEffects = 40.0;
CGFloat const kMGOffsetBlurEffect = 2.0;

@implementation MGSpotyViewController {
    CGPoint _startContentOffset;
    CGPoint _lastContentOffsetBlurEffect;
    CGRect _frameRect;
}

- (instancetype)initWithMainImage:(UIImage *)image andTopViewFrame:(CGRect)frame
{
    if(self = [super init]) {
        _foregroundImage = [image copy];
        _backgroundImage = [image copy];
        _mainImageView = [UIImageView new];
        [_mainImageView setImage:_foregroundImage];
        _overView = [UIView new];
        _tableView = [UITableView new];
        _frameRect = frame;
    }
    
    return self;
}

- (instancetype)initWithTitle:(LBXTitle *)title andTopViewFrame:(CGRect)frame
{
    if(self = [super init]) {
        _foregroundImage = [UIImage imageNamed:@"black"];
        _backgroundImage = [UIImage imageNamed:@"black"];
        [_mainImageView setImageToBlur:_backgroundImage blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:nil];
        [self getLatestIssueImageForTitle:title withCompletion:^(UIImage *image) {
            _foregroundImage = image;
            _backgroundImage = image;
            //[_mainImageView setImage:_foregroundImage];
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
        _frameRect = frame;
    }
    
    return self;
}

- (instancetype)initWithTopViewFrame:(CGRect)frame
{
    if(self = [super init]) {
        UIColor *color = [UIColor blackColor];
        CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSetFillColorWithColor(context, [color CGColor]);
        CGContextFillRect(context, rect);
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        _backgroundImage = image;
        _foregroundImage = image;
        _mainImageView = [UIImageView new];
        [_mainImageView setImage:_foregroundImage];
        _overView = [UIView new];
        _tableView = [UITableView new];
        _frameRect = frame;
    }
    
    return self;
}

- (void)loadView
{
    //Create the view
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    view.backgroundColor = [UIColor whiteColor];
    
    [_mainImageView setFrame:_frameRect];
    [_mainImageView setContentMode:UIViewContentModeScaleAspectFill];
    if (_backgroundImage) [_mainImageView setImageToBlur:_backgroundImage blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:nil];
    [view addSubview:_mainImageView];

    [_overView setFrame:_mainImageView.bounds];
    [_overView setBackgroundColor:[UIColor clearColor]];
    [view addSubview:_overView];
    
    [_tableView setFrame:view.frame];
    [_tableView setShowsVerticalScrollIndicator:YES];
    [_tableView setBackgroundColor:[UIColor clearColor]];
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
    [view insertSubview:_tableView belowSubview:_overView];
    
    //[_tableView setContentInset:UIEdgeInsetsMake(20.0, 0, 0, 0)];
    _startContentOffset = _tableView.contentOffset;
    _lastContentOffsetBlurEffect = _startContentOffset;
    
    // +18 for the height of the header
    _whiteView = [[UIView alloc] initWithFrame:CGRectMake(_overView.frame.origin.x, _overView.frame.size.height + 18, _overView.bounds.size.width, view.frame.size.height - _overView.frame.size.height)];
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
                [imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:((LBXIssue *)issueArray[0]).coverImage]] placeholderImage:[UIImage imageNamed:@"loadingCoverTransparent"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    
                    completion(image);
                    
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                    completion([UIImage imageNamed:@"NotAvailable.jpeg"]);

                }];
            }
            else completion([UIImage imageNamed:@"NotAvailable.jpeg"]);
        }
        else {
            completion([UIImage imageNamed:@"NotAvailable.jpeg"]);
            //[LBXMessageBar displayError:error];
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
    [UIView transitionWithView:_mainImageView
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        _mainImageView.image = image;
                    }
                    completion:NULL];
    
    _backgroundImage = image;

    // Adjustment for images with a height that is less than _mainImageView
    if (image.size.height < _frameRect.size.height) {
        int verticalAdjustment = _frameRect.size.height + image.size.height;
        _mainImageView.frame = CGRectMake(0,  -verticalAdjustment, _frameRect.size.width, _frameRect.size.height+verticalAdjustment);
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
        //Image size effects
        CGFloat absoluteY = ABS(scrollView.contentOffset.y);
        CGFloat diff = _startContentOffset.y - scrollView.contentOffset.y;

        // Adjustment for images with a height that is less than _mainImageView
        int verticalAdjustment = 0;
        if (_mainImageView.image.size.height < _overView.frame.size.height) {
            verticalAdjustment = _overView.frame.size.height + _mainImageView.image.size.height;
        }
        
        [_mainImageView setFrame:CGRectMake(0.0 - diff/2.0, (_frameRect.size.height - self.view.frame.size.width)/2 - verticalAdjustment, _overView.frame.size.width + absoluteY, _overView.frame.size.width + absoluteY + verticalAdjustment)];
        [_overView setFrame:CGRectMake(0.0, 0.0+absoluteY, _overView.frame.size.width, _overView.frame.size.height)];
        // +18 for the height of the header
        _whiteView.frame = CGRectMake(_overView.frame.origin.x, _overView.frame.size.height + 18 + absoluteY, _overView.bounds.size.width, self.view.frame.size.height - _overView.frame.size.height);
        
        
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
        [self.view bringSubviewToFront:_tableView];
        CGFloat diff =  scrollView.contentOffset.y- _startContentOffset.y-80;
        CGFloat scale = (kLBBlurredImageDefaultBlurRadius/kMGOffsetEffects) / 55;
        [_overView setAlpha:1.0 - diff*scale];
        
    }
    if (scrollView.contentOffset.y > _startContentOffset.y + 18) {
        [self.view bringSubviewToFront:_tableView];
        CGFloat diff =  scrollView.contentOffset.y- _startContentOffset.y-18;
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
        [self.view bringSubviewToFront:_overView];
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
        UIView *transparentView = [[UIView alloc] initWithFrame:_overView.bounds];
        [transparentView setBackgroundColor:[UIColor clearColor]];
        return transparentView;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return _overView.frame.size.height;
    
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
