//
//  LBXIssueDetailViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/19/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXIssueDetailViewController.h"
#import "LBXTitleServices.h"
#import "LBXPublisherDetailViewController.h"

#import "UIImageView+LBBlurredImage.h"
#import "UIFont+customFonts.h"
#import "UIImage+ImageEffects.h"
#import "JTSImageViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <UIImageView+AFNetworking.h>
#import <GPUImage.h>

@interface LBXIssueDetailViewController ()

@property (nonatomic) IBOutlet UIImageView *backgroundCoverImageView;
@property (nonatomic) IBOutlet UITextView *descriptionTextView;
@property (nonatomic) IBOutlet UIImageView *coverImageView;
@property (nonatomic) IBOutlet UIButton *imageButton;
@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutlet UILabel *subtitleLabel;
@property (nonatomic) IBOutlet UILabel *distributorCodeLabel;
@property (nonatomic) IBOutlet UILabel *priceLabel;
@property (nonatomic) IBOutlet UIButton *publisherButton;
@property (nonatomic) IBOutlet UIButton *releaseDateButton;

@property (nonatomic, copy) UIImage *issueImage;

@end

@implementation LBXIssueDetailViewController

- (instancetype)initWithMainImage:(UIImage *)image {
    if(self = [super init]) {
        _issueImage = [image copy];
        _backgroundCoverImageView = [UIImageView new];
        _descriptionTextView = [UITextView new];
        _coverImageView = [UIImageView new];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame andIssue:(LBXIssue *)issue {
    if(self = [super init]) {
        _backgroundCoverImageView = [UIImageView new];
        _descriptionTextView = [UITextView new];
        _coverImageView = [UIImageView new];
        _issue = issue;
        self.view.frame = frame;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];


    
//    NSManagedObjectContext *privateContext = [NSManagedObjectContext MR_context];
//    [privateContext performBlock:^{
//        // Execute your fetch
//
//        // Return to our main thread
//        dispatch_async(dispatch_get_main_queue(), ^{
//        });
//    }];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_issueImage == nil) {
        _issueImage = [UIImage new];
        [self setupImageViews];
    }
    [self setupImages];
    
    [_coverImageView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_coverImageView(==%d)]", (int)self.view.frame.size.height/2]
                                                                            options:0
                                                                            metrics:nil
                                                                              views:NSDictionaryOfVariableBindings(_coverImageView)]];
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"&#?[a-zA-Z0-9z]+;" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSString *modifiedTitleString = [regex stringByReplacingMatchesInString:_issue.title.name options:0 range:NSMakeRange(0, [_issue.title.name length]) withTemplate:@""];
    _titleLabel.text = [NSString stringWithFormat:@"%@ #%@", modifiedTitleString, _issue.issueNumber];
    
    _subtitleLabel.text = _issue.subtitle;
    if (_issue.subtitle) {
        NSString *modifiedSubtitleString = [regex stringByReplacingMatchesInString:_issue.subtitle options:0 range:NSMakeRange(0, [_issue.subtitle length]) withTemplate:@""];
        _subtitleLabel.text = modifiedSubtitleString;
    }
    _distributorCodeLabel.text = _issue.diamondID;
    _priceLabel.text = [NSString stringWithFormat:@"$%.02f", [_issue.price floatValue]];
    [_publisherButton setTitle:_issue.publisher.name
                      forState:UIControlStateNormal];
    [_releaseDateButton setTitle:[LBXTitleServices localTimeZoneStringWithDate:_issue.releaseDate]
                        forState:UIControlStateNormal];
    
    // Move the arrow so it is on the right side of the publisher text
    _publisherButton.titleEdgeInsets = UIEdgeInsetsMake(0, -_publisherButton.imageView.frame.size.width, 0, _publisherButton.imageView.frame.size.width);
    _publisherButton.imageEdgeInsets = UIEdgeInsetsMake(0, _publisherButton.titleLabel.frame.size.width + 8, 0, -_publisherButton.titleLabel.frame.size.width);
    _releaseDateButton.titleEdgeInsets = UIEdgeInsetsMake(0, -_releaseDateButton.imageView.frame.size.width, 0, _releaseDateButton.imageView.frame.size.width);
    _releaseDateButton.imageEdgeInsets = UIEdgeInsetsMake(0, _releaseDateButton.titleLabel.frame.size.width + 8, 0, -_releaseDateButton.titleLabel.frame.size.width);
    
    [_publisherButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_releaseDateButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _publisherButton.tag = 1;
    _releaseDateButton.tag = 2;
    
    if (!_issue.releaseDate) {
        [_releaseDateButton setTitle:@"UNKNOWN" forState:UIControlStateNormal];
        _releaseDateButton.userInteractionEnabled = NO;
        _releaseDateButton.tintColor = [UIColor whiteColor];
    }
    if (!_issue.price) {
        _priceLabel.text = @"UNKNOWN";
    }
    if (!_issue.publisher.name) {
        [_publisherButton setTitle:@"UNKNOWN" forState:UIControlStateNormal];
        _publisherButton.userInteractionEnabled = NO;
        _publisherButton.tintColor = [UIColor whiteColor];
    }
    if (!_issue.diamondID) {
        _distributorCodeLabel.text = @"UNKNOWN";
    }
    
    NSString *modifiedDescriptionString = [regex stringByReplacingMatchesInString:_issue.issueDescription options:0 range:NSMakeRange(0, [_issue.issueDescription length]) withTemplate:@""];
    _descriptionTextView.text = modifiedDescriptionString;
    _descriptionTextView.selectable = NO;
    [_descriptionTextView scrollRangeToVisible:NSMakeRange(0, 0)]; // Scroll to the top
    
    [_imageButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _imageButton.tag = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"MEMORY WARNING IN ISSUE DETAIL VIEW CONTROLLER!");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.topItem.title = @" ";
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (IBAction)buttonPressed:(UIButton *)sender
{
    UIButton *button = (UIButton *)sender;
    
    switch ([button tag]) {
        case 0:
        {
            // Create image info
            JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
            imageInfo.image = _coverImageView.image;
            imageInfo.referenceRect = _imageButton.frame;
            imageInfo.referenceView = _imageButton.superview;
            
            // Setup view controller
            JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                                   initWithImageInfo:imageInfo
                                                   mode:JTSImageViewControllerMode_Image
                                                   backgroundStyle:JTSImageViewControllerBackgroundStyle_ScaledDimmedBlurred];
            
            // Present the view controller.
            [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
            
            break;
        }
        case 1:
        {
            LBXPublisherDetailViewController *publisherViewController = [[LBXPublisherDetailViewController alloc] initWithMainImage:_coverImageView.image andTopViewFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * 3/8)];
            
            publisherViewController.publisherID = _issue.publisher.publisherID;
            publisherViewController.publisherImage = _coverImageView.image;
            
            [self.navigationController pushViewController:publisherViewController animated:YES];
            break;
        }
        case 2:
        {
            NSLog(@"Pressed date in issue view");
            break;
        }
    }
}

#pragma mark Private Methods

- (void)setupImageViews
{
    UIImageView *imageView = [UIImageView new];
    // Get the image from the URL and set it
    [imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_issue.coverImage]] placeholderImage:[UIImage imageNamed:@"loadingCoverTransparent"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
        _issueImage = image;
        [self setupImages];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
        _issueImage = [UIImage imageNamed:@"NotAvailable.jpeg"];
        [self setupImages];
        
    }];
}


- (void)setupImages
{
    _coverImageView.alpha = 0.0;
    _backgroundCoverImageView.alpha = 0.0;
    [_backgroundCoverImageView setImageToBlur:_issueImage blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:nil];
    [_issueImage applyDarkEffect];
    
    UIImage *blurredImage = [_issueImage applyBlurWithRadius:0.0
                                                   tintColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3]
                                       saturationDeltaFactor:0.5
                                                   maskImage:nil];
    
    [_coverImageView setImage:blurredImage];
    [_coverImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [UIView transitionWithView:_backgroundCoverImageView
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        _backgroundCoverImageView.alpha = 1.0;
                    } completion:nil];
    [UIView transitionWithView:_coverImageView
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        _coverImageView.alpha = 1.0;
                    } completion:nil];

}

@end
