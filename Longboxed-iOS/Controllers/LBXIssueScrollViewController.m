//
//  LBXIssueScrollViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/23/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXIssueScrollViewController.h"
#import "LBXIssueDetailViewController.h"
#import "LBXClient.h"
#import "LBXMessageBar.h"

@interface LBXIssueScrollViewController ()

@property (nonatomic) LBXIssue *issue;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIImage *issueImage;

@end

@implementation LBXIssueScrollViewController

CGRect screenRect;

- (instancetype)initWithIssue:(LBXIssue *)issue andImage:(UIImage *)image {
    if(self = [super init]) {
        _issue = issue;
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
    
    CGRect viewFrame = self.view.frame;
    int navAndStatusHeight = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
    viewFrame.origin.y -= navAndStatusHeight;
    viewFrame.size.height += navAndStatusHeight;
    _scrollView = [[UIScrollView alloc] initWithFrame:viewFrame];
    _scrollView.backgroundColor = [UIColor blackColor];
    _scrollView.pagingEnabled = YES;
    _scrollView.bounces = NO;
    _scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    [self.view addSubview:_scrollView];
    
    [self setupIssueViewsWithIssue:_issue];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
}

#pragma mark Private Methods

- (void)setupIssueViewsWithIssue:(LBXIssue *)issue
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(title == %@) AND (issueNumber == %@)", _issue.title, _issue.issueNumber];
    NSArray *issuesArray = [LBXIssue MR_findAllSortedBy:@"completeTitle" ascending:YES withPredicate:predicate];
    screenRect = self.view.bounds;
    CGRect bigRect = screenRect;
    bigRect.size.width *= (issuesArray.count);
    _scrollView.contentSize = bigRect.size;
    
    __block int count = 0;
    for (LBXIssue *issue in issuesArray) {
        LBXIssueDetailViewController *titleViewController = [[LBXIssueDetailViewController alloc] initWithAlternates:issue.alternates];
        titleViewController.issueID = issue.issueID;
        // Add to the scroll view
        if (count != 0) {
            screenRect.origin.x += screenRect.size.width;
        }
        titleViewController.view.frame = screenRect;
        [self addChildViewController:titleViewController];
        [_scrollView addSubview:titleViewController.view];
        [titleViewController didMoveToParentViewController:self];
        count++;
    }
}

@end
