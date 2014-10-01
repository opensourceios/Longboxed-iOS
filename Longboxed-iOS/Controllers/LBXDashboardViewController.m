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
#import "LBXPublisherViewController.h"
#import "LBXTitleAndPublisherServices.h"
#import "LBXLoginViewController.h"
#import "LBXWeekViewController.h"
#import "LBXSearchViewController.h"
#import "LBXPullListViewController.h"
#import "LBXClient.h"
#import "LBXBundle.h"

#import "UIFont+customFonts.h"
#import "UIColor+customColors.h"

#import <FontAwesomeKit/FontAwesomeKit.h>
#import <UICKeyChainStore.h>
#import <QuartzCore/QuartzCore.h>

@interface LBXDashboardViewController ()

@property (nonatomic, strong) LBXClient *client;
@property (nonatomic, strong) NSArray *popularIssuesArray;
@property (nonatomic, strong) NSArray *bundleIssuesArray;
@property (nonatomic, strong) LBXSearchViewController *searchViewController;

@end

@implementation LBXDashboardViewController

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
        
        self.browseTableView.contentInset = UIEdgeInsetsMake(-2, 0, -2, 0);
        
        [self.topTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        self.bottomTableView.tableFooterView = [UIView new];
        
//        if ([UIScreen mainScreen].bounds.size.height > 667) {
//        [self.topTableView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[topTableView(==%d)]", 165]
//                                                                                options:0
//                                                                                metrics:nil
//                                                                                    views: @{@"topTableView" :self.topTableView}]];
//        }
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSIndexPath *tableSelection = [self.browseTableView indexPathForSelectedRow];
    [self.browseTableView deselectRowAtIndexPath:tableSelection animated:YES];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont searchPlaceholderFont]];
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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBar.topItem.title = @" ";
    
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.shadowImage = nil;
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"longboxed_full"]];
    
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor whiteColor];

    _client = [LBXClient new];
    
    [self getCoreDataBundle];
    [self.topTableView reloadData];
    
    [self refresh];
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
}

- (void)getCoreDataPopularIssues
{
    NSDate *currentDate = [LBXTitleAndPublisherServices getLocalDate];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(releaseDate > %@) AND (releaseDate < %@) AND (isParent == %@)", [currentDate dateByAddingTimeInterval:- 3*DAY], [currentDate dateByAddingTimeInterval:4*DAY], @1];
    NSArray *allIssuesArray = [LBXIssue MR_findAllSortedBy:@"title.subscribers" ascending:NO withPredicate:predicate];
    
    NSSortDescriptor *boolDescr = [[NSSortDescriptor alloc] initWithKey:@"title.subscribers" ascending:NO];
    NSArray *sortDescriptors = @[boolDescr];
    NSArray *sortedArray = [NSArray new];
    if (allIssuesArray.count >= 10) {
        sortedArray = [[allIssuesArray subarrayWithRange:NSMakeRange(0, 10)] sortedArrayUsingDescriptors:sortDescriptors];
    }
    
    _popularIssuesArray = sortedArray;
    
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

- (void)getCoreDataBundle
{
    NSArray *coreDataBundleArray = [LBXBundle MR_findAllSortedBy:@"releaseDate" ascending:NO];
    LBXBundle *bundle;
    if (coreDataBundleArray.firstObject) {
        bundle = coreDataBundleArray.firstObject;
        
        NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"completeTitle" ascending:YES];
        NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
        _bundleIssuesArray = [[bundle.issues allObjects] sortedArrayUsingDescriptors:descriptors];
        
        [self.topTableView reloadData];
        NSString *issuesString = @"ISSUES";
        if (bundle.issues.count == 1) {
            issuesString = @"ISSUE";
        }
        [_bundleButton setTitle:[NSString stringWithFormat:@"%lu %@", (unsigned long)bundle.issues.count, issuesString]
                       forState:UIControlStateNormal];
        [_bundleButton setNeedsDisplay];
    }
    else {
        [_bundleButton setTitle:@"0 ISSUES"
                       forState:UIControlStateNormal];
    }
    
}

- (void)fetchBundle
{
    if ([UICKeyChainStore stringForKey:@"id"]) {
        // Fetch the users bundles
        [self.client fetchBundleResourcesWithCompletion:^(NSArray *bundleArray, RKObjectRequestOperation *response, NSError *error) {
            
            if (!error) {
                // Get the bundles from Core Data
                [self getCoreDataBundle];
            
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
        LBXIssueDetailViewController *titleViewController = [[LBXIssueDetailViewController alloc] initWithMainImage:dict[@"image"]];
        titleViewController.issue = issue;
        [self.navigationController pushViewController:titleViewController animated:YES];
    }
}

- (void)settingsPressed
{
    UIViewController *newVC = [LBXLoginViewController new];;
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
            // Pressing the your bundle/issues button
            LBXWeekViewController *controller = [[LBXWeekViewController alloc] initWithIssues:_bundleIssuesArray andTitle:@"Your Issues"];
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
    }
}

#pragma mark TableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.browseTableView) return 3;
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
            [self getCoreDataBundle];
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
        
        NSArray *imageArray = @[comicsImage, calendarIconImage, pullListIconImage];
        NSArray *textArray = @[@"Comics", @"Releases", @"Your Pull List"];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = [textArray objectAtIndex:indexPath.row];
        cell.textLabel.font = [UIFont browseTableViewFont];
        cell.imageView.image = [imageArray objectAtIndex:indexPath.row];
        
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
                LBXPublisherViewController *controller = [LBXPublisherViewController new];
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
        }
    }
}

@end
