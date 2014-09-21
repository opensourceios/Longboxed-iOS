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
#import "LBXNavigationViewController.h"
#import "LBXLogging.h"

#import "UIFont+customFonts.h"
#import "NSArray+ArrayUtilities.h"
#import "UIColor+customColors.h"

#import <SVProgressHUD.h>
#import <QuartzCore/QuartzCore.h>
#import <POP.h>

@interface LBXPublisherDetailViewController () <UIScrollViewDelegate>

@property (nonatomic, copy) LBXPublisher *detailPublisher;
@property (nonatomic, copy) LBXClient *client;
@property (nonatomic, copy) LBXPublisherDetailView *detailView;
@property (nonatomic, copy) UIImage *publisherImage;
@property (nonatomic, copy) NSArray *titlesForPublisherArray;
@property (nonatomic, copy) NSArray *sectionArray;
@property (nonatomic, strong) UIView *loadingView;

@end

@implementation LBXPublisherDetailViewController

LBXNavigationViewController *navigationController;

static const NSUInteger ISSUE_TABLE_HEIGHT = 88;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Calls perferredStatusBarStyle
    [self setNeedsStatusBarAppearanceUpdate];
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"clear"] style:UIBarButtonItemStylePlain target:self action:nil];
    self.navigationItem.rightBarButtonItem = actionButton;
    self.navigationController.navigationBar.topItem.title = @"";
    
    _client = [LBXClient new];

    [self setDetailPublisher];
    [self fetchPublisher];
    [self createTitlesArray];
    
    [self setDetailView];
    [self setOverView:_detailView];
    
    _loadingView = [[UIView alloc] initWithFrame:self.view.frame];
    _loadingView.backgroundColor = [UIColor whiteColor];
    [SVProgressHUD setFont:[UIFont SVProgressHUDFont]];
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD setForegroundColor:[UIColor blackColor]];
    
    [self fetchAllTitlesWithPage:@1];
    
    self.tableView.hidden = YES;
    [self.view insertSubview:_loadingView aboveSubview:_detailView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
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
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    navigationController = (LBXNavigationViewController *)self.navigationController;
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
    
    [SVProgressHUD show];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
    
    [self.view setNeedsDisplay];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Private methods

- (void)setNavBarAlpha:(NSNumber *)alpha
{
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:[alpha doubleValue]], NSFontAttributeName : [UIFont navTitleFont]}];
}

- (void)setDetailPublisher
{
    _detailPublisher = [LBXPublisher MR_findFirstByAttribute:@"publisherID" withValue:_publisherID];
}

- (void)fetchPublisher
{
    [_client fetchPublisher:_publisherID withCompletion:^(LBXPublisher *publisher, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            
            CGSize size = CGSizeMake(self.detailView.latestIssueImageView.frame.size.width, self.view.frame.size.width);
            
            UIImage *colorImage = [LBXTitleAndPublisherServices generateImageForPublisher:_detailPublisher size:size];
            
            __block typeof(self) bself = self;
            
            //Configure the view
            // Background
            [self.mainImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:publisher.mediumSplash]] placeholderImage:colorImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                
                [bself setCustomBlurredBackgroundImageWithImage:image];
                
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                [bself setCustomBackgroundImageWithImage:colorImage];
            }];
            
            [self updateDetailView];
            [self setDetailPublisher];
            
            // Main image (publisher's logo)
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
    // Fetch pull list titles
    [_client fetchTitlesForPublisher:_publisherID page:page withCompletion:^(NSArray *titleArray, RKObjectRequestOperation *response, NSError *error) {
        if (!error) {
            if (titleArray.count == 0 || [_detailPublisher.titleCount intValue] == _titlesForPublisherArray.count) {
                self.tableView.tableFooterView = nil;
                [self createTitlesArray];
            }
            else {
                [self createTitlesArray];
                int value = [page intValue];
                [self fetchAllTitlesWithPage:[NSNumber numberWithInt:value + 1]];
            }
        }
        else {
            //[LBXMessageBar displayError:error];
        }
    }];
}

- (void)createTitlesArray
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(publisher == %@)", _detailPublisher];
    _titlesForPublisherArray = [LBXTitle MR_findAllSortedBy:@"name" ascending:YES withPredicate:predicate];
    [self generateSectionArray];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self.view setNeedsDisplay];
    });
    if (self.tableView.hidden) {
        [_loadingView removeFromSuperview];
        self.tableView.hidden = NO;
        
        // First let's remove any existing animations
        CALayer *layer = self.view.layer;
        [layer pop_removeAllAnimations];
        
        POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
        anim.fromValue = @(self.view.frame.size.height*2+self.navigationController.navigationBar.frame.size.height+[UIApplication sharedApplication].statusBarFrame.size.height);
        anim.toValue = @(0+self.view.frame.size.height/2+self.navigationController.navigationBar.frame.size.height+[UIApplication sharedApplication].statusBarFrame.size.height);
        anim.springBounciness = 12.0;
        anim.springSpeed = 18.0;
        anim.velocity = @(2000.);
        
        [layer pop_addAnimation:anim forKey:@"origin.y"];
        
        [SVProgressHUD dismiss];
    }
}

- (void)generateSectionArray {
    
    static NSString *letters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ#";
    
    NSMutableArray *content = [NSMutableArray new];
    
    // Loop through every letter of the alphabet
    for (int i = 0; i < [letters length]; i++ ) {
        NSMutableDictionary *letterDict = [NSMutableDictionary new];
        NSMutableArray *letterArray = [NSMutableArray new];
        // Loop through every title in the publisher array
        for (LBXTitle *title in _titlesForPublisherArray) {
            // Check if the title name begins with the current character
            if (toupper([letters characterAtIndex:i]) == toupper([title.name characterAtIndex:0])) {
                // If it does, append it to an array of all the titles
                // for that letter
                [letterArray addObject:title];
            }
            if ([letters characterAtIndex:i] == '#' && isdigit([title.name characterAtIndex:0])) {
                [letterArray addObject:title];
            }
        }
        // Add the letter as the key and the title array as the value
        // and then make it a part of the larger content array
        if (letterArray.count) {
            [letterDict setValue:letterArray forKey:[NSString stringWithFormat:@"%c", [letters characterAtIndex:i]]];
            [content addObject:letterDict];
        }
    }
    _sectionArray = content;
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
    view.tintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    
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
    
    NSDictionary *dict = [_sectionArray objectAtIndex:indexPath.section-1];
    NSArray *array = [dict objectForKey:dict.allKeys[0]];
    LBXTitle *title = [array objectAtIndex:indexPath.row];
    
    [LBXLogging logMessage:[NSString stringWithFormat:@"Selected title %@", title]];
    titleViewController.titleID = title.titleID;
    titleViewController.latestIssueImage = cell.latestIssueImageView.image;
    [self.navigationController pushViewController:titleViewController animated:YES];
}

@end
