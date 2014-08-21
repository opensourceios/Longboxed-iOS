//
//  LBXIssueDetailViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/19/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXIssueDetailViewController.h"

#import "UIImageView+LBBlurredImage.h"
#import "UIFont+customFonts.h"
#import "UIImage+ImageEffects.h"
#import "PaperButton.h"

#import <FontAwesomeKit/FontAwesomeKit.h>

@interface LBXIssueDetailViewController ()

@property (nonatomic) IBOutlet UIImageView *backgroundCoverImageView;
@property (nonatomic) IBOutlet UITextView *descriptionTextView;
@property (nonatomic) IBOutlet UIImageView *coverImageView;
@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) PaperButton *closeButton;
@property (nonatomic, copy) UIImage *issueImage;
@property (nonatomic, copy) LBXIssue *issue;

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
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    [_backgroundCoverImageView setImageToBlur:_issueImage blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:nil];
    [_issueImage applyDarkEffect];
    
    UIImage *blurredImage = [_issueImage applyBlurWithRadius:0.0
                                             tintColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3]
                                 saturationDeltaFactor:0.5
                                             maskImage:nil];
    
    [_coverImageView setImage:blurredImage];
    
    
    _issue = [LBXIssue MR_findFirstByAttribute:@"issueID" withValue:_issueID];
    NSLog(@"Selected issue %@", _issue.issueID);
    
    _titleLabel.text = _issue.completeTitle;
    
    NSString *string = _issue.issueDescription;
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"&#[0-9]+;" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@""];
    _descriptionTextView.text = modifiedString;
    
    _closeButton = [PaperButton buttonWithOrigin:CGPointMake(16, 16)];
    _closeButton.tintColor = [UIColor whiteColor];
    [_closeButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_closeButton];
    [_closeButton animateToClose];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.navigationController.navigationBar.topItem.title = _issue.title.name;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonPressed:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
