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
#import "LBXTitleAndPublisherServices.h"
#import "LBXIssueDetailViewController.h"
#import "LBXIssueScrollViewController.h"
#import "LBXLogging.h"

#import "UIFont+customFonts.h"
#import "NSArray+ArrayUtilities.h"
#import "UIColor+customColors.h"

#import <SVProgressHUD.h>
#import <QuartzCore/QuartzCore.h>

@interface LBXPublisherDetailViewController () <UIScrollViewDelegate>

@property (nonatomic, copy) LBXPublisher *detailPublisher;
@property (nonatomic, copy) LBXClient *client;
@property (nonatomic, copy) LBXPublisherDetailView *detailView;
@property (nonatomic, copy) UIImage *publisherImage;
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
    self.navigationController.navigationBar.topItem.title = @"";
    
    endOfIssues = NO;
    
    _client = [LBXClient new];

    [self setDetailPublisher];
    [self fetchPublisher];
    [self createTitlesArray];
    
    [self setDetailView];
    [self setOverView:_detailView];
    
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
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    
    // Keep the section header on the top
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 64, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
    if (self.tableView.contentOffset.y > 0) {
        // Set the title alpha properly when returning from the issue view
        [self setNavBarAlpha:@(1 - self.overView.alpha)];
    }
    else {
        [self setNavBarAlpha:@0];
    }
    self.title = _detailPublisher.name;
    self.navigationController.navigationBar.topItem.title = _detailPublisher.name;
    
    [LBXLogging logMessage:[NSString stringWithFormat:@"LBXPublisher\n%@\ndid appear", _detailPublisher]];
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
    _detailView.titleLabel.numberOfLines = 0;
    _detailView.titleLabel.preferredMaxLayoutWidth = 200;
    
    [self updateDetailView];
    
    [_detailView.latestIssueImageView sizeToFit];
}

- (void)updateDetailView
{
    _detailView.titleLabel.text = _detailPublisher.name;
    
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
    [_detailView.issuesAndSubscribersLabel sizeToFit];
    
    if (_titlesForPublisherArray.count <= self.tableView.visibleCells.count) {
        _detailView.loadingLabel.text = @"LOADING TITLES...";
        _detailView.loadingLabel.font = [UIFont titleDetailSubscribersAndIssuesFont];
    }
    // When loading the title info
    if ([_detailPublisher.issueCount isEqual:@0]) {
        _detailView.issuesAndSubscribersLabel.text = @"";
        _detailView.loadingLabel.text = @"LOADING TITLES...";
        _detailView.loadingLabel.font = [UIFont titleDetailSubscribersAndIssuesFont];
    }
    
    [self.view setNeedsDisplay];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Private methods

- (void)setDetailPublisher
{
    _detailPublisher = [LBXPublisher MR_findFirstByAttribute:@"publisherID" withValue:_publisherID];
}

- (void)fetchPublisher
{
    [_client fetchPublisher:_publisherID withCompletion:^(LBXPublisher *publisher, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            _detailPublisher = publisher;
            
            // Set the background color to the gradient
            UIColor *primaryColor = [UIColor colorWithHex:publisher.primaryColor];
            UIColor *secondaryColor = [UIColor colorWithHex:publisher.secondaryColor];
            CGSize size = CGSizeMake(self.detailView.latestIssueImageView.frame.size.width, self.detailView.latestIssueImageView.frame.size.width);
            UIGraphicsBeginImageContext(size);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
            size_t gradientNumberOfLocations = 2;
            CGFloat gradientLocations[2] = { 0.0, 1.0 };
            CGFloat gradientComponents[8] = {CGColorGetComponents(primaryColor.CGColor)[0], CGColorGetComponents(primaryColor.CGColor)[1], CGColorGetComponents(primaryColor.CGColor)[2], 1.0,     // Start color
                CGColorGetComponents(secondaryColor.CGColor)[0], CGColorGetComponents(secondaryColor.CGColor)[1], CGColorGetComponents(secondaryColor.CGColor)[2], 1.0, };  // End color
            CGGradientRef gradient = CGGradientCreateWithColorComponents (colorspace, gradientComponents, gradientLocations, gradientNumberOfLocations);
            CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, size.height), 0);
            
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            [self setCustomBackgroundImageWithImage:image];
            
            [self updateDetailView];
            [self setDetailPublisher];
                //Configure the view
            __block typeof(self) bself = self;
            [self.detailView.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:publisher.mediumLogo]] placeholderImage:[UIImage imageNamed:@"clear"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                
                [UIView transitionWithView:bself.detailView.latestIssueImageView
                                  duration:0.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{bself.detailView.latestIssueImageView.image = image;}
                                completion:NULL];
                
                
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                
                [UIView transitionWithView:bself.detailView.latestIssueImageView
                                  duration:0.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{bself.detailView.latestIssueImageView.image = self.mainImageView.image;}
                                completion:NULL];
                [bself setCustomBackgroundImageWithImage:image];
            }];
        }
        else {
            //[LBXMessageBar displayError:error];
        }
        [self.view setNeedsDisplay];
    }];
}

