//
//  LBXIssueScrollViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/23/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXIssueScrollViewController.h"
#import "LBXIssueDetailViewController.h"
#import "LBXControllerServices.h"
#import "LBXClient.h"

#import <Shimmer/FBShimmeringView.h>
#import "NSString+StringUtilities.h"

@interface LBXIssueScrollViewController ()

@property (nonatomic) NSArray *issues;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIImage *issueImage;
@property (nonatomic) LBXIssueDetailViewController *titleViewController;
@property (nonatomic) LBXIssueDetailViewController *parentTitleViewController;

@end

@implementation LBXIssueScrollViewController

CGRect screenRect;

- (instancetype)initWithIssues:(NSArray *)issues andImage:(UIImage *)image {
    if(self = [super init]) {
        _issues = issues;
        _issueImage = image;
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
    
    CGRect viewFrame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    int navAndStatusHeight = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
    viewFrame.origin.y -= navAndStatusHeight;
    viewFrame.size.height += navAndStatusHeight;
    _scrollView = [[UIScrollView alloc] initWithFrame:viewFrame];
    _scrollView.backgroundColor = [UIColor blackColor];
    _scrollView.pagingEnabled = YES;
    _scrollView.bounces = NO;
    _scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.navigationController.navigationBar.frame.size.height, 0);
    [self.view addSubview:_scrollView];
    
    [LBXControllerServices setupTransparentNavigationBarForViewController:self];
    
    // Fix so the swipe to go back gesture works with a horizontal scrollview
    // http://stackoverflow.com/questions/23267929/combine-uipageviewcontroller-swipes-with-ios-7-uinavigationcontroller-back-swipe
    for (UIGestureRecognizer *gestureRecognizer in _scrollView.gestureRecognizers) {
        [gestureRecognizer requireGestureRecognizerToFail:self.navigationController.interactivePopGestureRecognizer];
    }
    
    screenRect = self.view.bounds;
    CGRect bigRect = screenRect;
    screenRect.origin.x -= screenRect.size.width;
    bigRect.size.width *= (_issues.count);
    _scrollView.contentSize = bigRect.size;
    
    // Set up the first issue
    [self setupIssueViewsWithIssuesArray:@[_issues.firstObject]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [LBXControllerServices setViewWillAppearClearNavigationController:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [LBXControllerServices setViewDidAppearClearNavigationController:self];
    // Set up the rest of the issue variants
    [self setupIssueViewsWithIssuesArray:[_issues subarrayWithRange:NSMakeRange(1, _issues.count-1)]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [LBXControllerServices setViewWillDisappearClearNavigationController:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark Private Methods

- (void)setupIssueViewsWithIssuesArray:(NSArray *)issuesArray
{
    for (LBXIssue *issue in issuesArray) {
        screenRect.origin.x += screenRect.size.width;
        _titleViewController = [[LBXIssueDetailViewController alloc] initWithFrame:screenRect andIssue:issue];
        
        if (screenRect.origin.x < screenRect.size.width) {
            _parentTitleViewController = _titleViewController;
            _titleViewController.alternativeCoversArrowView.alpha = 0.0; // Hide until all variant issues are loaded
            
            FBShimmeringView *shimmeringView = [[FBShimmeringView alloc] initWithFrame:_titleViewController.alternativeCoversArrowView.bounds];
            [_titleViewController.alternativeCoversArrowView addSubview:shimmeringView];
            
            UILabel *loadingLabel = [[UILabel alloc] initWithFrame:_titleViewController.alternativeCoversArrowView.bounds];
            loadingLabel.textColor = [UIColor whiteColor];
            loadingLabel.font = [UIFont fontWithName:@"Mishafi" size:32];
            loadingLabel.text = @"<<<";
            shimmeringView.contentView = loadingLabel;
            
            shimmeringView.shimmeringDirection = FBShimmerDirectionLeft;
            shimmeringView.shimmeringSpeed = 25;
            shimmeringView.shimmeringPauseDuration = 1.0;
            
            // Start shimmering.
            shimmeringView.shimmering = YES;
        }
        
        // Add to the scroll view
        [self addChildViewController:_titleViewController];
        [_scrollView addSubview:_titleViewController.view];
        [_titleViewController didMoveToParentViewController:self];
        
        if (issuesArray.count == (NSMakeRange(1, _issues.count-1)).length && (issuesArray.lastObject == issue)) {
            [UIView transitionWithView:_parentTitleViewController.alternativeCoversArrowView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{_parentTitleViewController.alternativeCoversArrowView.alpha = 1.0;}
                            completion:NULL];
            
        }
    }
}

- (void)showShareSheet {
    int page = self.scrollView.contentOffset.x / self.scrollView.frame.size.width;
    LBXIssue *issue = ((LBXIssue *)[_issues objectAtIndex:page]);
    NSString *infoString = [NSString fixHTMLAttributes:issue.completeTitle];
    NSString *urlString = [NSString stringWithFormat:@"%@%@", @"https://longboxed.com/issue/", issue.diamondID];
    NSString *viaString = [NSString stringWithFormat:@"\nvia @longboxed for iOS"];
    UIImage *coverImage = [UIImage new];
    for (LBXIssueDetailViewController *vc in self.childViewControllers) {
        NSLog(@"%f   %f", vc.view.frame.origin.x, self.scrollView.contentOffset.x);
        if (vc.view.frame.origin.x == self.scrollView.contentOffset.x) {
            coverImage = vc.coverImageView.image;
        }
    }
    
    [LBXControllerServices showShareSheetWithArrayOfInfo:@[infoString, [NSURL URLWithString:urlString], viaString, coverImage]];

}

@end
