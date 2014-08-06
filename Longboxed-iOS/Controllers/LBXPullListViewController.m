//
//  LBXPullListCollectionViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Jay Hickey. All rights reserved.
//

#import "LBXPullListViewController.h"
#import "LBXCustomTitleTableViewCell.h"
#import "LBXClient.h"
#import "LBXPullListTitle.h"
#import "ParallaxFlowLayout.h"
#import "ParallaxPhotoCell.h"
#import "LBXNavigationViewController.h"
#import "SVWebViewController.h"
#import "UIImage+ImageEffects.h"
#import "UIColor+customColors.h"
#import "UIFont+customFonts.h"

#import <UIImageView+AFNetworking.h>
#import <TWMessageBarManager.h>
#import <FontAwesomeKit/FontAwesomeKit.h>
#import <MCSwipeTableViewCell.h>

@interface LBXPullListViewController () <MCSwipeTableViewCellDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UILabel *noResultsLabel;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchBarController;
@property (nonatomic, strong) UIImageView *blurImageView;
@property (nonatomic, strong) NSMutableArray *pullListArray;
@property (nonatomic, strong) NSArray *searchResultsArray;
@property (nonatomic, strong) NSMutableArray *alreadyExistingTitles;
@property (nonatomic, strong) LBXClient *client;
@property (nonatomic, strong) MCSwipeTableViewCell *cellToDelete;

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
    self.navigationItem.leftBarButtonItem = actionButton;
    [self.navigationItem.leftBarButtonItem setTintColor:[UIColor blackColor]];

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
    
    _pullListArray = [NSMutableArray arrayWithArray:[self sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];

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
    _searchBar.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, _searchBar.frame.size.height);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    // Fetch pull list titles
    [self.client fetchPullListWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            _pullListArray = [NSMutableArray arrayWithArray:[self sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
            tableViewRows = _pullListArray.count;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self.refreshControl endRefreshing];
            });
        }
        else if ([error.localizedDescription rangeOfString:@"NSURLErrorDomain error -999"].location == NSNotFound) {
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Network Error"
                                                           description:@"Check your network connection."
                                                                  type:TWMessageBarMessageTypeError];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
            });
        }
    }];
}

- (void)addTitle:(LBXTitle *)title
{
    __block typeof(self) bself = self;
    [self.client addTitleToPullList:title.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Added!"
                                                           description:[NSString stringWithFormat:@"%@ has been added to your pull list.", title.name]
                                                                  type:TWMessageBarMessageTypeSuccess];
            
            [bself refresh];
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
    // Fetch pull list titles
    [self.client removeTitleFromPullList:title.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            _pullListArray = [NSMutableArray arrayWithArray:[self sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
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

- (NSArray *)sortedArray:(NSArray *)array basedOffObjectProperty:(NSString *)property
{
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:property
                                                 ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    return [array sortedArrayUsingDescriptors:sortDescriptors];
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
    _blurImageView = [[UIImageView alloc] initWithFrame:self.view.superview.bounds];
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
        static NSString *CellIdentifier = @"Cell";
        [[UITableViewCell appearance] setBackgroundColor:[UIColor clearColor]];
        
        LBXCustomTitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            
            cell = [[LBXCustomTitleTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
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
        
        static NSString *CellIdentifier = @"Cell";
        
        MCSwipeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            
            cell = [[MCSwipeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            
            // Remove inset of iOS 7 separators.
            if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
                cell.separatorInset = UIEdgeInsetsZero;
            }
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
            
            // Setting the background color of the cell.
            cell.contentView.backgroundColor = [UIColor whiteColor];
        }
        
        // Setting the default inactive state color to the tableView background color.
        [cell setDefaultColor:self.tableView.backgroundView.backgroundColor];
        [cell setDelegate:self];
        cell.defaultColor = [UIColor lightGrayColor];
        
        // Configure the cell...
        LBXTitle *title = [_pullListArray objectAtIndex:indexPath.row];
        cell.textLabel.font = [UIFont pullListTitleFont];
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping; // Pre-iOS6 use UILineBreakModeWordWrap
        cell.textLabel.numberOfLines = 2;  // 0 means no max.
        cell.textLabel.text = title.name;
        
        cell.detailTextLabel.font = [UIFont pullListSubtitleFont];
        cell.detailTextLabel.text = title.publisher.name;
        
        int iconSize = 30;
        
        // Delete cross
        FAKFontAwesome *crossIcon = [FAKFontAwesome timesIconWithSize:iconSize];
        [crossIcon addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
        UIImage *iconImage = [crossIcon imageWithSize:CGSizeMake(iconSize, iconSize)];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:iconImage];
        imageView.contentMode = UIViewContentModeCenter;
        UIView *crossView = imageView;
        
        [cell setSwipeGestureWithView:crossView color:[UIColor LBXRedColor] mode:MCSwipeTableViewCellModeExit state:MCSwipeTableViewCellState3 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
            
                _cellToDelete = cell;
            
                LBXTitle *title = [_pullListArray objectAtIndex:indexPath.row];
            
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete?"
                                                                    message:[NSString stringWithFormat:@"Are you sure your want to delete %@?", title.name]
                                                                   delegate:self
                                                          cancelButtonTitle:@"No"
                                                          otherButtonTitles:@"Yes", nil];
                [alertView show];

        }];
        
        // Snap the cell back if the swipe wasn't far enough
        [cell swipeToOriginWithCompletion:^{
            
        }];
        return cell;
    }
}



- (UIView *)viewWithImageName:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    return imageView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        [self.searchDisplayController setActive:NO animated:NO];

        LBXTitle *selectedTitle = [_searchResultsArray objectAtIndex:indexPath.row];
        
        [self addTitle:selectedTitle];
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

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // No
    if (buttonIndex == 0) {
        [_cellToDelete swipeToOriginWithCompletion:^{
            
        }];
        _cellToDelete = nil;
    }
    
    // Yes
    else {
        [self deleteTitle:[_pullListArray objectAtIndex:[self.tableView indexPathForCell:_cellToDelete].row]];
        [_pullListArray removeObjectAtIndex:[self.tableView indexPathForCell:_cellToDelete].row];
        [self.tableView deleteRowsAtIndexPaths:@[[self.tableView indexPathForCell:_cellToDelete]] withRowAnimation:UITableViewRowAnimationLeft];
    }
}


@end
