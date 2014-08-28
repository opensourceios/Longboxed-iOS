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

#import <UIImageView+AFNetworking.h>

CGFloat const kMGOffsetEffects = 40.0;
CGFloat const kMGOffsetBlurEffect = 2.0;

@interface MGSpotyViewController ()

@property (nonatomic) UIImage *image;

@end

@implementation MGSpotyViewController {
    CGPoint _startContentOffset;
    CGPoint _lastContentOffsetBlurEffect;
    NSString *_URLString;
    CGRect _frameRect;
}

- (instancetype)initWithMainImage:(UIImage *)image andTopViewFrame:(CGRect)frame
{
    if(self = [super init]) {
        _image = [image copy];
        _mainImageView = [UIImageView new];
        [_mainImageView setImage:_image];
        _overView = [UIView new];
        _tableView = [UITableView new];
        _frameRect = frame;
    }
    
    return self;
}

- (instancetype)initWithMainImageURL:(NSString *)urlString andTopViewFrame:(CGRect)frame
{
    if(self = [super init]) {
        UIColor *color = [UIColor lightGrayColor];
        CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSetFillColorWithColor(context, [color CGColor]);
        CGContextFillRect(context, rect);
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        _image = image;
        _mainImageView = [UIImageView new];
        _URLString = urlString;
        [_mainImageView setImage:_image];
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
    
    [_mainImageView setFrame:_frameRect];
    NSLog(@"%f", _mainImageView.frame.size.width);
    NSLog(@"%f", _mainImageView.frame.size.height);
    NSLog(@"%f", _frameRect.size.width);
    NSLog(@"%f", _frameRect.size.height);
    [_mainImageView setContentMode:UIViewContentModeScaleAspectFill];
    [_mainImageView setImageToBlur:_image blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:nil];
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
    
    //Set the view
    self.view = view;
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

- (void)setBlurImageViewFrame:(CGRect)frame
{
    [_mainImageView setFrame:frame];
}

- (UIImage *)blurImageView:(UIImageView *)imageView withImage:(UIImage *)image
{
    [imageView setImageToBlur:image blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:nil];
    _image = image;
    return imageView.image;
}


#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(scrollView.contentOffset.y <= _startContentOffset.y) {
        //Image size effects
        CGFloat absoluteY = ABS(scrollView.contentOffset.y);
        CGFloat diff = _startContentOffset.y - scrollView.contentOffset.y;

        [_mainImageView setFrame:CGRectMake(0.0-diff/2.0, (_frameRect.size.height-self.view.frame.size.width)/2, _overView.frame.size.width+absoluteY, _overView.frame.size.width+absoluteY)];
        [_overView setFrame:CGRectMake(0.0, 0.0+absoluteY, _overView.frame.size.width, _overView.frame.size.height)];
        
        if(scrollView.contentOffset.y < _startContentOffset.y-kMGOffsetEffects) {
            diff = kMGOffsetEffects;
        }
        
        //Image blur effects
        CGFloat scale = kLBBlurredImageDefaultBlurRadius/kMGOffsetEffects;
        CGFloat newBlur = kLBBlurredImageDefaultBlurRadius - diff*scale;
        
        __block typeof (_overView) overView = _overView;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //Blur effects
            if(ABS(_lastContentOffsetBlurEffect.y-scrollView.contentOffset.y) >= kMGOffsetBlurEffect) {
                _lastContentOffsetBlurEffect = scrollView.contentOffset;
                [_mainImageView setImageToBlur:_image blurRadius:newBlur completionBlock:nil];
            }
            
            //Opacity overView
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
        [cell setBackgroundColor:[UIColor darkGrayColor]];
        [cell.textLabel setTextColor:[UIColor whiteColor]];
    }
    
    [cell.textLabel setText:@"Cell"];
    
    return cell;
}



@end
