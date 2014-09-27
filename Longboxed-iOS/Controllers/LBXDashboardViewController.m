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

@interface LBXDashboardViewController ()

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
    [self.topTableView reloadData];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    navigationController = (LBXNavigationViewController *)self.navigationController;
    [navigationController.menu setNeedsLayout];
    self.topTableView.contentInset = UIEdgeInsetsZero;
}

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
//    TableViewCell *cell = (TableViewCell*)[self.bottomTableView dequeueReusableCellWithIdentifier:CellIdentifier];
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
        if (tableView == self.topTableView) {
            //tableViewCell.horizontalTableView.frame = CGRectMake(0, -86, tableViewCell.horizontalTableView.frame.size.width, tableViewCell.horizontalTableView.frame.size.height);
//            tableViewCell.horizontalTableView.
        }
        
        tableViewCell.contentArray = @[@{@"ImageName" : @"NotAvailable.jpeg",
                                         @"PubDate" : [NSDate date],
                                         @"Title" : @"This just in: Bananas are tasty!"},
                                       @{@"ImageName" : @"black-spiderman.jpg",
                                         @"PubDate" : [NSDate date],
                                         @"Title" : @"This just in: Bananas are tasty!"},
                                       @{@"ImageName" : @"thor-hulk.jpg",
                                         @"PubDate" : [NSDate date],
                                         @"Title" : @"This just in: Bananas are tasty!"},
                                       @{@"ImageName" : @"thor-hulk.jpg",
                                         @"PubDate" : [NSDate date],
                                         @"Title" : @"This just in: Bananas are tasty!"}];
        
        tableViewCell.horizontalTableView.allowsSelection = YES;
        cell = tableViewCell;
        //self.tableViewCell = nil;
        
    }
    cell.selectedBackgroundView.backgroundColor = [UIColor orangeColor];
    return cell;
}

@end
