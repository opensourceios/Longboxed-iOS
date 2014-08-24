//
//  LBXPublisherDetailViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/23/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXPublisherDetailViewController.h"
#import "LBXClient.h"
#import "LBXMessageBar.h"
#import "LBXPullListTableViewCell.h"
#import "LBXPullListTitle.h"
#import "LBXPublisherDetailView.h"
#import "LBXTitleDetailViewController.h"
#import "LBXTitle.h"
#import "LBXTitleServices.h"
#import "LBXIssueDetailViewController.h"
#import "LBXIssueScrollViewController.h"

#import "UIFont+customFonts.h"
#import "NSArray+ArrayUtilities.h"

#import <SVProgressHUD.h>
#import <QuartzCore/QuartzCore.h>

@interface LBXPublisherDetailViewController () <UIScrollViewDelegate>

@property (nonatomic, copy) LBXPublisher *detailPublisher;
@property (nonatomic, copy) LBXClient *client;
@property (nonatomic, copy) LBXPublisherDetailView *detailView;
@property (nonatomic, copy) NSArray *titlesForPublisherArray;
@property (nonatomic) NSNumber *page;

@end

@implementation LBXPublisherDetailViewController

static const NSUInteger ISSUE_TABLE_HEIGHT = 88;
BOOL endOfIssues;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Calls perferredStatusBarStyle
    [self setNeedsStatusBarAppearanceUpdate];
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"clear"] style:UIBarButtonItemStylePlain target:self action:nil];
    self.navigationItem.rightBarButtonItem = actionButton;
    self.title = _detailPublisher.name;
    
    endOfIssues = NO;
    
    _client = [LBXClient new];
    
    [self createTitlesArray];
    
    [self setDetailView];
    [self setOverView:_detailView];
    
    [self fetchPublisher];
    [self fetchPullList];
    [self fetchAllTitlesWithPage:@1];
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
    
    if (_detailView.latestIssueImageView.image.size.height > 200.0) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                      forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        
        self.navigationController.navigationBar.translucent = YES;
        self.navigationController.view.backgroundColor = [UIColor clearColor];
    }
    else {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
    }
    
    [self setNavBarAlpha:@0];
    
    // Keep the section header on the top
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 64, 0);
    
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBar.topItem.title = _detailPublisher.name;
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
    if (self.tableView.contentOffset.y > 0) {
        // Set the title alpha properly when returning from the issue view
        [self setNavBarAlpha:@(1 - self.overView.alpha)];
    }
    else {
        [self setNavBarAlpha:@0];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self setNavBarAlpha:@1];
    self.navigationController.navigationBar.topItem.title = @" ";
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

- (void)setDetailView
{
    _detailView = [LBXPublisherDetailView new];
    _detailView.frame = self.overView.frame;
    _detailView.bounds = self.overView.bounds;
    _detailView.titleLabel.font = [UIFont titleDetailTitleFont];
    _detailView.titleLabel.numberOfLines = 2;
    [_detailView.titleLabel sizeToFit];
    _detailView.publisherButton.titleLabel.font = [UIFont titleDetailPublisherFont];
    
    [self updateDetailView];
    
    _detailView.addToPullListButton.titleLabel.font = [UIFont titleDetailAddToPullListFont];
    _detailView.addToPullListButton.layer.borderWidth = 1.0f;
    _detailView.addToPullListButton.layer.cornerRadius = 19.0f;
    _detailView.latestIssueImageView.image = _publisherImage;
    [_detailView.latestIssueImageView sizeToFit];
}

- (void)updateDetailView
{
    _detailView.titleLabel.text = _detailPublisher.name;
    [_detailView.publisherButton setTitle:[_detailPublisher.name uppercaseString] forState:UIControlStateNormal];
    
    NSString *issuesString;
    if ([_detailPublisher.titleCount isEqualToNumber:@1]) {
        issuesString = [NSString stringWithFormat:@"%@ Title", _detailPublisher.titleCount];
    }
    else {
        issuesString = [NSString stringWithFormat:@"%@ Titles", _detailPublisher.titleCount];
    }
    
    NSString *subscribersString;
    if ([_detailPublisher.issueCount isEqualToNumber:@1]) {
        subscribersString = [NSString stringWithFormat:@"%@ Issue", _detailPublisher.issueCount];
    }
    else {
        subscribersString = [NSString stringWithFormat:@"%@ Issues", _detailPublisher.issueCount];
    }
    
    _detailView.issuesAndSubscribersLabel.text = [NSString stringWithFormat:@"%@  •  %@", [issuesString uppercaseString], [subscribersString uppercaseString]];
    _detailView.issuesAndSubscribersLabel.font = [UIFont titleDetailSubscribersAndIssuesFont];
    
    [self.view setNeedsDisplay];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Private methods

- (void)setDetailPublisherWithID:(NSNumber *)ID
{
    _detailPublisher = [LBXPublisher MR_findFirstByAttribute:@"publisherID" withValue:ID];
}

- (void)fetchPullList
{
    // Fetch pull list titles
    [_client fetchPullListWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [self createTitlesArray];
        }
        else {
            [LBXMessageBar displayError:error];
        }
        [self.view setNeedsDisplay];
    }];
}

