//
//  LBXDashboardViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/27/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXDashboardViewController.h"
#import "LBXNavigationViewController.h"
#import "TableViewCell.h"
#import "LBXClient.h"
#import "LBXBundle.h"

#import <UICKeyChainStore.h>

@interface LBXDashboardViewController ()

@property (nonatomic, strong) LBXClient *client;
@property (nonatomic, strong) NSArray *popularIssuesArray;
@property (nonatomic, strong) NSArray *bundleIssuesArray;

@end

@implementation LBXDashboardViewController

LBXNavigationViewController *navigationController;

@synthesize topTableView;
@synthesize bottomTableView;
@synthesize tableViewCell;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Do any additional setup after loading the view from its nib.
        //self.edgesForExtendedLayout = UIRectEdgeNone;
        // Custom initialization
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"longboxed_full"]];
        LBXNavigationViewController *navController = [LBXNavigationViewController new];
        [navController addPaperButtonToViewController:self];
        UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
        self.navigationItem.rightBarButtonItem = actionButton;
        [self.navigationItem.rightBarButtonItem setTintColor:[UIColor blackColor]];
        
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"longboxed_full"]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _client = [LBXClient new];
    [self refresh];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    navigationController = (LBXNavigationViewController *)self.navigationController;
    [navigationController.menu setNeedsLayout];
    self.topTableView.contentInset = UIEdgeInsetsZero;
}

#pragma mark Private Methods

- (void)refresh
{
    [self fetchPopularIssues];
    [self fetchBundle];
}

- (void)fetchPopularIssues
{
    // Fetch this weeks comics
    [self.client fetchPopularIssuesWithCompletion:^(NSArray *popularIssuesArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            _popularIssuesArray = popularIssuesArray;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.bottomTableView reloadData];
            });
        }
        else {
            //[LBXMessageBar displayError:error];
        }
    }];
}

- (void)fetchBundle
{
    if ([UICKeyChainStore stringForKey:@"id"]) {
        // Fetch the users bundles
        [self.client fetchBundleResourcesWithCompletion:^(NSArray *bundleArray, RKObjectRequestOperation *response, NSError *error) {
            
            if (!error) {
                // Get the bundles from Core Data
                NSArray *coreDataBundleArray = [LBXBundle MR_findAllSortedBy:@"releaseDate" ascending:NO];
                LBXBundle *bundle;
                if (coreDataBundleArray.firstObject) {
                    bundle = bundleArray.firstObject;
                    _bundleIssuesArray = [bundle.issues allObjects];
                }
                
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

#pragma mark TableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    return @"Title for header in section";
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.frame.size.height+100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    TableViewCell *cell = (TableViewCell*)[self.topTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (tableView == self.bottomTableView) {
        cell = (TableViewCell*)[self.bottomTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    }
    [cell setBackgroundColor:[UIColor clearColor]];
    if (!cell) {
        [[NSBundle mainBundle] loadNibNamed:@"TableViewCell" owner:self options:nil];
        
        CGAffineTransform rotateTable = CGAffineTransformMakeRotation(-M_PI_2);
        tableViewCell.horizontalTableView.transform = rotateTable;
        tableViewCell.horizontalTableView.frame = CGRectMake(0, 0, tableViewCell.horizontalTableView.frame.size.width, tableViewCell.horizontalTableView.frame.size.height);
        
        tableViewCell.horizontalTableView.allowsSelection = YES;
        cell = tableViewCell;
    }
    
    if (tableView == self.bottomTableView) {
        tableViewCell.contentArray = _popularIssuesArray;
        if (_popularIssuesArray.count) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"reloadTableView"
             object:self];
        }
    }
    else if (tableView == self.topTableView) {
        tableViewCell.contentArray = _bundleIssuesArray;
        if (_bundleIssuesArray.count) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"reloadTableView"
             object:self];
        }
    }
    
    cell = tableViewCell;
    cell.selectedBackgroundView.backgroundColor = [UIColor orangeColor];
    return cell;
}

@end
