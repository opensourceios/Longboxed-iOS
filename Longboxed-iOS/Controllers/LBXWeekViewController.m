//
//  LBXWeekTableViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXWeekViewController.h"
#import "LBXWeekTableViewCell.h"
#import "LBXClient.h"
#import "UIFont+customFonts.h"
#import "LBXNavigationViewController.h"
#import "LBXIssueScrollViewController.h"
#import "LBXIssueDetailViewController.h"
#import "NSDate+DateUtilities.h"

#import "LBXLogging.h"

#import "Masonry.h"

@interface LBXWeekViewController () <UIToolbarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UIToolbar *toolBar;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, copy) LBXClient *client;
@property (nonatomic, copy) NSArray *issuesForWeekArray;

@end

@implementation LBXWeekViewController

LBXNavigationViewController *navigationController;

static const NSUInteger ISSUE_TABLE_HEIGHT = 88;

NSInteger tableViewRows;
CGFloat cellWidth;
BOOL endOfPages;
int page;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _client = [LBXClient new];
    
    page = 1;
    endOfPages = NO;
    tableViewRows = 0;
    
    _issuesForWeekArray = [NSArray new];
    
    _tableView = [UITableView new];
    _tableView.frame = self.view.frame;
    _tableView.delegate = self;
    _tableView.dataSource = self;

    [self.view addSubview:_tableView];
    
    NSArray *itemArray = [NSArray arrayWithObjects: @"This Week", @"Next Week", nil];
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    [_segmentedControl addTarget:self
                          action:@selector(segmentedControlToggle:)
                forControlEvents:UIControlEventValueChanged];
    _segmentedControl.selectedSegmentIndex = 0;
    _toolBar = [UIToolbar new];
    _toolBar.frame = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y, self.view.frame.size.width, self.navigationController.navigationBar.frame.size.height*2);

    _toolBar.delegate = self;
    [_toolBar addSubview:self.segmentedControl];
    [self setToolbarItems:@[_segmentedControl]];
    [self.view addSubview:_toolBar];
    
    // Autolayout the segmented control
    [_segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(_toolBar.mas_centerY).with.offset(self.navigationController.navigationBar.frame.size.height-8);
//        make.centerX.equalTo(self.view);
        make.edges.equalTo(_toolBar).insets(UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height+8, 16, 8, 16));
    }];
    _segmentedControl.tintColor = [UIColor blackColor];
    
    _tableView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height, 0, 0, 0);
    _tableView.scrollIndicatorInsets = _tableView.contentInset;
    
    // Add refresh
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshControlAction)
              forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [self.navigationController.navigationBar.backItem.backBarButtonItem setImageInsets:UIEdgeInsetsMake(40, 40, -40, 40)];
    [self.navigationController.navigationBar setBackIndicatorImage:
     [UIImage imageNamed:@"arrow"]];
    [self.navigationController.navigationBar setBackIndicatorTransitionMaskImage:
     [UIImage imageNamed:@"arrow"]];
    
    self.tableView.rowHeight = ISSUE_TABLE_HEIGHT;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
    
    [self setIssuesForWeekArrayWithThisWeekIssues];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.topItem.title = @"Releases";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
    
    if (_issuesForWeekArray.count == 0) {
        [self.refreshControl beginRefreshing];
        [self fetchThisWeekWithPage:@1];
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    navigationController = (LBXNavigationViewController *)self.navigationController;
    [navigationController.menu setNeedsLayout];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.topItem.title = @" ";
}


#pragma mark Private Methods

- (UIBarPosition)positionForBar:(id)bar {
    return UIBarPositionTopAttached;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (IBAction)segmentedControlToggle:(id)sender
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *) sender;
    NSInteger selectedSegment = segmentedControl.selectedSegmentIndex;
    
    if (selectedSegment == 0) {
        _issuesForWeekArray = nil;
        [self setIssuesForWeekArrayWithThisWeekIssues];
        [self.tableView reloadData];
        if (_issuesForWeekArray.count == 0) {
            [self.refreshControl beginRefreshing];
            [self fetchThisWeekWithPage:@1];
        }
    }
    else{
        _issuesForWeekArray = nil;
        [self setIssuesForWeekArrayWithNextWeekIssues];
        [self.tableView reloadData];
        if (_issuesForWeekArray.count == 0) {
            [self.refreshControl beginRefreshing];
            [self fetchThisWeekWithPage:@1];
        }
    }
}

- (void)refreshControlAction
{
    if (_segmentedControl.selectedSegmentIndex == 0) {
        [self fetchThisWeekWithPage:@1];
    }
    if (_segmentedControl.selectedSegmentIndex == 1) {
        [self fetchNextWeekWithPage:@1];
    }
    [self.refreshControl beginRefreshing];
    
}

