//
//  LBXPublisherDetailViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/23/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXPublisherDetailViewController.h"
#import "LBXClient.h"
#import "LBXPullListTableViewCell.h"
#import "LBXPullListTitle.h"
#import "LBXTitleDetailViewController.h"
#import "LBXTitle.h"
#import "LBXControllerServices.h"
#import "LBXLogging.h"

#import "UIFont+LBXCustomFonts.h"
#import "NSArray+LBXArrayUtilities.h"
#import "UIColor+LBXCustomColors.h"
#import "UIImage+DrawOnImage.h"
#import "UIImage+LBXCreateImage.h"
#import "SVProgressHUD.h"

#import <QuartzCore/QuartzCore.h>

@interface LBXPublisherDetailViewController () <UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) LBXPublisher *detailPublisher;
@property (nonatomic, copy) LBXClient *client;
@property (nonatomic, copy) NSArray *titlesForPublisherArray;
@property (nonatomic, copy) NSArray *sectionArray;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIView *loadingView;

@end

@implementation LBXPublisherDetailViewController

static const NSUInteger ISSUE_TABLE_HEIGHT = 88;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Calls perferredStatusBarStyle
    [self setNeedsStatusBarAppearanceUpdate];
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"clear"] style:UIBarButtonItemStylePlain target:self action:nil];
    self.navigationItem.rightBarButtonItem = actionButton;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Add refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    _loadingView = [[UIView alloc] initWithFrame:self.view.frame];
    _loadingView.backgroundColor = [UIColor whiteColor];
    [SVProgressHUD setFont:[UIFont SVProgressHUDFont]];
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD setForegroundColor:[UIColor blackColor]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.rowHeight = ISSUE_TABLE_HEIGHT;
    
    [LBXControllerServices setViewWillAppearWhiteNavigationController:self];
    
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [LBXControllerServices setViewDidAppearWhiteNavigationController:self];
    self.navigationController.navigationBar.topItem.title = _detailPublisher.name;
    
    _client = [LBXClient new];
    [self setDetailPublisher];
    [self fetchPublisher];
    
    self.title = _detailPublisher.name;
        
    [self createTitlesArray];
    
    if (!_titlesForPublisherArray.count) {
        self.tableView.hidden = YES;
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    }
    
    [self refresh];
    
    [LBXLogging logMessage:[NSString stringWithFormat:@"LBXPublisher\n%@\ndid appear", _detailPublisher]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
    [SVProgressHUD setForegroundColor: [UIColor blackColor]];
    [SVProgressHUD setBackgroundColor: [UIColor whiteColor]];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
}

#pragma mark - Private methods

- (void)refresh
{
    [self fetchAllTitlesWithPage:@1];
}

- (void)setDetailPublisher
{
    _detailPublisher = [LBXPublisher MR_findFirstByAttribute:@"publisherID" withValue:_publisherID];
    
}

- (void)fetchPublisher
{
    [_client fetchPublisher:_publisherID withCompletion:^(LBXPublisher *publisher, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [self setDetailPublisher];
            
        }
        else {
            //[LBXMessageBar displayError:error];
        }
        [self.view setNeedsDisplay];
    }];
}

- (void)fetchAllTitlesWithPage:(NSNumber *)page
{
    // Fetch pull list titles
    [_client fetchTitlesForPublisher:_publisherID page:page withCompletion:^(NSArray *titleArray, RKObjectRequestOperation *response, NSError *error) {
        if (!error) {
            if (titleArray.count == 0 || [_detailPublisher.titleCount intValue] == _titlesForPublisherArray.count) {
                self.tableView.tableFooterView = nil;
                [self.refreshControl endRefreshing];
                [self createTitlesArray];
            }
            else {
                [self createTitlesArray];
                int value = [page intValue];
                [self fetchAllTitlesWithPage:[NSNumber numberWithInt:value + 1]];
            }
        }
        else {
            [self.refreshControl endRefreshing];
            //[LBXMessageBar displayError:error];
        }
    }];
}

- (void)createTitlesArray
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(publisher == %@)", _detailPublisher];
    _titlesForPublisherArray = [LBXTitle MR_findAllSortedBy:@"name" ascending:YES withPredicate:predicate];
    _sectionArray = [NSArray getAlphabeticalTableViewSectionArrayForArray:_titlesForPublisherArray];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self.view setNeedsDisplay];
    });
    if (self.tableView.hidden && _titlesForPublisherArray.count) {
        [_loadingView removeFromSuperview];
        self.tableView.hidden = NO;
        
        [SVProgressHUD dismiss];   
    }
}

#pragma mark - Setter overrides

- (void)setPublisherID:(NSNumber *)publisherID
{
    _publisherID = publisherID;
    [self setDetailPublisher];
}

#pragma mark - UITableView Delegate & Datasource

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if(section >= 0)
        return [super tableView:tableView viewForHeaderInSection:section];
    
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Background color
    view.tintColor = [UIColor colorWithHex:@"#E0E1E2"];
    
    // Text Color and font
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:[UIColor blackColor]];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont titleDetailSubscribersAndIssuesFont]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(section == 0) return [super tableView:tableView heightForHeaderInSection:section];
    
    else return 18.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) return 0;
    
    NSDictionary *dict = [_sectionArray objectAtIndex:section-1];
    return dict.allKeys.firstObject;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray *arr = [NSMutableArray new];
    for (NSDictionary *dict in _sectionArray) {
        [arr addObject:dict.allKeys[0]];
    }
    return arr;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    NSMutableArray *arr = [NSMutableArray new];
    for (NSDictionary *dict in _sectionArray) {
        [arr addObject:dict.allKeys[0]];
    }
    return [arr indexOfObject:title]+1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!_sectionArray.count) {
        return 1;
    }
    return _sectionArray.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 0;
    
    NSDictionary *dict = [_sectionArray objectAtIndex:section-1];
    NSArray *arr = [dict valueForKey:dict.allKeys[0]];
    return [arr count];
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
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(LBXPullListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    if (_titlesForPublisherArray.count <= indexPath.row) {
        return;
    }
    
    NSDictionary *dict = [_sectionArray objectAtIndex:indexPath.section-1];
    NSArray *array = [dict objectForKey:dict.allKeys[0]];
    LBXTitle *title = [array objectAtIndex:indexPath.row];
    
    cell.titleLabel.font = [UIFont pullListTitleFont];
    cell.titleLabel.text = title.name;
    cell.titleLabel.numberOfLines = 2;
    cell.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    cell.subtitleLabel.font = [UIFont pullListSubtitleFont];
    cell.subtitleLabel.textColor = [UIColor grayColor];
    cell.subtitleLabel.numberOfLines = 2;
    
    cell.latestIssueImageView.image = nil;
    
    [LBXControllerServices setPublisherCell:cell withTitle:title];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    // Setting the background color of the cell.
    cell.contentView.backgroundColor = [UIColor whiteColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = [_sectionArray objectAtIndex:indexPath.section-1];
    NSArray *array = [dict objectForKey:dict.allKeys[0]];
    LBXTitle *title = [array objectAtIndex:indexPath.row];
    
    LBXPullListTableViewCell *cell = (LBXPullListTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    LBXTitleDetailViewController *titleViewController = [[LBXTitleDetailViewController alloc] initWithTitle:title];
    
    [LBXLogging logMessage:[NSString stringWithFormat:@"Selected title %@", title]];
    titleViewController.titleID = title.titleID;
    titleViewController.latestIssueImage = cell.latestIssueImageView.image;
    [self.navigationController pushViewController:titleViewController animated:YES];
}

@end
