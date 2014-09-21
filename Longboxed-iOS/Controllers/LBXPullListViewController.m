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
#import "LBXTitleAndPublisherServices.h"
#import "LBXEmptyPullListViewController.h"
#import "LBXLogging.h"
#import "PaintCodeImages.h"

// Categories
#import "NSArray+ArrayUtilities.h"
#import "NSDate+DateUtilities.h"
#import "UIColor+customColors.h"
#import "UIFont+customFonts.h"
#import "UIImage+ImageEffects.h"
#import "LBXMessageBar.h"

#import <SVProgressHUD/SVProgressHUD.h>
#import <FontAwesomeKit/FontAwesomeKit.h>
#import <UIScrollView+EmptyDataSet.h>
#import <SVProgressHUD.h>
#import <POP.h>

@interface LBXPullListViewController () <UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate,
                                         DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) LBXClient *client;
@property (nonatomic, strong) NSArray *searchResultsArray;
@property (nonatomic, strong) NSMutableArray *alreadyExistingTitles;
@property (nonatomic, strong) NSMutableArray *latestIssuesInPullListArray;
@property (nonatomic, strong) NSMutableArray *pullListArray;
@property (nonatomic, strong) UIImageView *blurImageView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchBarController;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) LBXPullListTitle *selectedTitle;
@property (nonatomic, strong) UIView *loadingView;

@end


@implementation LBXPullListViewController

LBXNavigationViewController *navigationController;

static const NSUInteger PULL_LIST_TABLE_HEIGHT = 88;
static const NSUInteger SEARCH_TABLE_HEIGHT = 88;

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
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
    
    // Background color for the swiping of the cells
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Calls perferredStatusBarStyle
    [self setNeedsStatusBarAppearanceUpdate];
    self.tableView.rowHeight = PULL_LIST_TABLE_HEIGHT;
    self.tableView.alwaysBounceVertical = YES;
    
    // Special attribute set for title text color
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
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

    _searchBar.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, _searchBar.frame.size.height);
    
    self.searchDisplayController.searchResultsTableView.rowHeight = SEARCH_TABLE_HEIGHT;
    
    // Reload the pull list when using the back button on the title view
    _client = [LBXClient new];

    [self fillPullListArray];
    if (_pullListArray.count == 0) {
        [self refresh];
    }
    
    _loadingView = [[UIView alloc] initWithFrame:self.view.frame];
    _loadingView.backgroundColor = [UIColor whiteColor];
    [SVProgressHUD setFont:[UIFont SVProgressHUDFont]];
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD setForegroundColor:[UIColor blackColor]];
    
    [self fillPullListArray];
    
    if (!_pullListArray.count) {
        self.tableView.hidden = YES;
        [self.view insertSubview:_loadingView aboveSubview:self.tableView];
        [SVProgressHUD show];
    }
    
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
    
    // Special attribute set for title text color
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self refresh];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.shadowImage = nil;
    self.navigationController.navigationBar.topItem.title = @"Pull List";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
    
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    
    ///////
    // Search Bar
    ///////
    
    // SearchBar cancel button font
    [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:[UIColor blackColor]];
    NSDictionary *fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [UIFont searchCancelFont], NSFontAttributeName, [UIColor blackColor], NSForegroundColorAttributeName, nil];
    [[UIBarButtonItem appearance] setTitleTextAttributes:fontDict forState:UIControlStateNormal];
    
    // SearchBar placeholder text font
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont searchPlaceholderFont]];
    // SearchBar text field input font
    for (UIView *subviews in _searchBar.subviews) {
        for (UIView *subview in subviews.subviews) {
            if ([subview isKindOfClass:[UITextField class]]) {
                UITextField *searchField = (UITextField *)subview;
                searchField.font = [UIFont searchPlaceholderFont];
                searchField.textColor = [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] textColor];
            }
        }
    }
    

    
    // Set the search bar background color
    self.searchDisplayController.searchBar.barTintColor = [UIColor whiteColor];
    
    // Set the search bar text field background color
    for (UIView *subView in _searchBar.subviews) {
        for(id field in subView.subviews){
            if ([field isKindOfClass:[UITextField class]]) {
                UITextField *textField = (UITextField *)field;
                [textField setBackgroundColor:[UIColor colorWithHex:@"#CCCCCC"]];
            }
        }
    }
    
    // SearchBar cursor color
    self.searchDisplayController.searchBar.tintColor = [UIColor blackColor];
    

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.topItem.title = @" ";
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.refreshControl endRefreshing];
    [super viewDidDisappear:animated];
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
    //[self blurScreen];
    // Put the search bar in front of the blurred view
    [self.view bringSubviewToFront:_searchBar];
    
    // Show the search bar
    _searchBar.hidden = NO;
    _searchBar.translucent = NO;
    _searchBar.backgroundImage = [UIImage imageNamed:@"longboxed_full"];
    _searchBar.scopeBarBackgroundImage = [UIImage imageNamed:@"longboxed_full"];
    [_searchBar becomeFirstResponder];
    [self.searchDisplayController setActive:YES animated:NO];

}

