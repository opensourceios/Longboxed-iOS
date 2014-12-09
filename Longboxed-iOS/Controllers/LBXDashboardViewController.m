//
//  LBXDashboardViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/27/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXDashboardViewController.h"
#import "LBXTopTableViewCell.h"
#import "LBXBottomTableViewCell.h"
#import "LBXIssueDetailViewController.h"
#import "LBXIssueScrollViewController.h"
#import "LBXTitleDetailViewController.h"
#import "LBXPublisherTableViewController.h"
#import "LBXControllerServices.h"
#import "LBXPullListTableViewCell.h"
#import "LBXLoginViewController.h"
#import "LBXWeekViewController.h"
#import "LBXPullListViewController.h"
#import "LBXSearchTableViewController.h"
#import "PaintCodeImages.h"
#import "LBXClient.h"
#import "LBXBundle.h"
#import "LBXLogging.h"

#import "UIFont+customFonts.h"
#import "UIColor+customColors.h"
#import "UIImage+CreateImage.h"
#import "UIImage+DrawOnImage.h"
#import "UIImage+ImageEffects.h"

#import <FontAwesomeKit/FontAwesomeKit.h>
#import <UICKeyChainStore.h>
#import <QuartzCore/QuartzCore.h>
#import <SVProgressHUD.h>

@interface LBXDashboardViewController () <UISearchControllerDelegate, UISearchBarDelegate>

@property (nonatomic, strong) LBXClient *client;
@property (nonatomic, strong) LBXIssue *featuredIssue;
@property (nonatomic, strong) LBXSearchTableViewController *searchResultsController;
@property (nonatomic, strong) NSArray *popularIssuesArray;
@property (nonatomic, strong) NSArray *bundleIssuesArray;
@property (nonatomic, strong) NSMutableArray *lastFiveBundlesIssuesArray;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSArray *tableConstraints;
@property (nonatomic) NSArray *searchResultsArray;

@end

@implementation LBXDashboardViewController

static double TABLEHEIGHT = 174;

@synthesize topTableView;
@synthesize bottomTableView;
@synthesize topTableViewCell;
@synthesize bottomTableViewCell;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Do any additional setup after loading the view from its nib.
        //self.edgesForExtendedLayout = UIRectEdgeNone;
        // Custom initialization
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"longboxed_full"]];
        UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
        self.navigationItem.rightBarButtonItem = actionButton;
        [self.navigationItem.rightBarButtonItem setTintColor:[UIColor blackColor]];
        
        int checksize = 24;
        FAKFontAwesome *cogIcon = [FAKFontAwesome cogIconWithSize:checksize];
        [cogIcon addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
        UIImage *cogImage = [cogIcon imageWithSize:CGSizeMake(checksize, checksize)];
        
        UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:cogImage style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed)];
        
        self.navigationItem.leftBarButtonItem = settingsButton;
        self.navigationItem.leftBarButtonItem.tintColor = [UIColor blackColor];
        
        self.view.backgroundColor = [UIColor whiteColor];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(pushToIssueWithDict:)
                                                     name:@"pushToIssueWithDict"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadTableView)
                                                     name:@"reloadDashboardTableView"
                                                   object:nil];
        
        self.browseTableView.contentInset = UIEdgeInsetsMake(-2, 0, -2, 0);
        
        [self.topTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        self.bottomTableView.tableFooterView = [UIView new];
        
        self.searchResultsController = [LBXSearchTableViewController new];
        _searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchResultsController];
        _searchController.searchResultsUpdater = self.searchResultsController;
        self.searchResultsController.tableView.delegate = self;
        self.searchResultsController.tableView.dataSource = self;
        _searchController.dimsBackgroundDuringPresentation = YES;
        _searchController.delegate = self;
        _searchController.searchBar.delegate = self;
        self.definesPresentationContext = YES;
        
        [_scrollView addSubview:_searchController.searchBar];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSIndexPath *tableSelection = [self.browseTableView indexPathForSelectedRow];
    [self.browseTableView deselectRowAtIndexPath:tableSelection animated:YES];
    
    tableSelection = [self.searchResultsController.tableView indexPathForSelectedRow];
    [self.searchResultsController.tableView deselectRowAtIndexPath:tableSelection animated:YES];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont searchPlaceholderFont]];
    [LBXControllerServices setViewWillAppearWhiteNavigationController:self];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.topTableView.contentInset = UIEdgeInsetsZero;
    [_bundleButton setTitleColor:[UIColor lightGrayColor]
                        forState:UIControlStateHighlighted];
    [_popularButton setTitleColor:[UIColor lightGrayColor]
                         forState:UIControlStateHighlighted];
    [self setArrowsForButton:_bundleButton];
    [self setArrowsForButton:_popularButton];
    
    _searchBar.hidden = YES;
    
    _featuredDescriptionLabel.textColor = [UIColor whiteColor];
    _featuredDescriptionLabel.font = [UIFont featuredIssueDescriptionFont];

    [_bundleButton addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
    [_popularButton addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];

    // Add 1px line
    CALayer *separatorBottomBorder = [CALayer layer];
    separatorBottomBorder.frame = CGRectMake(-self.thisWeekLabel.frame.origin.x, -self.thisWeekLabel.frame.origin.x, [UIScreen mainScreen].bounds.size.width, 1.0f);
    separatorBottomBorder.backgroundColor = [UIColor colorWithHex:@"#C8C7CC"].CGColor;
    [self.thisWeekLabel.layer addSublayer:separatorBottomBorder];

    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 1.0f);
    bottomBorder.backgroundColor = [UIColor colorWithHex:@"#C8C7CC"].CGColor;
    [_separatorView.layer addSublayer:bottomBorder];
    
    _searchController.searchBar.barStyle = UISearchBarStyleMinimal;
    _searchController.searchBar.backgroundImage = [[UIImage alloc] init];
    _searchController.searchBar.backgroundColor = [UIColor clearColor];
    _searchController.searchBar.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44);
    _searchController.searchBar.placeholder = @"Search Comics";
    _searchController.searchBar.clipsToBounds = YES;
    _searchController.hidesNavigationBarDuringPresentation = YES;
    UIImage *image = [PaintCodeImages imageOfMagnifyingGlassWithColor:[UIColor whiteColor] width:24];
    [_searchController.searchBar setImage:image forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    
    [self reloadTableView];
}

