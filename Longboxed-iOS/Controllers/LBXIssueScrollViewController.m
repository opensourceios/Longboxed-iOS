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

@property (nonatomic) NSArray *issues;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIImage *issueImage;
@property (nonatomic) LBXIssueDetailViewController *titleViewController;

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
    
    screenRect = self.view.bounds;
    CGRect bigRect = screenRect;
    screenRect.origin.x -= screenRect.size.width;
    bigRect.size.width *= (_issues.count);
    _scrollView.contentSize = bigRect.size;
    // Set up the first issue
//    [self setupIssueViewsWithIssuesArray:_issues];
//    NSOperationQueue *operationQueue = [NSOperationQueue new];
    
    [self setupIssueViewsWithIssuesArray:@[_issues.firstObject]];
    
    
    
//    [operationQueue addOperationWithBlock:^{
//        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(title == %@) AND (issueNumber == %@)", _issue.title, _issue.issueNumber];
//        issuesArray = [LBXIssue MR_findAllSortedBy:@"completeTitle" ascending:YES withPredicate:predicate];
//    }];
//    [self setupIssueViewsWithIssuesArray:issuesArray];


}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupIssueViewsWithIssuesArray:[_issues subarrayWithRange:NSMakeRange(1, _issues.count-1)]];
    // Set up the rest of the issue variants

}

#pragma mark Private Methods

- (void)setupIssueViewsWithIssuesArray:(NSArray *)issuesArray
{
    for (LBXIssue *issue in issuesArray) {
        screenRect.origin.x += screenRect.size.width;
//        if (!_titleViewController) {
        _titleViewController = [[LBXIssueDetailViewController alloc] initWithFrame:screenRect andIssue:issue];
//        }
    
        // Add to the scroll view
        [self addChildViewController:_titleViewController];
        [_scrollView addSubview:_titleViewController.view];
        [_titleViewController didMoveToParentViewController:self];
    }
}

@end
