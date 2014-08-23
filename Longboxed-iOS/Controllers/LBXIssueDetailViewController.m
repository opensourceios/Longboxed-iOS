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

@interface LBXIssueDetailViewController () <UITableViewDelegate>

@property (nonatomic) IBOutlet UIImageView *backgroundCoverImageView;
@property (nonatomic) IBOutlet UITextView *descriptionTextView;
@property (nonatomic) IBOutlet UIImageView *coverImageView;
@property (nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) IBOutlet UIButton *imageButton;
@property (nonatomic) IBOutlet UILabel *titleLabel;

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
        _tableView = [UITableView new];
        _tableView.delegate = self;
        _alternates = alternates;
    }
    return self;
}

- (instancetype)initWithAlternates:(NSArray *)alternates {
    if(self = [super init]) {
        _backgroundCoverImageView = [UIImageView new];
        _descriptionTextView = [UITextView new];
        _coverImageView = [UIImageView new];
        _tableView = [UITableView new];
        _tableView.delegate = self;
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
    
    NSString *modifiedTitleString = [regex stringByReplacingMatchesInString:_issue.completeTitle options:0 range:NSMakeRange(0, [_issue.completeTitle length]) withTemplate:@""];
    _titleLabel.text = modifiedTitleString;
    
    NSString *modifiedDescriptionString = [regex stringByReplacingMatchesInString:_issue.issueDescription options:0 range:NSMakeRange(0, [_issue.issueDescription length]) withTemplate:@""];
    _descriptionTextView.text = modifiedDescriptionString;
    _descriptionTextView.selectable = NO;
    
    [_imageButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _imageButton.tag = 1;
    
    self.tableView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.0];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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

#pragma mark UITableView methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

// Change the Height of the Cell [Default is 44]:
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 22;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell new];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIImage *image = [UIImage imageNamed:@"arrow"];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.bounds = CGRectMake(imageView.frame.origin.x+10, imageView.frame.origin.y+10, imageView.frame.size.width, imageView.frame.size.height-10);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;
    imageView.transform = CGAffineTransformMakeRotation(2*M_PI_2);
    imageView.tintColor = [UIColor whiteColor];
    
    switch (indexPath.row) {
        case 0:
        {
            cell.textLabel.text = _issue.publisher.name.uppercaseString;
            cell.accessoryView = imageView;
            break;
        }
        case 1:
        {
            cell.textLabel.text = [LBXTitleServices localTimeZoneStringWithDate:_issue.releaseDate].uppercaseString;
            cell.accessoryView = imageView;
            break;
        }
        case 2:
        {
            cell.textLabel.text = [NSString stringWithFormat:@"$%.02f", [_issue.price floatValue]].uppercaseString;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case 3:
        {
            cell.textLabel.text = _issue.diamondID.uppercaseString;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case 4:
        {
            cell.textLabel.text = @"3 VARIANT COVERS";
            cell.accessoryView = imageView;
        }
            
        default:
            break;
    }
    
    cell.textLabel.font = [UIFont titleDetailSubscribersAndIssuesFont];
    cell.textLabel.textColor = [UIColor whiteColor];
    
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"selected row %ld", (long)indexPath.row);
}

@end