- (void)setIssuesForWeekArrayWithThisWeekIssues
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(isParent == 1)"];
    NSArray *allIssuesArray = [LBXIssue MR_findAllSortedBy:@"publisher" ascending:YES withPredicate:predicate];
    if (allIssuesArray.count > 1) {
        NSDate *localDateTime = [NSDate dateWithTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT] sinceDate:[NSDate date]];
        NSMutableArray *nextWeekArray = [NSMutableArray new];
        for (LBXIssue *issue in allIssuesArray) {
            // Check if the issue is next week
            if ([issue.releaseDate timeIntervalSinceDate:localDateTime] > -4*DAY &&
                [issue.releaseDate timeIntervalSinceDate:localDateTime] < 7*DAY && issue.releaseDate) {
                NSLog(@"%@", issue.releaseDate);
                [nextWeekArray addObject:issue];
            }
        }
        _issuesForWeekArray = nextWeekArray;
        tableViewRows = _issuesForWeekArray.count;
    }
}

- (void)setIssuesForWeekArrayWithNextWeekIssues
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(isParent == 1)"];
    NSArray *allIssuesArray = [LBXIssue MR_findAllSortedBy:@"publisher" ascending:YES withPredicate:predicate];
    if (allIssuesArray.count > 1) {
        NSDate *localDateTime = [NSDate dateWithTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT] sinceDate:[NSDate date]];
        NSMutableArray *nextWeekArray = [NSMutableArray new];
        for (LBXIssue *issue in allIssuesArray) {
            // Check if the issue is next week
            if ([issue.releaseDate timeIntervalSinceDate:localDateTime] >= 7*DAY &&
                [issue.releaseDate timeIntervalSinceDate:localDateTime] < 7*2*DAY && issue.releaseDate) {
                [nextWeekArray addObject:issue];
            }
        }
        _issuesForWeekArray = nextWeekArray;
        tableViewRows = _issuesForWeekArray.count;
    }
}

- (void)completeRefreshWithArray:(NSArray *)array
{
    if (array.count == 0) {
        endOfPages = YES;
    }
    
    if (_segmentedControl.selectedSegmentIndex == 0) {
        [self setIssuesForWeekArrayWithThisWeekIssues];
    }
    if (_segmentedControl.selectedSegmentIndex == 1) {
        [self setIssuesForWeekArrayWithNextWeekIssues];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    });
}

- (void)fetchThisWeekWithPage:(NSNumber *)page
{
    // Fetch this weeks comics
    [self.client fetchThisWeeksComicsWithPage:page completion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [self completeRefreshWithArray:pullListArray];
        }
        else {
            //[LBXMessageBar displayError:error];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
            });
        }
    }];
}

- (void)fetchNextWeekWithPage:(NSNumber *)page
{
    // Fetch this weeks comics
    [self.client fetchNextWeeksComicsWithPage:page completion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [self completeRefreshWithArray:pullListArray];
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
    static NSString *CellIdentifier = @"WeekTableViewCell";
    
    LBXWeekTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        // Custom cell as explained here: https://medium.com/p/9bee5824e722
        [tableView registerNib:[UINib nibWithNibName:@"LBXWeekTableViewCell" bundle:nil] forCellReuseIdentifier:@"WeekTableViewCell"];
        cell = [tableView dequeueReusableCellWithIdentifier:@"WeekTableViewCell"];
    }
    
    cell.titleLabel.font = [UIFont pullListTitleFont];
    
    LBXIssue *issue = [_issuesForWeekArray objectAtIndex:indexPath.row];
    cell.titleLabel.text = issue.title.name;
    
    NSDate *localDateTime = [NSDate dateWithTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT] sinceDate:[NSDate date]];
    
    cell.subtitleLabel.text = [NSString stringWithFormat:@"Issue %@  •  $%.02f  •  %@", issue.issueNumber, [issue.price floatValue], [NSDate fuzzyTimeBetweenStartDate:issue.releaseDate andEndDate:localDateTime]].uppercaseString;
    
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(LBXWeekTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
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
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    // Setting the background color of the cell.
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Disselect and return immediately if selecting an empty cell
    // i.e., one below the last issue
    if (_issuesForWeekArray.count < indexPath.row+1) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    LBXIssue *issue = [_issuesForWeekArray objectAtIndex:indexPath.row];
    [LBXLogging logMessage:[NSString stringWithFormat:@"Selected issue %@", issue]];
    LBXWeekTableViewCell *cell = (LBXWeekTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    // Set up the scroll view controller containment if there are alternate issues
    if (issue.alternates.count) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(title == %@) AND (issueNumber == %@)", issue.title, issue.issueNumber];
        NSArray *issuesArray = [LBXIssue MR_findAllSortedBy:@"completeTitle" ascending:YES withPredicate:predicate];
        LBXIssueScrollViewController *scrollViewController = [[LBXIssueScrollViewController alloc] initWithIssues:issuesArray andImage:cell.latestIssueImageView.image];
        [self.navigationController pushViewController:scrollViewController animated:YES];
    }
    else {
        LBXIssueDetailViewController *titleViewController = [[LBXIssueDetailViewController alloc] initWithMainImage:cell.latestIssueImageView.image];
        titleViewController.issue = issue;
        [self.navigationController pushViewController:titleViewController animated:YES];
    }
    
}


@end