- (void)fetchAllTitlesWithPage:(NSNumber *)page
{
    if ([page intValue] > 1 && !endOfIssues) {
        // Add a footer loading spinner
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [spinner startAnimating];
        spinner.frame = CGRectMake(0, 0, 320, 44);
        self.tableView.tableFooterView = spinner;
    }
    
    // Fetch pull list titles
    [_client fetchTitlesForPublisher:_publisherID page:page withCompletion:^(NSArray *titleArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            if (titleArray.count == 0 || [_detailPublisher.titleCount intValue] == _titlesForPublisherArray.count) {
                endOfIssues = YES;
                self.tableView.tableFooterView = nil;
            }
            [self fetchAllIssuesWithTitleArray:titleArray];
        }
        else {
            //[LBXMessageBar displayError:error];
        }
        [self.tableView reloadData];
        [self.view setNeedsDisplay];
    }];
}

- (void)fetchAllIssuesWithTitleArray:(NSArray *)titleArray
{
    __block NSUInteger i = 1;
    for (LBXTitle *title in titleArray) {
        [self.client fetchIssuesForTitle:title.titleID page:@1 withCompletion:^(NSArray *issuesArray, RKObjectRequestOperation *response, NSError *error) {
            // Wait until all titles in _pullListArray have been fetched
            if (i == titleArray.count) {
                if (!error) {
                    [self createTitlesArray];
                    [UIView transitionWithView:_detailView.loadingLabel
                                      duration:1.0f
                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                    animations:^{_detailView.loadingLabel.alpha = 0;}
                                    completion:NULL];
                }
                else {
                    //[LBXMessageBar displayError:error];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }
            i++;
        }];
    }
}

- (void)createTitlesArray
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(publisher == %@)", _detailPublisher];
    _titlesForPublisherArray = [LBXTitle MR_findAllSortedBy:@"name" ascending:YES withPredicate:predicate];
}

- (void)setNavBarAlpha:(NSNumber *)alpha
{
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:[alpha doubleValue]], NSFontAttributeName : [UIFont navTitleFont]}];
}

#pragma mark - Setter overrides

- (void)setPublisherID:(NSNumber *)publisherID
{
    _publisherID = publisherID;
    [self setDetailPublisher];
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
    view.tintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8];
    
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
        return @"Titles";
    
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
    
    if (indexPath.row == _titlesForPublisherArray.count - 1 && !endOfIssues) {
        _page = [NSNumber numberWithInt:[_page integerValue]+1];
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
    
    [LBXTitleAndPublisherServices setPublisherCell:cell withTitle:title];
    
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
    [LBXLogging logMessage:[NSString stringWithFormat:@"Selected title %@", title]];
    titleViewController.titleID = title.titleID;
    titleViewController.latestIssueImage = cell.latestIssueImageView.image;
    [self.navigationController pushViewController:titleViewController animated:YES];
}

@end
