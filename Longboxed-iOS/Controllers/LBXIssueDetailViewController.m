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
#import "PaintCodeImages.h" 
#import "LBXClient.h"

#import "UIImageView+LBBlurredImage.h"
#import "NSString+StringUtilities.h"
#import "UIImage+LBXCreateImage.h"
#import "UIFont+LBXCustomFonts.h"
#import "UIImage+ImageEffects.h"

#import "JGActionSheet.h"
#import "LBXLogging.h"
#import "SVProgressHUD.h"

#import <QuartzCore/QuartzCore.h>
#import <JTSImageViewController.h>
#import <UIImageView+AFNetworking.h>

@interface LBXIssueDetailViewController () <JTSImageViewControllerInteractionsDelegate, JTSImageViewControllerDismissalDelegate>

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
BOOL selectedTitle;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Don't do setup if contained in scroll view (has variant issues)
    if (self.parentViewController) [LBXControllerServices setupTransparentNavigationBarForViewController:self];
    
    if (_issueImage == nil || [UIImagePNGRepresentation(_issueImage) isEqual:UIImagePNGRepresentation([UIImage defaultCoverImage])]) {
        _issueImage = [UIImage new];
        [self setupImageViews];
    }
    [self setupImagesWithImage:_issueImage];
    
    NSString *modifiedTitleString = [NSString regexOutHTMLJunk:_issue.title.name];
    [_titleButton setTitle:[NSString stringWithFormat:@"%@ #%@", modifiedTitleString, _issue.issueNumber] forState:UIControlStateNormal];
    [_titleButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _titleButton.titleLabel.font = [UIFont issueDetailTitleFont];
    
    CGFloat width = [_titleButton.titleLabel.text sizeWithAttributes: @{NSFontAttributeName:[UIFont issueDetailTitleFont]}].width;
    _titleButton.titleLabel.numberOfLines = (width > [UIScreen mainScreen].bounds.size.width-40) ? 2 : 1;
    
    [_titleButton addConstraints:[NSLayoutConstraint
                                  constraintsWithVisualFormat:@"V:[titleButton(titleButtonHeight)]"
                                  options:0
                                  metrics:@{@"titleButtonHeight" : [NSNumber numberWithDouble:_titleButton.frame.size.height * (_titleButton.titleLabel.numberOfLines *0.7)]}
                                  views:@{@"titleButton" : _titleButton}]];
    
    _titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    _subtitleLabel.text = _issue.subtitle;
    if (_issue.subtitle) {
        NSString *modifiedSubtitleString = [NSString regexOutHTMLJunk:_issue.subtitle];
        _subtitleLabel.text = modifiedSubtitleString;
        
        
        // Set a minimum height constraint for the subtitle
        CGFloat height = [_subtitleLabel.text boundingRectWithSize:_subtitleLabel.frame.size
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:@{NSFontAttributeName:_subtitleLabel.font}
                                                           context:nil].size.height;
        
        [_subtitleLabel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[subtitleLabel(==%d)]", (int)(ceil(height))]
                                                                               options:0
                                                                               metrics:nil
                                                                                 views:@{@"subtitleLabel" : _subtitleLabel}]];
    }
    _distributorCodeLabel.text = _issue.diamondID;
    _priceLabel.text = [NSString stringWithFormat:@"$%.02f", [_issue.price floatValue]];
    [_publisherButton setTitle:_issue.publisher.name
                      forState:UIControlStateNormal];
    [_releaseDateButton setTitle:[NSString localTimeZoneStringWithDate:_issue.releaseDate]
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
    
    NSString *modifiedDescriptionString = [NSString regexOutHTMLJunk:_issue.issueDescription];
    _descriptionTextView.text = modifiedDescriptionString;
    _descriptionTextView.selectable = NO;
    [_descriptionTextView scrollRangeToVisible:NSMakeRange(0, 0)]; // Scroll to the top
    
    _descriptionTextView.font = [UIFont issueDetailDescriptionFont];
    
    CGFloat height = [_descriptionTextView.text boundingRectWithSize:_descriptionTextView.frame.size
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName:_descriptionTextView.font}
                                              context:nil].size.height;
    
    height = (height < 88) ? 88 : ((height > 88) ? self.view.frame.size.height/4 : height);
    
    // Add 16 px because of the text view scroll margins?
    [_descriptionTextView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_descriptionTextView(==%d)]", (int)(ceil(height))+16]
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(_descriptionTextView)]];
    
    
    [_imageButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _imageButton.tag = 0;
    
    _latestIssueForTitleImageView = [UIImageView new];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [LBXControllerServices setViewWillAppearClearNavigationController:self];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [LBXControllerServices setViewDidAppearClearNavigationController:self];
    selectedTitle = NO;
    [LBXLogging logMessage:[NSString stringWithFormat:@"LBXIssue\n%@\ndid appear", _issue]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (!selectedTitle) {
        [LBXControllerServices setViewWillDisappearClearNavigationController:self];
    }
    self.navigationController.navigationBar.topItem.title = @" ";
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
            selectedTitle = YES;
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title.titleID == %@", _issue.title.titleID];
            NSArray *issuesArray = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
            
            LBXTitleDetailViewController *titleViewController = [[LBXTitleDetailViewController alloc] initWithTitle:_issue.title];
            [LBXLogging logMessage:[NSString stringWithFormat:@"Selected title: %@", _issue.title.description]];
            titleViewController.titleID = _issue.title.titleID;
            titleViewController.latestIssueImage = (issuesArray[0] == _issue) ? _issueImage : [UIImage imageNamed:@"black"];
            
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
        
        [sheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
            switch (indexPath.section) {
                case 0:
                    switch (indexPath.row) {
                        case 0:
                        {
                            UIImageWriteToSavedPhotosAlbum(_issueImage, nil, nil, nil);
                            [SVProgressHUD showSuccessWithStatus:@"Saved to Photos" maskType:SVProgressHUDMaskTypeBlack];
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

#pragma mark Private Methods

- (void)setupImageViews
{
    UIImageView *imageView = [UIImageView new];
    // Get the image from the URL and set it
    [imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_issue.coverImage]] placeholderImage:[UIImage defaultCoverImageWithWhiteBackground] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
        _issueImage = image;
        [self setupImagesWithImage:image];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
        _issueImage = [UIImage defaultCoverImageWithWhiteBackground];
        [self setupImagesWithImage:[UIImage imageNamed:@"black"]];
        
    }];
}


- (void)setupImagesWithImage:(UIImage *)image
{
    _coverImageView.alpha = 0.0;
    _backgroundCoverImageView.alpha = 0.0;
    [_backgroundCoverImageView setImageToBlur:image blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:nil];
    UIImage *darkenedImage = _issueImage;
    [darkenedImage applyDarkEffect];
    
    darkenedImage = [darkenedImage applyBlurWithRadius:0.0
                                           tintColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3]
                                saturationDeltaFactor:0.5
                                            maskImage:nil];
    
    [_coverImageView setImage:darkenedImage];
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