- (void)searchLongboxedWithText:(NSString *)searchText {
    
    // Search
    [self.client fetchAutocompleteForTitle:searchText withCompletion:^(NSArray *newSearchResultsArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            // Create an array of titles names already in pull list so the can't be added twice
            [_alreadyExistingTitles removeAllObjects];
            _alreadyExistingTitles = [NSMutableArray new];
            for (LBXPullListTitle *searchTitle in newSearchResultsArray) {
                BOOL match = NO;
                for (LBXPullListTitle *pullListTitle in _pullListArray) {
                    NSLog(@"Comparing %@ and %@", searchTitle.name, pullListTitle.name);
                    if (![searchTitle.name isEqualToString:pullListTitle.name]) {
                        //[_alreadyExistingTitles addObject:[NSNumber numberWithBool:NO]];
                    }
                    else {
                        match = YES;
                    }
                }
                if (match) {
                   [_alreadyExistingTitles addObject:[NSNumber numberWithBool:YES]];
                }
                else {
                    [_alreadyExistingTitles addObject:[NSNumber numberWithBool:NO]];
                }
            }
            [self refreshTableView:[self.searchBarController searchResultsTableView]  withOldSearchResults:self.searchResultsArray newResults:newSearchResultsArray animation:UITableViewRowAnimationFade];
        }
        else {
            //[LBXMessageBar displayError:error];
        }
    }];
}