- (void)reloadTableView
{
    [_browseTableView removeConstraints:_tableConstraints];
    double height = TABLEHEIGHT;
    if (!_bundleButton.superview && !topTableView.superview) {
        // Show the bundle horizontal table view if logged in
        [self.view insertSubview:_bundleButton aboveSubview:_popularButton];
        [self.view insertSubview:topTableView aboveSubview:_popularButton];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_bundleButton
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:_thisWeekLabel
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1.0
                                                               constant:4.0]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_bundleButton
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:_thisWeekLabel
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:4.0]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_bundleButton
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:topTableView
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:-4.0]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:topTableView
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:bottomTableView
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1.0
                                                               constant:0.0]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:topTableView
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:bottomTableView
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1.0
                                                               constant:0.0]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:topTableView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:_popularButton
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:-15.0]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:topTableView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:bottomTableView
                                                              attribute:NSLayoutAttributeHeight
                                                             multiplier:1.0
                                                               constant:0.0]];
    }
    // Hide some stuff if not logged in
    if (![LBXControllerServices isLoggedIn]) {
        height = TABLEHEIGHT/2;
       [_bundleButton removeFromSuperview];
       [topTableView removeFromSuperview];
    }
    // Adjust the menus to hide the pull list/bundle options if not logged in
    _tableConstraints = [NSLayoutConstraint
                        constraintsWithVisualFormat:@"V:[browseTableView(tableViewHeight)]"
                        options:0
                        metrics:@{@"tableViewHeight" : [NSNumber numberWithDouble:height]}
                        views:@{@"browseTableView" : _browseTableView}];
    [_browseTableView addConstraints:_tableConstraints];
    
    [self.view setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [LBXControllerServices setViewDidAppearWhiteNavigationController:self];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"longboxed_full"]];
    _client = [LBXClient new];
    
    [self getCoreDataLatestBundle];
    [self.topTableView reloadData];
    
    [self refresh];
    
    if (!_featuredBlurredImageView.image) {
        [SVProgressHUD showAtPosY:(_featuredBlurredImageView.frame.origin.y + _featuredBlurredImageView.frame.size.height)/2 + self.navigationController.navigationBar.frame.size.height + _searchBar.frame.size.height];
    }
}

#pragma mark Private Methods

