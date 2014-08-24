//
//  LBXPullListCollectionViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Jay Hickey. All rights reserved.
//

#import "LBXClient.h"
#import "LBXNavigationViewController.h"
#import "LBXPullListTableViewCell.h"
#import "LBXPullListTitle.h"
#import "LBXPullListViewController.h"
#import "LBXSearchTableViewCell.h"
#import "ParallaxFlowLayout.h"
#import "ParallaxPhotoCell.h"
#import "SVWebViewController.h"
#import "LBXTitleDetailViewController.h"
#import "LBXTitleServices.h"

// Categories
#import "NSArray+ArrayUtilities.h"
#import "NSDate+DateUtilities.h"
#import "UIColor+customColors.h"
#import "UIFont+customFonts.h"
#import "UIImage+ImageEffects.h"
#import "LBXMessageBar.h"

#import <FontAwesomeKit/FontAwesomeKit.h>
#import <UIImageView+AFNetworking.h>
#import <SVProgressHUD.h>

@interface LBXPullListViewController () <UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate>

@property (nonatomic, strong) LBXClient *client;
@property (nonatomic, strong) NSArray *searchResultsArray;
@property (nonatomic, strong) NSMutableArray *alreadyExistingTitles;
@property (nonatomic, strong) NSMutableArray *latestIssuesInPullListArray;
@property (nonatomic, strong) NSMutableArray *pullListArray;
@property (nonatomic, strong) UIImageView *blurImageView;
@property (nonatomic, strong) UILabel *noResultsLabel;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchBarController;

@end


@implementation LBXPullListViewController

LBXNavigationViewController *navigationController;

static const NSUInteger PULL_LIST_TABLE_HEIGHT = 88;
static const NSUInteger SEARCH_TABLE_HEIGHT = 66;

NSInteger tableViewRows;
CGFloat cellWidth;

- (id)init
{
    self = [super init];
    
    if (self == nil) {
        return nil;
    }
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(setupSearchView)];
    self.navigationItem.rightBarButtonItem = actionButton;
    [self.navigationItem.rightBarButtonItem setTintColor:[UIColor blackColor]];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Background color for the swiping of the cells
    self.view.backgroundColor = [UIColor whiteColor];
    
    [SVProgressHUD setFont:[UIFont SVProgressHUDFont]];
    [SVProgressHUD setBackgroundColor:[UIColor LBXGrayColor]];
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
    
    
    _noResultsLabel = [UILabel new];
    
    // TODO: Use autolayout constraints
    _noResultsLabel.frame = CGRectMake(self.view.frame.origin.x + 30, self.view.frame.origin.y, self.view.frame.size.width - 60, self.view.frame.size.height);
    _noResultsLabel.textAlignment = NSTextAlignmentCenter;
    _noResultsLabel.textColor = [UIColor whiteColor];
    _noResultsLabel.font = [UIFont noResultsFont];
    _noResultsLabel.numberOfLines = 0;
    
    _noResultsLabel.frame = CGRectMake(self.view.frame.origin.x + 20, self.view.frame.origin.y, self.view.frame.size.width - 40, self.view.frame.size.height);
    _noResultsLabel.alpha = 0.0;
    
    _noResultsLabel.text = @"No Results";

    [self.view addSubview:_noResultsLabel];
    
    // Calls perferredStatusBarStyle
    [self setNeedsStatusBarAppearanceUpdate];
    self.tableView.rowHeight = PULL_LIST_TABLE_HEIGHT;
    self.tableView.alwaysBounceVertical = YES;
    
    // Special attribute set for title text color
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    tableViewRows = 0;
    
    // Add refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh)
             forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl]; // So that the swipe cells aren't blocked
    
    _searchBar = [UISearchBar new];
    _searchBarController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar
                                                             contentsController:self];
    _searchBarController.delegate = self;
    _searchBarController.searchResultsDataSource = self;
    _searchBarController.searchResultsDelegate = self;
    
    [self.view addSubview:_searchBar];
    _searchBar.delegate = self;
    _searchBar.hidden = YES;
    _searchBar.placeholder = @"Add Title to Pull List";
    _searchBar.backgroundColor = [UIColor clearColor];
    _searchBar.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, _searchBar.frame.size.height);
    
    // Reload the pull list when using the back button on the title view
    _client = [LBXClient new];
    
    [self fillPullListArray];
    [self fillLatestIssuesInPullListArray];
    [self refresh];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];

    // SearchBar cancel button font
    [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:[UIColor blackColor]];
    NSDictionary *fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [UIFont searchCancelFont], NSFontAttributeName, [UIColor whiteColor], NSForegroundColorAttributeName, nil];
    [[UIBarButtonItem appearance] setTitleTextAttributes:fontDict forState:UIControlStateNormal];
    
    // SearchBar placeholder text font
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont searchPlaceholderFont]];
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    
    // SearchBar cursor color
    [[UISearchBar appearance] setTintColor:[UIColor blackColor]];
    
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
    
    // some over view controller could have changed our nav bar tint color, so reset it here
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor], NSFontAttributeName : [UIFont navTitleFont]}];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.shadowImage = nil;
    self.navigationController.navigationBar.topItem.title = @"Pull List";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.topItem.title = @" ";
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    navigationController = (LBXNavigationViewController *)self.navigationController;
    [navigationController.menu setNeedsLayout];
}