- (void)fetchPublisher
{
    [_client fetchPublisher:_publisherID withCompletion:^(LBXPublisher *publisher, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            _detailPublisher = publisher;
            [self updateDetailView];
        }
        else {
            [LBXMessageBar displayError:error];
        }
        [self.view setNeedsDisplay];
    }];
}

- (void)fetchAllTitlesWithPage:(NSNumber *)page
{
    // Fetch pull list titles
    [_client fetchTitlesForPublisher:_publisherID withCompletion:^(NSArray *titleArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            if (titleArray.count == 0) {
                endOfIssues = YES;
            }
            
            [self createTitlesArray];
        }
        else {
            [LBXMessageBar displayError:error];
        }
        [self.tableView reloadData];
        [self.view setNeedsDisplay];
    }];
}

- (void)createTitlesArray
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(publisher == %@)", _detailPublisher];
    _titlesForPublisherArray = [LBXTitle MR_findAllSortedBy:@"name" ascending:YES withPredicate:predicate];
}

- (void)setNavBarAlpha:(NSNumber *)alpha
{
    if (_detailView.latestIssueImageView.image.size.height > 200.0) {
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:[alpha doubleValue]], NSFontAttributeName : [UIFont navTitleFont]}];
    }
    else {
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor], NSFontAttributeName : [UIFont navTitleFont]}];
    }
}

#pragma mark - Setter overrides

- (void)setPublisherID:(NSNumber *)publisherID
{
    _publisherID = publisherID;
    [self setDetailPublisherWithID:publisherID];
}

#pragma mark - UITableView Delegate & Datasource

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return [super tableView:tableView viewForHeaderInSection:section];
    
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Background color
    view.tintColor = [UIColor whiteColor];
    
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor blackColor]];
    header.textLabel.font = [UIFont titleDetailSubscribersAndIssuesFont];
    
    // Another way to set the background color
    // Note: does not preserve gradient effect of original header
    // header.contentView.backgroundColor = [UIColor blackColor];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 1)
        return @"Issues";
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return [super tableView:tableView heightForHeaderInSection:section];
    
    if(section == 1)
        return 18.0;
    
    return 0.0;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger mySections = 1;
    
    return mySections + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section != 1) {
        return 0;
    }
    if (_titlesForPublisherArray.count <= 3) {
        return 3;
    }
    
    return _titlesForPublisherArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PullListCell";
    
    LBXPullListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        // Custom cell as explained here: https://medium.com/p/9bee5824e722
        [tableView registerNib:[UINib nibWithNibName:@"LBXPullListTableViewCell" bundle:nil] forCellReuseIdentifier:@"PullListCell"];
        cell = [tableView dequeueReusableCellWithIdentifier:@"PullListCell"];
        
        // Remove inset of iOS 7 separators.
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsZero;
        }
        
    }
    
    if ([indexPath row] == _titlesForPublisherArray.count - 1 && !endOfIssues) {
        int value = [_page integerValue];
        _page = [NSNumber numberWithInt:value+1];
        [self fetchAllTitlesWithPage:_page];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(LBXPullListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    if (_titlesForPublisherArray.count <= indexPath.row) {
        return;
    }
    
    LBXTitle *title = [_titlesForPublisherArray objectAtIndex:indexPath.row];
    
    cell.titleLabel.font = [UIFont pullListTitleFont];
    cell.titleLabel.text = title.name;
    cell.titleLabel.numberOfLines = 2;
    cell.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    cell.subtitleLabel.font = [UIFont pullListSubtitleFont];
    cell.subtitleLabel.textColor = [UIColor grayColor];
    cell.subtitleLabel.numberOfLines = 2;
    
    cell.latestIssueImageView.image = nil;
    
    [LBXTitleServices setCell:cell withTitle:title];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    // Setting the background color of the cell.
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y > 0) {
        [self setNavBarAlpha:@(1 - self.overView.alpha)];
    }
    else {
        [self setNavBarAlpha:@0];
    }
    return [super scrollViewDidScroll:scrollView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LBXPullListTableViewCell *cell = (LBXPullListTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    LBXTitleDetailViewController *titleViewController = [[LBXTitleDetailViewController alloc] initWithMainImage:cell.latestIssueImageView.image andTopViewFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * 3/4)];
    
    LBXTitle *title = [_titlesForPublisherArray objectAtIndex:indexPath.row];
    titleViewController.titleID = title.titleID;
    titleViewController.latestIssueImage = cell.latestIssueImageView.image;
    [self.navigationController pushViewController:titleViewController animated:YES];
}

@end