- (void)setArrowsForButton:(UIButton *)button
{
    // Move the arrow so it is on the right side of the publisher text
    button.imageView.tintColor = [UIColor blackColor];
    
    button.titleEdgeInsets = UIEdgeInsetsMake(0, -button.imageView.frame.size.width, 0, button.imageView.frame.size.width);
    button.imageEdgeInsets = UIEdgeInsetsMake(0, button.titleLabel.frame.size.width + 4, 2, -button.titleLabel.frame.size.width);
    [_bundleButton.imageView setUserInteractionEnabled:YES];
}

- (void)refresh
{
    [self fetchBundle];
    [self fetchPopularIssues];
    [self fetchPullList];
}

- (void)setFeaturedIssueWithIssuesArray:(NSArray *)popularIssuesArray
{
    if (!_popularIssuesArray.count) {
        [SVProgressHUD dismiss];
        return;
    }
    
    // Feature an issue that has a cover
    BOOL validImage = NO;
    for (LBXIssue *issue in popularIssuesArray) {
        if (!validImage) {
            if (issue.coverImage) {
                validImage = YES;
                _featuredIssue = issue;
            }
        }
    }
    
    self.featuredDescriptionLabel.text = [LBXControllerServices regexOutHTMLJunk:_featuredIssue.issueDescription];
    self.featuredDescriptionLabel.textColor = UIColor.whiteColor;
    _featuredDescriptionLabel.font = [UIFont featuredIssueDescriptionFont];
    self.featuredIssueTitleLabel.text = _featuredIssue.title.name;
    
    UIImageView *featuredImageView = [UIImageView new];
    featuredImageView.frame = _featuredIssueCoverButton.bounds;
    
    __weak __typeof(self) weakSelf = self;
    __weak typeof(featuredImageView) weakfeaturedImageView = featuredImageView;
    [featuredImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_featuredIssue.coverImage]] placeholderImage:[UIImage singlePixelImageWithColor:[UIColor clearColor]] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
        weakfeaturedImageView.image = image;
        
        // Only fade in the image if it was fetched (not from cache)
        if (request) {
            [UIView transitionWithView:weakSelf.featuredIssueCoverButton
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[weakSelf.featuredIssueCoverButton setBackgroundImage:weakfeaturedImageView.image forState:UIControlStateNormal];}
                            completion:NULL];
            [weakSelf setFeaturedBlurredImageViewWithImage:weakfeaturedImageView.image];
        }
        else {
            [weakSelf setFeaturedBlurredImageViewWithImage:weakfeaturedImageView.image];
            [weakSelf.featuredIssueCoverButton setBackgroundImage:weakfeaturedImageView.image forState:UIControlStateNormal];
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
        UIImage *defaultImage = [UIImage imageByDrawingInitialsOnImage:[UIImage imageWithColor:[UIColor clearColor] rect:weakfeaturedImageView.frame] withInitials:weakSelf.featuredIssue.title.publisher.name font:[UIFont defaultPublisherInitialsFont]];
        
        [weakSelf setFeaturedBlurredImageViewWithImage:defaultImage];
        [weakSelf.featuredIssueCoverButton setBackgroundImage:defaultImage forState:UIControlStateNormal];
    }];
}

-(void)setFeaturedBlurredImageViewWithImage:(UIImage *)image
{
    UIImage *blurredImage = [image applyBlurWithRadius:20
                                             tintColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.1]
                                 saturationDeltaFactor:1
                                             maskImage:nil];
    
    [UIView transitionWithView:self.featuredBlurredImageView
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{self.featuredBlurredImageView.image = blurredImage;}
                    completion:NULL];
    
    [SVProgressHUD dismiss];
}

- (void)getCoreDataPopularIssues
{
    NSDate *currentDate = [LBXControllerServices getLocalDate];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(releaseDate > %@) AND (releaseDate < %@) AND (isParent == %@)", [currentDate dateByAddingTimeInterval:- 3*DAY], [currentDate dateByAddingTimeInterval:4*DAY], @1];
    NSArray *allIssuesArray = [LBXIssue MR_findAllSortedBy:@"title.subscribers" ascending:NO withPredicate:predicate];
    
    NSSortDescriptor *boolDescr = [[NSSortDescriptor alloc] initWithKey:@"title.subscribers" ascending:NO];
    NSArray *sortDescriptors = @[boolDescr];
    NSArray *sortedArray = [NSArray new];
    if (allIssuesArray.count >= 10) {
        sortedArray = [[allIssuesArray subarrayWithRange:NSMakeRange(0, 10)] sortedArrayUsingDescriptors:sortDescriptors];
    }
    
    _popularIssuesArray = sortedArray;
    
    [self setFeaturedIssueWithIssuesArray:_popularIssuesArray];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.bottomTableView reloadData];
    });
}