#pragma mark - PrivateMethods

- (void)setupSearchView
{
    // Close the nav menu if it is open
    [navigationController.menu close];
    
    // Blur the current screen
    [self blurScreen];
    // Put the search bar in front of the blurred view
    [self.view bringSubviewToFront:_searchBar];
    
    // Show the search bar
    _searchBar.hidden = NO;
    _searchBar.translucent = YES;
    _searchBar.backgroundImage = [UIImage new];
    _searchBar.scopeBarBackgroundImage = [UIImage new];
    [_searchBar becomeFirstResponder];
    [self.searchDisplayController setActive:YES animated:NO];

}

- (void)searchLongboxedWithText:(NSString *)searchText {
    // Search
    [self.client fetchAutocompleteForTitle:searchText withCompletion:^(NSArray *searchResultsArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            
            // Create an array of titles names already in pull list so the can't be added twice
            [_alreadyExistingTitles removeAllObjects];
            _alreadyExistingTitles = [NSMutableArray new];
            for (LBXTitle *title in searchResultsArray) {
                LBXTitle *existingTitle = [LBXPullListTitle MR_findFirstByAttribute:@"name" withValue:title.name];
                if (!existingTitle) {
                    [_alreadyExistingTitles addObject:[NSNumber numberWithBool:NO]];
                }
                else {
                    [_alreadyExistingTitles addObject:[NSNumber numberWithBool:YES]];
                }
            }
            self.searchResultsArray = [[NSArray alloc] initWithArray:searchResultsArray];
            
            dispatch_async(dispatch_get_main_queue(),^{
                [[self.searchBarController searchResultsTableView] reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            });
        }
        else {
            [LBXMessageBar displayError:error];
        }
    }];
}

- (void)fillPullListArray
{
    _pullListArray = [NSMutableArray arrayWithArray:[NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
}

- (void)fillLatestIssuesInPullListArray
{
    
    // Fetch the latest of the issues from Core Data and append to _latestIssuesInPullListArray
    for (LBXTitle *title in _pullListArray) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(title.titleID == %@) AND (isParent == 1)", title.titleID];
        NSArray *initialFind = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
        
        // Not all parents are actually the parents (sometimes a variant is a parent due to API bug)
        // so correct this by getting the issue with the shortest title
        // TODO: Get Tim to fix this
        NSMutableArray *correctedArray = [NSMutableArray new];
        for (LBXIssue *issue in initialFind) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(title == %@) AND (issueNumber == %@)", issue.title, issue.issueNumber];
            NSArray *issuesArray = [LBXIssue MR_findAllSortedBy:@"completeTitle" ascending:YES withPredicate:predicate];
            [correctedArray addObject:issuesArray[0]];
        }
        
        NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:correctedArray];
        
        NSSortDescriptor *sortByIssueID = [NSSortDescriptor sortDescriptorWithKey:@"issueID" ascending:NO];
        NSSortDescriptor *sortByIssueNumber = [NSSortDescriptor sortDescriptorWithKey:@"issueNumber" ascending:NO];
        NSSortDescriptor *sortByIssueReleaseDate = [NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:NO];
        
        // Combine the two
        NSArray *sortDescriptors = @[sortByIssueReleaseDate, sortByIssueNumber, sortByIssueID];
        NSArray *sortedArray = [mutableArray sortedArrayUsingDescriptors:sortDescriptors];
        
        
        if (sortedArray.count == 0) {
            [_latestIssuesInPullListArray addObject:@" "];
        }
        else {
            LBXIssue *issue = sortedArray[0];
            [_latestIssuesInPullListArray addObject:issue];
        }
    }
}

