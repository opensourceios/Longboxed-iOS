//
//  LBXIssueDetailViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/19/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXIssueDetailViewController.h"
#import "LBXControllerServices.h"
#import "LBXPublisherDetailViewController.h"
#import "LBXTitleDetailViewController.h"
#import "LBXWeekViewController.h"
#import "LBXClient.h"

#import "UIImageView+LBBlurredImage.h"
#import "UIFont+customFonts.h"
#import "UIImage+ImageEffects.h"
#import "JGActionSheet.h"
#import "LBXLogging.h"
#import "SVProgressHUD.h"

#import <QuartzCore/QuartzCore.h>
#import <JTSImageViewController.h>
#import <UIImageView+AFNetworking.h>

@interface LBXIssueDetailViewController () <JTSImageViewControllerInteractionsDelegate, JTSImageViewControllerDismissalDelegate, JGActionSheetDelegate>

@property (nonatomic) IBOutlet UIImageView *backgroundCoverImageView;
@property (nonatomic) IBOutlet UITextView *descriptionTextView;
@property (nonatomic) IBOutlet UIImageView *coverImageView;
@property (nonatomic) IBOutlet UIButton *imageButton;
@property (nonatomic) IBOutlet UIButton *titleButton;
@property (nonatomic) IBOutlet UILabel *subtitleLabel;
@property (nonatomic) IBOutlet UILabel *distributorCodeLabel;
@property (nonatomic) IBOutlet UILabel *priceLabel;
@property (nonatomic) IBOutlet UIButton *publisherButton;
@property (nonatomic) IBOutlet UIButton *releaseDateButton;

@property (nonatomic, copy) UIImageView *latestIssueForTitleImageView;
@property (nonatomic, copy) UIImage *issueImage;

@end

@implementation LBXIssueDetailViewController

