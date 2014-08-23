//
//  LBXIssueDetailViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/19/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXIssueDetailViewController.h"
#import "LBXTitleServices.h"

#import "UIImageView+LBBlurredImage.h"
#import "UIFont+customFonts.h"
#import "UIImage+ImageEffects.h"
#import "PaperButton.h"
#import "JTSImageViewController.h"

#import <FontAwesomeKit/FontAwesomeKit.h>
#import <QuartzCore/QuartzCore.h>
#import <UIImageView+AFNetworking.h>

@interface LBXIssueDetailViewController ()

@property (nonatomic) IBOutlet UIImageView *backgroundCoverImageView;
@property (nonatomic) IBOutlet UITextView *descriptionTextView;
@property (nonatomic) IBOutlet UIImageView *coverImageView;
@property (nonatomic) IBOutlet UIButton *imageButton;
@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutlet UILabel *subtitleLabel;
@property (nonatomic) IBOutlet UILabel *distributorCodeLabel;
@property (nonatomic) IBOutlet UILabel *priceLabel;
@property (nonatomic) IBOutlet UILabel *publisherLabel;
@property (nonatomic) IBOutlet UILabel *releaseDateLabel;

@property (nonatomic) NSArray *alternates;
@property (nonatomic) PaperButton *closeButton;
@property (nonatomic, copy) UIImage *issueImage;
@property (nonatomic, copy) LBXIssue *issue;

@end

@implementation LBXIssueDetailViewController

- (instancetype)initWithMainImage:(UIImage *)image andAlternates:(NSArray *)alternates {
    if(self = [super init]) {
        _issueImage = [image copy];
        _backgroundCoverImageView = [UIImageView new];
        _descriptionTextView = [UITextView new];
        _coverImageView = [UIImageView new];
        _alternates = alternates;
    }
    return self;
}

- (instancetype)initWithAlternates:(NSArray *)alternates {
    if(self = [super init]) {
        _backgroundCoverImageView = [UIImageView new];
        _descriptionTextView = [UITextView new];
        _coverImageView = [UIImageView new];
        _alternates = alternates;
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
    
    _issue = [LBXIssue MR_findFirstByAttribute:@"issueID" withValue:_issueID];
    NSLog(@"Selected issue %@", _issue.issueID);
    
    if (_issueImage == nil) {
        _issueImage = [UIImage new];
        [self setupImageViews];
    }
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    [self setupImages];
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"&#?[a-zA-Z0-9z]+;" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSString *modifiedTitleString = [regex stringByReplacingMatchesInString:_issue.title.name options:0 range:NSMakeRange(0, [_issue.title.name length]) withTemplate:@""];
    
    _titleLabel.text = [NSString stringWithFormat:@"%@ #%@", modifiedTitleString, _issue.issueNumber];
    _subtitleLabel.text = _issue.subtitle.uppercaseString;
    _distributorCodeLabel.text = _issue.diamondID.uppercaseString;
    _priceLabel.text = [NSString stringWithFormat:@"$%.02f", [_issue.price floatValue]].uppercaseString;
    _publisherLabel.text = _issue.publisher.name.uppercaseString;
    _releaseDateLabel.text = [LBXTitleServices localTimeZoneStringWithDate:_issue.releaseDate].uppercaseString;
    
    if (!_issue.releaseDate) {
        _releaseDateLabel.text = @"UNKNOWN";
    }
    if (!_issue.price) {
        _priceLabel.text = @"UNKNOWN";
    }
    if (!_issue.publisher.name) {
        _priceLabel.text = @"UNKNOWN";
    }
    if (!_issue.diamondID) {
        _priceLabel.text = @"UNKNOWN";
    }
    
    NSString *modifiedDescriptionString = [regex stringByReplacingMatchesInString:_issue.issueDescription options:0 range:NSMakeRange(0, [_issue.issueDescription length]) withTemplate:@""];
    _descriptionTextView.text = modifiedDescriptionString;
    _descriptionTextView.selectable = NO;
    [_descriptionTextView scrollRangeToVisible:NSMakeRange(0, 0)]; // Scroll to the top
    
    [_imageButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _imageButton.tag = 1;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonPressed:(UIButton *)sender
{
    UIButton *button = (UIButton *)sender;
    
    switch ([button tag]) {
        case 1:
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
    }
}

#pragma mark Private Methods

- (void)setupImageViews
{
    UIImageView *imageView = [UIImageView new];
    // Get the image from the URL and set it
    [imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_issue.coverImage]] placeholderImage:[UIImage imageNamed:@"NotAvailable"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
        _issueImage = image;
        [self setupImages];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
        _issueImage = [UIImage imageNamed:@"NotAvailable.jpeg"];
        [self setupImages];
        
    }];
}


- (void)setupImages
{
    [_backgroundCoverImageView setImageToBlur:_issueImage blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:nil];
    [_issueImage applyDarkEffect];
    
    UIImage *blurredImage = [_issueImage applyBlurWithRadius:0.0
                                                   tintColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3]
                                       saturationDeltaFactor:0.5
                                                   maskImage:nil];
    
    [_coverImageView setImage:blurredImage];
    [_coverImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_coverImageView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_coverImageView(==%d)]", (int)self.view.frame.size.height/2]
                                                                            options:0
                                                                            metrics:nil
                                                                              views:NSDictionaryOfVariableBindings(_coverImageView)]];
}

@end