- (void)refresh
{
    // Fetch pull list titles
    [self.client fetchPullListWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [self fillPullListArray];
            tableViewRows = _pullListArray.count;
            [self getAllIssues];
        }
        else {
            [LBXMessageBar displayError:error];
            [self.refreshControl endRefreshing];
        }
        [self.tableView reloadData];
    }];
}

- (void)getAllIssues {
    __block NSUInteger i = 1;
    
    if (![self.tableView numberOfRowsInSection:0]) {
        [self.refreshControl beginRefreshing];
    }
    
    // Fetch all the titles from the API so we can get the latest issue
    for (LBXTitle *title in _pullListArray) {
        [self.client fetchIssuesForTitle:title.titleID page:@1 withCompletion:^(NSArray *issuesArray, RKObjectRequestOperation *response, NSError *error) {
            // Wait until all titles in _pullListArray have been fetched
            if (i == _pullListArray.count) {
                if (!error) {
                    
                    [self fillLatestIssuesInPullListArray];
                }
                else {
                    [LBXMessageBar displayError:error];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
                [self.refreshControl endRefreshing];
            }
            i++;
        }];
    }
}

- (void)addTitle:(LBXTitle *)title
{
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"Adding %@", title.name]];
    __block typeof(self) bself = self;
    [self.client addTitleToPullList:title.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        if (!error) {
            [SVProgressHUD showSuccessWithStatus:@"Added!"];
            bself.pullListArray = [NSMutableArray arrayWithArray:[NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
            
            [bself.tableView reloadData];
        }
        else {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Unable to add %@\n%@", title.name, error.localizedDescription]];
        }
        [bself.refreshControl endRefreshing];
    }];
}

- (void)deleteTitle:(LBXTitle *)title
{
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"Deleting %@", title.name]];
    // Fetch pull list titles
    [self.client removeTitleFromPullList:title.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        [self.refreshControl endRefreshing];
        if (!error) {
            _pullListArray = [NSMutableArray arrayWithArray:[NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
            tableViewRows = _pullListArray.count;
            
            [SVProgressHUD showSuccessWithStatus:@"Deleted!"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        else {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Unable to delete %@\n%@", title.name, error.localizedDescription]];
        }
    }];
}

// Captures the current screen and blurs it
- (void)blurScreen {
    
    UIScreen *screen = [UIScreen mainScreen];
    UIGraphicsBeginImageContextWithOptions(self.view.superview.frame.size, YES, screen.scale);
    
    [self.view drawViewHierarchyInRect:self.view.superview.bounds afterScreenUpdates:NO];
    
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurImage = [snapshot applyDarkEffect];
    UIGraphicsEndImageContext();
    
    // Blur the current screen
    // Have to drop the blur view down the height of the nav bar to
    // make things align because it disappears and the table view
    // goes up 44px (nav bar height)
    _blurImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y + self.navigationController.navigationBar.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height)];
    _blurImageView.image = blurImage;
    _blurImageView.contentMode = UIViewContentModeBottom;
    _blurImageView.clipsToBounds = YES;
    [self.view addSubview:_blurImageView];
    
}

#pragma mark UITableView methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        // Return the number of rows in the section.
        return [_searchResultsArray count];
    }
    
    else {
        return [_pullListArray count];
    }
}