- (void)refreshTableView:(UITableView *)tableView withOldSearchResults:(NSArray *)oldResultsArray
                                  newResults:(NSArray *)newResultsArray
                                   animation:(UITableViewRowAnimation)animation
{
    // If rows are removed
    if (newResultsArray.count < oldResultsArray.count && oldResultsArray.count) {
        NSMutableArray *diferentIndexes = [NSMutableArray new];
        for (int i = 0; i < newResultsArray.count; i++) {
            if (oldResultsArray[i] != newResultsArray[i]) { //Maybe add "&& newSearchResultsArray.count" here
                [diferentIndexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
        
        NSMutableArray *oldIndexes = [NSMutableArray new];
        if (newResultsArray.count < oldResultsArray.count) {
            for (NSUInteger i = newResultsArray.count; i < oldResultsArray.count; i++) {
                [oldIndexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
        
        // Update the table view
        [tableView beginUpdates];
        [tableView numberOfRowsInSection:newResultsArray.count];
        [tableView deleteRowsAtIndexPaths:oldIndexes withRowAnimation:animation];
        
        self.searchResultsArray = [[NSArray alloc] initWithArray:newResultsArray];
        [tableView endUpdates];
    }
    
    
    // If rows are added
    else if (newResultsArray.count > oldResultsArray.count && oldResultsArray.count != 0) {
        NSMutableArray *diferentIndexes = [NSMutableArray new];
        for (int i = 0; i < oldResultsArray.count; i++) {
            if (oldResultsArray[i] != newResultsArray[i]) { //Maybe add "&& newSearchResultsArray.count" here
                [diferentIndexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
        NSMutableArray *newIndexes = [NSMutableArray new];
        if (newResultsArray.count > oldResultsArray.count) {
            NSUInteger index;
            if (!oldResultsArray.count) index = 0; else index = oldResultsArray.count;
            for (NSUInteger i = index; i < newResultsArray.count; i++) {
                [newIndexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
        
        // Update the table view
        [tableView beginUpdates];
        [tableView insertRowsAtIndexPaths:newIndexes withRowAnimation:animation];
        self.searchResultsArray = [[NSArray alloc] initWithArray:newResultsArray];
        [tableView endUpdates];
    }
    
    // Rows are just changed
    else if (newResultsArray.count == oldResultsArray.count && oldResultsArray.count != 0) {
        NSMutableArray *diferentIndexes = [NSMutableArray new];
        for (int i = 0; i < oldResultsArray.count; i++) {
            if (oldResultsArray[i] != newResultsArray[i]) { //Maybe add "&& newSearchResultsArray.count" here
                [diferentIndexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
        
        // Update the table view
        [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:diferentIndexes withRowAnimation:animation];
        self.searchResultsArray = [[NSArray alloc] initWithArray:newResultsArray];
        [tableView endUpdates];
    }
    
    // If entire view needs refreshed
    else if (oldResultsArray.count == 0) {
        dispatch_async(dispatch_get_main_queue(),^{
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:animation];
        });
        self.searchResultsArray = [[NSArray alloc] initWithArray:newResultsArray];
    }
}


- (void)fillPullListArray
{
    _pullListArray = [NSMutableArray arrayWithArray:[NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
}

- (void)refresh
{
    NSArray *oldArray = _pullListArray;
    [self fillPullListArray];
    [self refreshTableView:self.tableView withOldSearchResults:oldArray newResults:_pullListArray animation:UITableViewRowAnimationLeft];
    
    if (_pullListArray.count == 0) {
        self.tableView.contentOffset = CGPointMake(0, -self.refreshControl.frame.size.height);
        [self.refreshControl beginRefreshing];
    }
    
    [self fillPullListArray];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    
    // Fetch pull list titles
    [self.client fetchPullListWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        if (!error) {
            // Delete any items that may have been removed from
            // the pull list
            NSArray *objects = [LBXPullListTitle MR_findAll];
            for (NSManagedObject *managedObject in objects) {
                if (![pullListArray containsObject:managedObject]) {
                    [[NSManagedObjectContext MR_defaultContext] deleteObject:managedObject];
                }
            }
            
            [self fillPullListArray];
        }
        else {
            //[LBXMessageBar displayError:error];
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
            if (self.tableView.hidden) {
                [_loadingView removeFromSuperview];
                self.tableView.hidden = NO;
                
                // First let's remove any existing animations
                CALayer *layer = self.view.layer;
                [layer pop_removeAllAnimations];
                
                POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
                anim.fromValue = @(self.view.frame.size.height*2);
                anim.toValue = @(0+self.view.frame.size.height/2);
                anim.springBounciness = 12.0;
                anim.springSpeed = 18.0;
                anim.velocity = @(2000.);
                
                [layer pop_addAnimation:anim forKey:@"origin.y"];
                
                [SVProgressHUD dismiss];
            }
        });
    }];
}

- (void)addTitle:(LBXTitle *)title
{
    LBXPullListTitle *pullListTitle = [LBXPullListTitle MR_createEntity];
    pullListTitle.name = title.name;
    pullListTitle.subscribers = title.subscribers;
    pullListTitle.publisher = title.publisher;
    pullListTitle.titleID = title.titleID;
    pullListTitle.issueCount = title.issueCount;
    pullListTitle.latestIssue = title.latestIssue;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self fillPullListArray];
    [self.tableView reloadData];
    __block typeof(self) bself = self;
    [self.client addTitleToPullList:title.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        if (!error) {
            [bself fillPullListArray];
        }
        else {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Unable to add %@\n%@", title.name, error.localizedDescription]];
        }
        [bself.tableView reloadData];
    }];
}

- (void)deleteTitle:(LBXTitle *)title
{
    // Fetch pull list titles
    [self.client removeTitleFromPullList:title.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        [self.refreshControl endRefreshing];
        if (!error) {
        }
        else {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Unable to delete %@\n%@", title.name, error.localizedDescription]];
        }
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.tableView reloadData];
//        });
    }];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"titleID == %@", title.titleID];
    [LBXPullListTitle MR_deleteAllMatchingPredicate:predicate];
    [self fillPullListArray];
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

#pragma mark - DZNEmptyDataSet

- (UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    
    LBXEmptyPullListViewController *controller = [LBXEmptyPullListViewController new];
    controller.view.frame = CGRectMake(-self.view.frame.size.width/2, -self.view.frame.size.height/2, self.view.frame.size.width, self.view.frame.size.height);
    return controller.view;
}

#pragma mark UITableView methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        // Return the number of rows in the section.
        if (_searchResultsArray.count == 0) {
            return 1;
        }
        return [_searchResultsArray count];
    }
    else {
        return _pullListArray.count;
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
    static NSString *CellIdentifier = @"PullListCell";
    
    LBXPullListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [tableView setSeparatorInset:UIEdgeInsetsZero];
    
    if (cell == nil) {
        // Custom cell as explained here: https://medium.com/p/9bee5824e722
        [tableView registerNib:[UINib nibWithNibName:@"LBXPullListTableViewCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

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

- (void)tableView:(UITableView *)tableView willDisplayCell:(LBXPullListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    LBXTitle *title = [_pullListArray objectAtIndex:indexPath.row];
    if (tableView != self.searchDisplayController.searchResultsTableView) {

        [self setTableViewStylesWithCell:cell andTitle:title];
        [LBXTitleAndPublisherServices setPullListCell:cell withTitle:title];
    }
    else if (_searchResultsArray.count == 0) {
        cell.imageViewSeparatorLabel.hidden = YES;
        cell.latestIssueImageView.hidden = YES;
        cell.titleLabel.hidden = YES;
        cell.subtitleLabel.hidden = YES;
    }
    else {
        title = [_searchResultsArray objectAtIndex:indexPath.row];
        [self setTableViewStylesWithCell:cell andTitle:title];
        
        
        // Dim the cell if the title is already in the pull list
        if ([[_alreadyExistingTitles objectAtIndex:indexPath.row] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            [LBXTitleAndPublisherServices setAddToPullListSearchCell:cell withTitle:title darkenImage:YES];
            cell.titleLabel.textColor = [UIColor lightGrayColor];
            cell.subtitleLabel.textColor = [UIColor lightGrayColor];
        
        }
        else {

            [LBXTitleAndPublisherServices setAddToPullListSearchCell:cell withTitle:title darkenImage:NO];
        }
    }
}

- (void)setTableViewStylesWithCell:(LBXPullListTableViewCell *)cell andTitle:(LBXTitle *)title
{
    cell.imageViewSeparatorLabel.hidden = NO;
    cell.latestIssueImageView.hidden = NO;
    cell.titleLabel.hidden = NO;
    cell.subtitleLabel.hidden = NO;
    NSArray *viewsToRemove = [cell.latestIssueImageView subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];

    cell.titleLabel.font = [UIFont pullListTitleFont];
    cell.titleLabel.textColor = [UIColor blackColor];
    cell.titleLabel.text = title.name;
    cell.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    cell.titleLabel.numberOfLines = 2;
    
    cell.subtitleLabel.font = [UIFont pullListSubtitleFont];
    cell.subtitleLabel.textColor = [UIColor grayColor];
    cell.subtitleLabel.numberOfLines = 2;
    
    cell.latestIssueImageView.image = nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _indexPath = indexPath;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        // Do nothing if the title is already in the pull list
        if ([[_alreadyExistingTitles objectAtIndex:indexPath.row] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Already Added"
                                                            message:@"This title is already in your pull list."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.searchDisplayController setActive:NO animated:NO];

        LBXTitle *selectedTitle = [_searchResultsArray objectAtIndex:indexPath.row];
        _selectedTitle = [_searchResultsArray objectAtIndex:indexPath.row];
        
        [self addTitle:selectedTitle];
    }
    else {
        LBXPullListTableViewCell *cell = (LBXPullListTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        LBXTitleDetailViewController *titleViewController = [[LBXTitleDetailViewController alloc] initWithMainImage:cell.latestIssueImageView.image andTopViewFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * 3/4)];
        _selectedTitle = [_pullListArray objectAtIndex:indexPath.row];
        [LBXLogging logMessage:[NSString stringWithFormat:@"Selected title: %@", _selectedTitle.description]];
        titleViewController.titleID = _selectedTitle.titleID;
        titleViewController.latestIssueImage = cell.latestIssueImageView.image;
        [self.navigationController pushViewController:titleViewController animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return NO;
    }
    else {
        // Return YES if you want the specified item to be editable.
        return YES;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Remove";
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        _indexPath = indexPath;
        //add code here for when you hit delete
        
        [self deleteTitle:[_pullListArray objectAtIndex:[self.tableView indexPathForCell:[self.tableView cellForRowAtIndexPath:_indexPath]].row]];
            [tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[[self.tableView indexPathForCell:[self.tableView cellForRowAtIndexPath:_indexPath]]] withRowAnimation:UITableViewRowAnimationLeft];
            [tableView endUpdates];
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

}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    _searchResultsArray = nil;
    _alreadyExistingTitles = nil;
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
