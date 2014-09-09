//
//  LBXWeekTableViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXWeekTableViewController.h"
#import "LBXPullListTableViewCell.h"
#import "LBXClient.h"
#import "UIFont+customFonts.h"
#import "LBXNavigationViewController.h"

@interface LBXWeekTableViewController ()

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, copy) LBXClient *client;
@property (nonatomic) NSDate *date;
@property (nonatomic, copy) NSArray *issuesForWeekArray;

@end

@implementation LBXWeekTableViewController

LBXNavigationViewController *navigationController;

static const NSUInteger ISSUE_TABLE_HEIGHT = 88;

NSInteger tableViewRows;
CGFloat cellWidth;
BOOL endOfPages;
int page;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _client = [LBXClient new];
    
    page = 1;
    endOfPages = NO;
    tableViewRows = 0;
    
    _issuesForWeekArray = [NSArray new];
    
    // Add refresh
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshControlAction)
              forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    [self refreshControlAction];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar.backItem.backBarButtonItem setImageInsets:UIEdgeInsetsMake(40, 40, -40, 40)];
    [self.navigationController.navigationBar setBackIndicatorImage:
     [UIImage imageNamed:@"arrow"]];
    [self.navigationController.navigationBar setBackIndicatorTransitionMaskImage:
     [UIImage imageNamed:@"arrow"]];
    
    self.tableView.rowHeight = ISSUE_TABLE_HEIGHT;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.topItem.title = @"Next Week";
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    navigationController = (LBXNavigationViewController *)self.navigationController;
    [navigationController.menu setNeedsLayout];
}

#pragma mark Private Methods

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)refreshControlAction
{
    [self.refreshControl beginRefreshing];
    [self refreshViewWithPage:@1];
}

- (void)refreshViewWithPage:(NSNumber *)page
{
    // Fetch this weeks comics
    [self.client fetchThisWeeksComicsWithPage:page completion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            if (pullListArray.count == 0) {
                endOfPages = YES;
            }
            else {
                // Get this week date for fetching
                // from core data later
                LBXIssue *issue = pullListArray[0];
//                _thisWeekDate = issue.releaseDate;
            }
            
//            [self setThisWeeksComicsArrayWithLatestIssues];
            _issuesForWeekArray = pullListArray;
            tableViewRows = _issuesForWeekArray.count;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self.refreshControl endRefreshing];
            });
        }
        else {
            //[LBXMessageBar displayError:error];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
            });
        }
    }];
}

#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    if(section == 0) {
//        UIView *transparentView = [[UIView alloc] initWithFrame:_overView.bounds];
//        [transparentView setBackgroundColor:[UIColor clearColor]];
//        return transparentView;
//    }
//    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    if(section == 0)
//        return _overView.frame.size.height;
    
    return 0.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0)
        return _issuesForWeekArray.count;
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PullListCell";
    
    LBXPullListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        // Custom cell as explained here: https://medium.com/p/9bee5824e722
        [tableView registerNib:[UINib nibWithNibName:@"LBXPullListTableViewCell" bundle:nil] forCellReuseIdentifier:@"PullListCell"];
        cell = [tableView dequeueReusableCellWithIdentifier:@"PullListCell"];
    }
    
    cell.titleLabel.font = [UIFont pullListTitleFont];
    
    LBXIssue *issue = [_issuesForWeekArray objectAtIndex:indexPath.row];
    cell.titleLabel.text = issue.title.name;
    
    [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[UIImage imageNamed:@"black"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
        // Only fade in the image if it was fetched (not from cache)
        if (request) {
            [UIView transitionWithView:cell.latestIssueImageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{cell.latestIssueImageView.image = image;}
                            completion:NULL];
        }
        else {
            cell.latestIssueImageView.image = image;
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
        cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
    }];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(LBXPullListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    if (_issuesForWeekArray.count <= indexPath.row) {
        return;
    }
    
    LBXIssue *issue = [_issuesForWeekArray objectAtIndex:indexPath.row];
    
    cell.titleLabel.font = [UIFont pullListTitleFont];
    cell.titleLabel.text = issue.completeTitle;
    cell.titleLabel.numberOfLines = 2;
    cell.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    cell.subtitleLabel.font = [UIFont pullListSubtitleFont];
    cell.subtitleLabel.textColor = [UIColor grayColor];
    cell.subtitleLabel.numberOfLines = 2;
    
    //[LBXTitleAndPublisherServices setTitleCell:cell withIssue:issue];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    // Setting the background color of the cell.
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
}


@end