- (void)fetchPopularIssues
{
    // Fetch popular issues
    [self.client fetchPopularIssuesWithCompletion:^(NSArray *popularIssuesArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            __block int count = 0;
            for (LBXIssue *issue in popularIssuesArray) {
                [self.client fetchTitle:issue.title.titleID withCompletion:^(LBXTitle *title, RKObjectRequestOperation *response, NSError *error) {
                    count++;
                    if (popularIssuesArray.count == count) {
                        [self getCoreDataPopularIssues];
                    }
                }];
            }
        }
        else {
            //[LBXMessageBar displayError:error];
        }
    }];
}

- (void)fetchPullList
{
    [self.client fetchPullListWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        if (!error);
        else;
    }];
}

- (void)getCoreDataLatestBundle
{
    NSArray *coreDataBundleArray = [LBXBundle MR_findAllSortedBy:@"releaseDate" ascending:NO];
    LBXBundle *bundle;
    if (coreDataBundleArray.firstObject) {
        bundle = coreDataBundleArray.firstObject;
        
        NSString *issuesString = @"ISSUES IN YOUR BUNDLE";
        if (bundle.issues.count == 1) {
            issuesString = @"ISSUE IN YOUR BUNDLE";
        }
        
        NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"completeTitle" ascending:YES];
        NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
        _bundleIssuesArray = [[bundle.issues allObjects] sortedArrayUsingDescriptors:descriptors];
        
        [self.topTableView reloadData];
        [_bundleButton setTitle:[NSString stringWithFormat:@"%lu %@", (unsigned long)bundle.issues.count, issuesString]
                       forState:UIControlStateNormal];
        [_bundleButton setNeedsDisplay];
    }
    else {
        [_bundleButton setTitle:@"0 ISSUES IN YOUR BUNDLE"
                       forState:UIControlStateNormal];
    }
    
}

- (void)getCoreDataLastFiveBundles
{
    _lastFiveBundlesIssuesArray = [NSMutableArray new];
    NSArray *coreDataBundleArray = [LBXBundle MR_findAllSortedBy:@"releaseDate" ascending:NO];
    if (coreDataBundleArray.firstObject) {
        for (LBXBundle *bundle in coreDataBundleArray) {
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"completeTitle" ascending:YES];
            NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
            [_lastFiveBundlesIssuesArray addObject:[[bundle.issues allObjects] sortedArrayUsingDescriptors:descriptors]];
        }
    }
}

- (void)fetchBundle
{
    if ([LBXControllerServices isLoggedIn]) {
        // Fetch the users bundles
        [self.client fetchBundleResourcesWithCompletion:^(NSArray *bundleArray, RKObjectRequestOperation *response, NSError *error) {
            
            if (!error) {
                // Get the bundles from Core Data
                [self getCoreDataLatestBundle];
            
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.topTableView reloadData];
                });
            }
            else {
                //[LBXMessageBar displayError:error];
            }
        }];
    }
}

- (void)searchLongboxedWithText:(NSString *)searchText {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    // Search
    [self.client fetchAutocompleteForTitle:searchText withCompletion:^(NSArray *newSearchResultsArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            self.searchResultsArray = newSearchResultsArray;
            [self.searchResultsController.tableView reloadData];
        }
        else {
            //[LBXMessageBar displayError:error];
        }
    }];
}

- (void)pushToIssueWithDict:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    LBXIssue *issue = dict[@"issue"];
    
    // Set up the scroll view controller containment if there are alternate issues
    if (issue.alternates.count) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(title == %@) AND (issueNumber == %@)", issue.title, issue.issueNumber];
        NSArray *issuesArray = [LBXIssue MR_findAllSortedBy:@"completeTitle" ascending:YES withPredicate:predicate];
        LBXIssueScrollViewController *scrollViewController = [[LBXIssueScrollViewController alloc] initWithIssues:issuesArray andImage:dict[@"image"]];
        [self.navigationController pushViewController:scrollViewController animated:YES];
    }
    else {
        LBXIssueDetailViewController *titleViewController = [[LBXIssueDetailViewController alloc] init];
        titleViewController.issue = issue;
        [self.navigationController pushViewController:titleViewController animated:YES];
    }
}