// Change the Height of the Cell [Default is 44]:
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return SEARCH_TABLE_HEIGHT;
    }
    
    else {
        return PULL_LIST_TABLE_HEIGHT;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        static NSString *CellIdentifier = @"SearchCell";
        [[UITableViewCell appearance] setBackgroundColor:[UIColor clearColor]];
        
        LBXSearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            
            cell = [[LBXSearchTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:CellIdentifier];
            [cell layoutSubviews];
        }
        
        // Set the line separator to go all the way across
        [_searchBarController.searchResultsTableView setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];
        
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont searchFont];
        
        // Make the added images circles in the search table view
        cell.imageView.layer.cornerRadius = cell.imageView.frame.size.height/2;
        cell.imageView.layer.borderWidth = 0;
        
        cell.imageView.backgroundColor = [UIColor clearColor];
        // Make the search table view test and cell separators white
        LBXTitle *title = [_searchResultsArray objectAtIndex:indexPath.row];
        NSString *text = title.name;
        
        // Nil out all imageviews so that only the
        // ones necessary have checkmarks
        cell.imageView.image = nil;
        
        if ([[_alreadyExistingTitles objectAtIndex:indexPath.row] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            int checksize = 80;
            FAKFontAwesome *checkIcon = [FAKFontAwesome checkIconWithSize:checksize];
            [checkIcon addAttribute:NSForegroundColorAttributeName value:[UIColor LBXGreenColor]];
            UIImage *iconImage = [checkIcon imageWithSize:CGSizeMake(checksize, checksize)];
            cell.imageView.image = iconImage;
            
            // Disable selection of the row
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        cell.textLabel.text = text;
        cell.textLabel.textColor = [UIColor whiteColor];
        return cell;
    }
    
    else {
        
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
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
            
            // Setting the background color of the cell.
            cell.contentView.backgroundColor = [UIColor whiteColor];
        }
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(LBXPullListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the pull list cell info
    if (tableView != self.searchDisplayController.searchResultsTableView) {
        // Configure the cell...
        LBXTitle *title = [_pullListArray objectAtIndex:indexPath.row];
        
        cell.titleLabel.font = [UIFont pullListTitleFont];
        cell.titleLabel.text = title.name;
        cell.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.titleLabel.numberOfLines = 2;
        
        cell.subtitleLabel.font = [UIFont pullListSubtitleFont];
        cell.subtitleLabel.textColor = [UIColor grayColor];
        cell.subtitleLabel.numberOfLines = 2;
        
        cell.latestIssueImageView.image = nil;
        
        [LBXTitleServices setCell:cell withTitle:title];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.searchDisplayController setActive:NO animated:NO];

        LBXTitle *selectedTitle = [_searchResultsArray objectAtIndex:indexPath.row];
        
        [self addTitle:selectedTitle];
    }
    else {
        LBXPullListTableViewCell *cell = (LBXPullListTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        LBXTitleDetailViewController *titleViewController = [[LBXTitleDetailViewController alloc] initWithMainImage:cell.latestIssueImageView.image andTopViewFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * 3/4)];
        
        LBXTitle *title = [_pullListArray objectAtIndex:indexPath.row];
        titleViewController.titleID = title.titleID;
        titleViewController.latestIssueImage = cell.latestIssueImageView.image;
        [self.navigationController pushViewController:titleViewController animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return NO;
    }
    else {
        // Return YES if you want the specified item to be editable.
        return YES;
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        [self deleteTitle:[_pullListArray objectAtIndex:[self.tableView indexPathForCell:[tableView cellForRowAtIndexPath:indexPath]].row]];
        [_pullListArray removeObjectAtIndex:[self.tableView indexPathForCell:[tableView cellForRowAtIndexPath:indexPath]].row];
        [self.tableView deleteRowsAtIndexPaths:@[[self.tableView indexPathForCell:[tableView cellForRowAtIndexPath:indexPath]]] withRowAnimation:UITableViewRowAnimationLeft];
    }
}

- (void)refreshSearchTableView
{
    [[self.searchBarController searchResultsTableView] reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark UISearchBar methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Delays on making the actor API calls
    if([searchText length] != 0) {
        float delay = 0.3;
        
        if (searchText.length > 3) {
            delay = 0.1;
        }
        
        // Clear any previously queued text changes
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        [self performSelector:@selector(searchLongboxedWithText:)
                   withObject:searchText
                   afterDelay:delay];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self endSearch];
}

#pragma mark UISearchDisplayController methods

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    // If you scroll down in the search table view, this puts it back to the top next time you search
    [self.searchDisplayController.searchResultsTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    
    // Remove the line separators if there is no results
    self.searchDisplayController.searchResultsTableView.tableFooterView = [UIView new];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    // Make the background of the search results transparent
    UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
    backView.backgroundColor = [UIColor clearColor];
    controller.searchResultsTableView.backgroundView = backView;
    controller.searchResultsTableView.backgroundColor = [UIColor clearColor];
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [self endSearch];
}

- (void)endSearch
{
    // Hide the search bar when searching is completed
    [self.searchDisplayController setActive:NO animated:NO];
    _searchBar.hidden = YES;
    [_blurImageView removeFromSuperview];
}


@end