BOOL saveSheetVisible;

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
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar.backItem.backBarButtonItem setImageInsets:UIEdgeInsetsMake(40, 40, -40, 40)];
    [self.navigationController.navigationBar setBackIndicatorImage:
     [UIImage imageNamed:@"arrow"]];
    [self.navigationController.navigationBar setBackIndicatorTransitionMaskImage:
     [UIImage imageNamed:@"arrow"]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0]}];
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
    [_titleButton setTitle:[NSString stringWithFormat:@"%@ #%@", modifiedTitleString, _issue.issueNumber] forState:UIControlStateNormal];
    [_titleButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    _subtitleLabel.text = _issue.subtitle;
    if (_issue.subtitle) {
        NSString *modifiedSubtitleString = [regex stringByReplacingMatchesInString:_issue.subtitle options:0 range:NSMakeRange(0, [_issue.subtitle length]) withTemplate:@""];
        _subtitleLabel.text = modifiedSubtitleString;
    }
    _distributorCodeLabel.text = _issue.diamondID;
    _priceLabel.text = [NSString stringWithFormat:@"$%.02f", [_issue.price floatValue]];
    [_publisherButton setTitle:_issue.publisher.name
                      forState:UIControlStateNormal];
    [_releaseDateButton setTitle:[LBXControllerServices localTimeZoneStringWithDate:_issue.releaseDate]
                        forState:UIControlStateNormal];
    
    [_publisherButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_releaseDateButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _titleButton.tag = 3;
    _publisherButton.tag = 1;
    _releaseDateButton.tag = 2;
    
    if (!_issue.releaseDate) {
        [_releaseDateButton setTitle:@"UNKNOWN" forState:UIControlStateNormal];
        _releaseDateButton.userInteractionEnabled = NO;
        _releaseDateButton.tintColor = [UIColor whiteColor];
        [_releaseDateButton setImage:nil forState:UIControlStateNormal];
    }
    if (!_issue.price) {
        _priceLabel.text = @"UNKNOWN";
    }
    if (!_issue.publisher.name) {
        [_publisherButton setTitle:@"UNKNOWN" forState:UIControlStateNormal];
        _publisherButton.userInteractionEnabled = NO;
        _publisherButton.tintColor = [UIColor whiteColor];
        [_publisherButton setImage:nil forState:UIControlStateNormal];
    }
    if (!_issue.diamondID) {
        _distributorCodeLabel.text = @"UNKNOWN";
    }
    
    // Move the arrow so it is on the right side of the publisher text
    _publisherButton.titleEdgeInsets = UIEdgeInsetsMake(0, -_publisherButton.imageView.frame.size.width, 0, _publisherButton.imageView.frame.size.width);
    _publisherButton.imageEdgeInsets = UIEdgeInsetsMake(0, _publisherButton.titleLabel.frame.size.width + 8, 0, -_publisherButton.titleLabel.frame.size.width);
    _releaseDateButton.titleEdgeInsets = UIEdgeInsetsMake(0, -_releaseDateButton.imageView.frame.size.width, 0, _releaseDateButton.imageView.frame.size.width);
    _releaseDateButton.imageEdgeInsets = UIEdgeInsetsMake(0, _releaseDateButton.titleLabel.frame.size.width + 8, 0, -_releaseDateButton.titleLabel.frame.size.width);
    
    [_publisherButton setTitleColor:[UIColor lightGrayColor]
                           forState:UIControlStateHighlighted];
    [_releaseDateButton setTitleColor:[UIColor lightGrayColor]
                             forState:UIControlStateHighlighted];
    
    NSString *modifiedDescriptionString = [regex stringByReplacingMatchesInString:_issue.issueDescription options:0 range:NSMakeRange(0, [_issue.issueDescription length]) withTemplate:@""];
    _descriptionTextView.text = modifiedDescriptionString;
    _descriptionTextView.selectable = NO;
    [_descriptionTextView scrollRangeToVisible:NSMakeRange(0, 0)]; // Scroll to the top
    
    [_imageButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _imageButton.tag = 0;
    
    _latestIssueForTitleImageView = [UIImageView new];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [LBXLogging logMessage:[NSString stringWithFormat:@"LBXIssue\n%@\ndid appear", _issue]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.topItem.title = @" ";
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (IBAction)buttonPressed:(UIButton *)sender
{
    UIButton *button = (UIButton *)sender;
    
    switch ([button tag]) {
        case 0:
        {
            // Create image info
            JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
            imageInfo.image = _issueImage;
            imageInfo.referenceRect = _imageButton.frame;
            imageInfo.referenceView = _imageButton.superview;
            
            // Setup view controller
            JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                                   initWithImageInfo:imageInfo
                                                   mode:JTSImageViewControllerMode_Image
                                                   backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred];
            imageViewer.interactionsDelegate = self;
            imageViewer.dismissalDelegate = self;
            
            // Present the view controller.
            [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
            
            
            break;
        }
        case 1:
        {
            LBXPublisherDetailViewController *publisherViewController = [LBXPublisherDetailViewController new];
            
            publisherViewController.publisherID = _issue.publisher.publisherID;
            
            [self.navigationController pushViewController:publisherViewController animated:YES];
            break;
        }
        case 2:
        {
            // Pressing the date in the issue view
            LBXWeekViewController *controller = [[LBXWeekViewController alloc] initWithDate:[NSDate dateWithTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT] sinceDate:_issue.releaseDate] andShowThisAndNextWeek:NO];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case 3: // Title button
        {
            LBXTitleDetailViewController *titleViewController = [[LBXTitleDetailViewController alloc] initWithTitle:_issue.title andTopViewFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * 3/4)];
            [LBXLogging logMessage:[NSString stringWithFormat:@"Selected title: %@", _issue.title.description]];
            titleViewController.titleID = _issue.title.titleID;
            titleViewController.latestIssueImage = [UIImage imageNamed:@"black"];
            [self.navigationController pushViewController:titleViewController animated:YES];
        }
    }
}

#pragma mark JTSImageViewControllerInteractionsDelegate methods

- (void)imageViewerDidLongPress:(JTSImageViewController *)imageViewer atRect:(CGRect)rect
{
    if (!saveSheetVisible) {
        JGActionSheetSection *section1 = [JGActionSheetSection sectionWithTitle:nil message:nil buttonTitles:@[@"Save Image", @"Copy Image"] buttonStyle:JGActionSheetButtonStyleDefault];
        JGActionSheetSection *cancelSection = [JGActionSheetSection sectionWithTitle:nil message:nil buttonTitles:@[@"Cancel"] buttonStyle:JGActionSheetButtonStyleCancel];
        
        NSArray *sections = @[section1, cancelSection];
        
        JGActionSheet *sheet = [JGActionSheet actionSheetWithSections:sections];
        sheet.delegate = self;
        
        [sheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
            [sheet dismissAnimated:YES];
            saveSheetVisible = NO;
        }];
        saveSheetVisible = YES;
        [sheet showInView:imageViewer.view animated:YES];
    }
}

- (BOOL)imageViewerShouldTemporarilyIgnoreTouches:(JTSImageViewController *)imageViewer
{
    if (saveSheetVisible) return YES;
    return NO;
}

#pragma mark JTSImageViewControllerDismissalDelegate methods

// Sometimes the status bar will go to black text. This changes it white
- (void)imageViewerDidDismiss:(JTSImageViewController *)imageViewer
{
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
}

#pragma mark JGActionSheetDelegate methods

- (void)actionSheet:(JGActionSheet *)actionSheet pressedButtonAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                {
                    UIImageWriteToSavedPhotosAlbum(_issueImage, nil, nil, nil);
                    break;
                }
                case 1:
                {
                    [LBXControllerServices copyImageToPasteboard:_issueImage];
                    break;
                }
                default:
                    break;
            }
            break;
        default:
            break;
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
    UIImage *blurredImage = _issueImage;
    [blurredImage applyDarkEffect];
    
    blurredImage = [blurredImage applyBlurWithRadius:0.0
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