- (void)settingsPressed
{
    LBXLoginViewController *newVC = [LBXLoginViewController new];
    newVC.dashController = self; // So it can be pushed back onto the view hierarchy and isn't deallocated
    NSMutableArray *vcs =  [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    [vcs insertObject:newVC atIndex:[vcs count]-1];
    [self.navigationController setViewControllers:vcs animated:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onClick:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch ([button tag]) {
        case 0: // Add title to pull list
        {
            [self getCoreDataLastFiveBundles];
            // Pressing the your bundle/issues button
            LBXWeekViewController *controller = [[LBXWeekViewController alloc] initWithIssues:_lastFiveBundlesIssuesArray andTitle:@"Bundles"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case 1:
        {
            // Pressing the popular button
            LBXWeekViewController *controller = [[LBXWeekViewController alloc] initWithIssues:_popularIssuesArray andTitle:@"Popular This Week"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case 2:
        {
            // Selecting the featured issue
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title.titleID == %@", _featuredIssue.title.titleID];
            NSArray *issuesArray = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
            
            LBXTitleDetailViewController *titleViewController = [[LBXTitleDetailViewController alloc] initWithTitle:_featuredIssue.title];
            titleViewController.titleID = _featuredIssue.title.titleID;
            titleViewController.latestIssueImage = (issuesArray[0] == _featuredIssue) ? [self.featuredIssueCoverButton backgroundImageForState:UIControlStateNormal] : [UIImage imageNamed:@"black"];
            
            [LBXLogging logMessage:[NSString stringWithFormat:@"Selected title %@", _featuredIssue.title]];
            [self.navigationController pushViewController:titleViewController animated:YES];
            break;
        }
    }
}

#pragma mark UISearchControllerDelegate Methods

- (void)willPresentSearchController:(UISearchController *)searchController
{
    // SearchBar cancel button font
    [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:[UIColor blackColor]];
    NSDictionary *fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [UIFont searchCancelFont], NSFontAttributeName, [UIColor blackColor], NSForegroundColorAttributeName, nil];
    [[UIBarButtonItem appearance] setTitleTextAttributes:fontDict forState:UIControlStateNormal];
    
    UIView *statusBarView = [UIView new];
    statusBarView.alpha = 0.0;
    statusBarView.backgroundColor = [UIColor whiteColor];
    statusBarView.frame = CGRectMake([UIApplication sharedApplication].statusBarFrame.origin.x, [UIApplication sharedApplication].statusBarFrame.origin.y, [UIApplication sharedApplication].statusBarFrame.size.width, [UIApplication sharedApplication].statusBarFrame.size.height + searchController.searchBar.frame.size.height);
    [self.view addSubview:statusBarView];
    [self.searchController.view insertSubview:statusBarView aboveSubview:searchController.searchBar];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [statusBarView setAlpha:1.0];
    [UIView commitAnimations];
    
    searchController.searchBar.barTintColor = [UIColor whiteColor];
    [LBXControllerServices setSearchBar:searchController.searchBar withTextColor:[UIColor blackColor]];
    _searchResultsArray = nil;

}

- (void)didPresentSearchController:(UISearchController *)searchController
{
    _searchResultsArray = nil;
    
    searchController.searchBar.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height, [UIScreen mainScreen].bounds.size.width, 44);
 
}

- (void)willDismissSearchController:(UISearchController *)searchController
{
    [LBXControllerServices setSearchBar:searchController.searchBar withTextColor:[UIColor whiteColor]];
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    
    _searchController.searchBar.barStyle = UISearchBarStyleMinimal;
    _searchController.searchBar.backgroundImage = [[UIImage alloc] init];
    _searchController.searchBar.backgroundColor = [UIColor clearColor];
    _searchController.searchBar.frame = CGRectMake(8, 0, [UIScreen mainScreen].bounds.size.width - 16, 44);
}

#pragma mark UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Delays on making the actor API calls
    if(searchText.length) {
        [LBXControllerServices setSearchBar:searchBar withTextColor:[UIColor blackColor]];
        searchBar.backgroundColor = [UIColor whiteColor];
        
        float delay = 0.5;
        
        if (searchText.length > 3) {
            delay = 0.3;
        }
        
        // Clear any previously queued text changes
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        [self performSelector:@selector(searchLongboxedWithText:)
                   withObject:searchText
                   afterDelay:delay];
    }
    else {
        [LBXControllerServices setSearchBar:searchBar withTextColor:[UIColor whiteColor]];
        // SearchBar cursor color
        searchBar.tintColor = [UIColor blackColor];
        
        _searchResultsArray = nil;
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    _searchResultsArray = nil;
}

#pragma mark TableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.browseTableView && [LBXControllerServices isLoggedIn]) return 4;
    if (tableView == self.browseTableView) return 2;
    if (tableView == self.searchResultsController.tableView) {
        if (_searchResultsArray.count == 0) {
            return 1;
        }
        return _searchResultsArray.count;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 1.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1.0;
}

-(UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

-(UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.browseTableView) return 44;
    if (tableView == self.searchResultsController.tableView) return 88;
    return tableView.frame.size.height+100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    if (tableView == self.topTableView) {
        LBXTopTableViewCell *cell = (LBXTopTableViewCell*)[self.topTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setBackgroundColor:[UIColor clearColor]];
        if (!cell) {
            [[NSBundle mainBundle] loadNibNamed:@"LBXTopTableViewCell" owner:self options:nil];
            CGAffineTransform rotateTable = CGAffineTransformMakeRotation(-M_PI_2);
            self.topTableViewCell.horizontalTableView.transform = rotateTable;
            self.topTableViewCell.horizontalTableView.frame = CGRectMake(0, 0, self.topTableViewCell.horizontalTableView.frame.size.width, self.topTableViewCell.horizontalTableView.frame.size.height);
            
            self.topTableViewCell.horizontalTableView.allowsSelection = YES;
            cell = self.topTableViewCell;
        }
        self.topTableViewCell.contentArray = _bundleIssuesArray;
        if (_bundleIssuesArray.count) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"reloadTopTableView"
             object:self];
        }
        else {
            [self getCoreDataLatestBundle];
        }
        
        cell = self.topTableViewCell;
        cell.selectedBackgroundView.backgroundColor = [UIColor whiteColor];
        return cell;
    }
    else if (tableView == self.bottomTableView) {
        LBXBottomTableViewCell *cell = (LBXBottomTableViewCell*)[self.bottomTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setBackgroundColor:[UIColor clearColor]];
        if (!cell) {
            [[NSBundle mainBundle] loadNibNamed:@"LBXBottomTableViewCell" owner:self options:nil];
            
            CGAffineTransform rotateTable = CGAffineTransformMakeRotation(-M_PI_2);
            self.bottomTableViewCell.horizontalTableView.transform = rotateTable;
            self.bottomTableViewCell.horizontalTableView.frame = CGRectMake(0, 0, self.bottomTableViewCell.horizontalTableView.frame.size.width, self.bottomTableViewCell.horizontalTableView.frame.size.height);
            
            self.bottomTableViewCell.horizontalTableView.allowsSelection = YES;
            cell = self.bottomTableViewCell;
        }
        self.bottomTableViewCell.contentArray = _popularIssuesArray;
        if (_popularIssuesArray.count) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"reloadBottomTableView"
             object:self];
        }
        else {
            [self getCoreDataPopularIssues];
        }
        
        cell = self.bottomTableViewCell;
        cell.selectedBackgroundView.backgroundColor = [UIColor orangeColor];
        return cell;
    }
    else if (tableView == self.browseTableView) {
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView
                                 dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                     initWithStyle:UITableViewCellStyleDefault
                     reuseIdentifier:CellIdentifier];
        }
        
        int checksize = cell.frame.size.height/2;
        FAKFontAwesome *comicsIcon = [FAKFontAwesome bookIconWithSize:checksize];
        [comicsIcon addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
        UIImage *comicsImage = [comicsIcon imageWithSize:CGSizeMake(checksize, checksize)];
        
        FAKFontAwesome *calendarIcon = [FAKFontAwesome calendarIconWithSize:checksize];
        [comicsIcon addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
        UIImage *calendarIconImage = [calendarIcon imageWithSize:CGSizeMake(checksize, checksize)];
        
        FAKFontAwesome *pullListIcon = [FAKFontAwesome listIconWithSize:checksize];
        [pullListIcon addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
        UIImage *pullListIconImage = [pullListIcon imageWithSize:CGSizeMake(checksize, checksize)];
        
        FAKFontAwesome *clockIcon = [FAKFontAwesome archiveIconWithSize:checksize];
        [clockIcon addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
        UIImage *clockIconImage = [clockIcon imageWithSize:CGSizeMake(checksize, checksize)];
        
        NSArray *imageArray = @[comicsImage, calendarIconImage, pullListIconImage, clockIconImage];
        NSArray *textArray = @[@"Comics", @"Releases", @"Pull List", @"Bundles"];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = [textArray objectAtIndex:indexPath.row];
        cell.textLabel.font = [UIFont browseTableViewFont];
        cell.imageView.image = [imageArray objectAtIndex:indexPath.row];
        
        return cell;
    }
    else if (tableView == self.searchResultsController.tableView) {
        static NSString *CellIdentifier = @"PullListCell";
        
        LBXPullListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        [tableView setSeparatorInset:UIEdgeInsetsZero];
        
        if (cell == nil) {
            // Custom cell as explained here: https://medium.com/p/9bee5824e722
            [tableView registerNib:[UINib nibWithNibName:@"LBXPullListTableViewCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            // Remove inset of iOS 7 separators.
            if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
                cell.separatorInset = UIEdgeInsetsZero;
            }
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
            
            // Setting the background color of the cell.
            cell.contentView.backgroundColor = [UIColor whiteColor];
        }
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.browseTableView)
    {
        //    LBXPublisherCollectionViewController *controller = [LBXPublisherCollectionViewController new];
        switch (indexPath.row) {
            case 0: {
                LBXPublisherTableViewController *controller = [LBXPublisherTableViewController new];
                [self.navigationController pushViewController:controller animated:YES];
                break;
            }
            case 1: {
                LBXWeekViewController *controller = [LBXWeekViewController new];
                [self.navigationController pushViewController:controller animated:YES];
                break;
            }
            case 2: {
                LBXPullListViewController *controller = [[LBXPullListViewController alloc] init];
                controller.title = @"Pull List";
                [self.navigationController pushViewController:controller animated:YES];
                break;
            }
            case 3: {
                [self getCoreDataLastFiveBundles];
                // Pressing the your issues button
                LBXWeekViewController *controller = [[LBXWeekViewController alloc] initWithIssues:_lastFiveBundlesIssuesArray andTitle:@"Bundles"];
                [self.navigationController pushViewController:controller animated:YES];
                break;
            }
        }
    }
    if (tableView == self.searchResultsController.tableView)
    {
        LBXPullListTableViewCell *cell = (LBXPullListTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        
        LBXTitle *title = ((LBXTitle *)[_searchResultsArray objectAtIndex:indexPath.row]);
        LBXTitleDetailViewController *titleViewController = [[LBXTitleDetailViewController alloc] initWithTitle:title];
        titleViewController.titleID = title.titleID;
        titleViewController.latestIssueImage = cell.latestIssueImageView.image;
        
        [LBXLogging logMessage:[NSString stringWithFormat:@"Selected title %@", _featuredIssue.title]];
        [self.navigationController pushViewController:titleViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(LBXPullListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchResultsController.tableView) {
        if (_searchResultsArray.count == 0) {
            cell.imageViewSeparatorLabel.hidden = YES;
            cell.latestIssueImageView.hidden = YES;
            cell.titleLabel.hidden = YES;
            cell.subtitleLabel.hidden = YES;
        }
        else {
            LBXTitle *title = [_searchResultsArray objectAtIndex:indexPath.row];
            [self setTableViewStylesWithCell:cell andTitle:title];
            
            [LBXControllerServices setAddToPullListSearchCell:cell withTitle:title darkenImage:NO];
        }
    }
}

- (void)setTableViewStylesWithCell:(LBXPullListTableViewCell *)cell andTitle:(LBXTitle *)title
{
    cell.imageViewSeparatorLabel.hidden = NO;
    cell.latestIssueImageView.hidden = NO;
    cell.titleLabel.hidden = NO;
    cell.subtitleLabel.hidden = NO;
    NSArray *viewsToRemove = [cell.latestIssueImageView subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];
    
    cell.titleLabel.font = [UIFont pullListTitleFont];
    cell.titleLabel.textColor = [UIColor blackColor];
    cell.titleLabel.text = title.name;
    cell.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    cell.titleLabel.numberOfLines = 2;
    
    cell.subtitleLabel.font = [UIFont pullListSubtitleFont];
    cell.subtitleLabel.textColor = [UIColor grayColor];
    cell.subtitleLabel.numberOfLines = 2;
    
    cell.latestIssueImageView.image = nil;
}



@end
