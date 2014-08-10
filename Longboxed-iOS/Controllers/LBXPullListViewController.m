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

// Categories
#import "NSArray+ArrayUtilities.h"
#import "NSDate+DateUtilities.h"
#import "UIColor+customColors.h"
#import "UIFont+customFonts.h"
#import "UIImage+ImageEffects.h"

#import <FontAwesomeKit/FontAwesomeKit.h>
#import <SVProgressHUD.h>
#import <TWMessageBarManager.h>
#import <UIImageView+AFNetworking.h>

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
    
    _client = [LBXClient new];
    
    _pullListArray = [NSMutableArray arrayWithArray:[NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];

    _latestIssuesInPullListArray = [NSMutableArray new];
    
    // Refresh the table view
    [self refresh];
    
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
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // SearchBar cancel button font
    [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:[UIColor blackColor]];
    NSDictionary *fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [UIFont searchCancelFont], NSFontAttributeName, [UIColor blackColor], NSForegroundColorAttributeName, nil];
    [[UIBarButtonItem appearance] setTitleTextAttributes:fontDict forState:UIControlStateNormal];
    
    // SearchBar placeholder text font
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont searchPlaceholderFont]];
    
    // SearchBar cursor color
    [[UISearchBar appearance] setTintColor:[UIColor blackColor]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
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
        else if ([error.localizedDescription rangeOfString:@"NSURLErrorDomain error -999"].location == NSNotFound) {
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Network Error"
                                                           description:@"Check your network connection."
                                                                  type:TWMessageBarMessageTypeError];
        }
    }];
}

- (void)refresh
{
    if (![self.tableView numberOfRowsInSection:0]) {
        [SVProgressHUD show];
    }
    // Fetch pull list titles
    [self.client fetchPullListWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            _pullListArray = [NSMutableArray arrayWithArray:[NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
            tableViewRows = _pullListArray.count;
        
        }
        else if ([error.localizedDescription rangeOfString:@"NSURLErrorDomain error -999"].location == NSNotFound) {
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Network Error"
                                                           description:@"Check your network connection."
                                                                  type:TWMessageBarMessageTypeError];
        }
        [self getAllIssues];
    }];
}

- (void)getAllIssues {
    __block NSUInteger i = 1;
    
    // Fetch all the titles from the API so we can get the latest issue
    for (LBXTitle *title in _pullListArray) {
        [self.client fetchIssuesForTitle:title.titleID withCompletion:^(NSArray *issuesArray, RKObjectRequestOperation *response, NSError *error) {
            // Wait until all titles in _pullListArray have been fetched
            if (i == _pullListArray.count) {
                if (!error) {
                    
                    // Fetch the latest of the issues from Core Data and append to _latestIssuesInPullListArray
                    for (LBXTitle *title in _pullListArray) {
                        NSLog(@"Searching for %@ (%@)", title.name, title.titleID);
                        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title.titleID == %@", title.titleID];
                        NSArray *allIssuesArray = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
                        
                        if (allIssuesArray.count == 0) {
                            NSLog(@"Couldn't find %@ (%@)", title.name, title.titleID);
                            [_latestIssuesInPullListArray addObject:@" "];
                        }
                        else {
                            LBXIssue *issue = allIssuesArray[0];
                            [_latestIssuesInPullListArray addObject:issue];
                        }
                    }
                }
                else if ([error.localizedDescription rangeOfString:@"NSURLErrorDomain error -999"].location == NSNotFound) {
                
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    [self.refreshControl endRefreshing];
                    [SVProgressHUD dismiss];
                });
            }
            i++;
        }];
    }
}

- (void)addTitle:(LBXTitle *)title
{
    [SVProgressHUD show];
    __block typeof(self) bself = self;
    [self.client addTitleToPullList:title.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        [SVProgressHUD dismiss];
        if (!error) {
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Added!"
                                                           description:[NSString stringWithFormat:@"%@ has been added to your pull list.", title.name]
                                                                  type:TWMessageBarMessageTypeSuccess];
            bself.pullListArray = [NSMutableArray arrayWithArray:[NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
            
            [bself.tableView reloadData];
        }
        else if ([error.localizedDescription rangeOfString:@"NSURLErrorDomain error -999"].location == NSNotFound) {
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Network Error"
                                                           description:@"Check your network connection."
                                                                  type:TWMessageBarMessageTypeError];
        }
    }];
}

- (void)deleteTitle:(LBXTitle *)title
{
    [SVProgressHUD show];
    // Fetch pull list titles
    [self.client removeTitleFromPullList:title.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        [SVProgressHUD dismiss];
        if (!error) {
            _pullListArray = [NSMutableArray arrayWithArray:[NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
            tableViewRows = _pullListArray.count;
            
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Deleted!"
                                                           description:[NSString stringWithFormat:@"%@ has been deleted from your pull list.", title.name]
                                                                  type:TWMessageBarMessageTypeInfo];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        else if ([error.localizedDescription rangeOfString:@"NSURLErrorDomain error -999"].location == NSNotFound) {
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Network Error"
                                                           description:@"Check your network connection."
                                                                  type:TWMessageBarMessageTypeError];
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
        
        [self setCell:cell withTitle:title];
        
        if (cell.latestIssueImageView.image == [UIImage imageNamed:@"NotAvailable"]) {
            [self.client fetchIssuesForTitle:title.titleID withCompletion:^(NSArray *issuesArray, RKObjectRequestOperation *response, NSError *error) {
                    if (!error) {
                        [self setCell:cell withTitle:title];
                    }
                    else if ([error.localizedDescription rangeOfString:@"NSURLErrorDomain error -999"].location == NSNotFound) {
                        
                    }
            }];
        }
        else {
            [self setCell:cell withTitle:title];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        [self.searchDisplayController setActive:NO animated:NO];

        LBXTitle *selectedTitle = [_searchResultsArray objectAtIndex:indexPath.row];
        
        [self addTitle:selectedTitle];
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

- (void)setCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title.titleID == %@", title.titleID];
    NSArray *allIssuesArray = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    
    if (allIssuesArray.count != 0) {
        LBXIssue *issue = allIssuesArray[0];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        [formatter setDateFormat:@"MM-dd-yyyy"];
        NSString *timeStamp = [formatter stringFromDate:issue.releaseDate];
        NSDate *gmtReleaseDate = [formatter dateFromString:timeStamp];
        // Add four hours because date is set to 20:00 by RestKit
        NSTimeInterval secondsInFourHours = 4 * 60 * 60;
        NSLog(@"%@: %@", title.name, issue.releaseDate);
        NSString *daysSinceLastIssue = [NSString stringWithFormat:@"%@", [NSDate fuzzyTimeBetweenStartDate:[gmtReleaseDate dateByAddingTimeInterval:secondsInFourHours] andEndDate:[NSDate date]]];
        
        NSString *subtitleString = [NSString stringWithFormat:@"%@  •  Issue %@, %@", title.publisher.name, issue.issueNumber, daysSinceLastIssue];
        
        cell.titleLabel.text = title.name;
        cell.subtitleLabel.text = [subtitleString uppercaseString];
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[UIImage imageNamed:@"clear"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
            [UIView transitionWithView:cell.imageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[cell.latestIssueImageView setImage:image];}
                            completion:NULL];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            
            
        }];
    }
    else {
        cell.titleLabel.text = title.name;
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@ •  No Issues", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
    }
}

#pragma mark UISearchBar methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Delays on making the actor API calls
    if([searchText length] != 0) {
        float delay = 0.5;
        
        if (searchText.length > 3) {
            delay = 0.3;
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
