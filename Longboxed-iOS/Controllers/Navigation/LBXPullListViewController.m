//
//  LBXPullListCollectionViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Jay Hickey. All rights reserved.
//

#import "LBXClient.h"
#import "LBXPullListTableViewCell.h"
#import "LBXPullListTitle.h"
#import "LBXBundle.h"
#import "LBXPullListViewController.h"
#import "LBXTitleDetailViewController.h"
#import "LBXControllerServices.h"
#import "LBXEmptyPullListViewController.h"
#import "LBXLogging.h"
#import "PaintCodeImages.h"

// Categories
#import "NSArray+LBXArrayUtilities.h"
#import "NSDate+DateUtilities.h"
#import "UIColor+LBXCustomColors.h"
#import "UIFont+LBXCustomFonts.h"
#import "UIImage+ImageEffects.h"
#import "SVProgressHUD.h"

#import <UICKeyChainStore.h>
#import <FontAwesomeKit/FontAwesomeKit.h>
#import <POP.h>
#import <Doppelganger.h>
#import "UIScrollView+UzysAnimatedGifPullToRefresh.h"

@interface LBXPullListViewController () <UISearchBarDelegate, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) LBXClient *client;
@property (nonatomic, strong) NSArray *searchResultsArray;
@property (nonatomic, strong) NSMutableArray *alreadyExistingTitles;
@property (nonatomic, strong) NSMutableArray *latestIssuesInPullListArray;
@property (nonatomic, strong) NSMutableArray *pullListArray;
@property (nonatomic, strong) LBXSearchTableViewController *searchResultsController;
@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) LBXPullListTitle *selectedTitle;
@property (nonatomic, strong) UIView *loadingView;

@end


@implementation LBXPullListViewController

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
    
    self.tableView = [UITableView new];
    self.tableView.frame = self.view.frame;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
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
    
    _searchResultsController = [LBXSearchTableViewController new];
    _searchController = [[UISearchController alloc] initWithSearchResultsController:_searchResultsController];
    [LBXControllerServices setupSearchController:_searchController withSearchResultsController:self.searchResultsController andDelegate:self];
    [self.tableView addSubview:_searchController.searchBar];
    _searchController.searchBar.hidden = YES;
    
    // Add refresh
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullToRefreshActionHandler:^{
        [weakSelf refresh];
    }
                            ProgressImagesGifName:@"PullToRefresh.gif"
                             LoadingImagesGifName:@"PullToRefresh_Loading.gif"
                          ProgressScrollThreshold:60
                            LoadingImageFrameRate:30];
    
    // Reload the pull list when using the back button on the title view
    self.client = [LBXClient new];
    
    [self fillPullListArray];
    if (_pullListArray.count == 0) {
        [self refresh];
    }
    
    _loadingView = [[UIView alloc] initWithFrame:self.view.frame];
    _loadingView.backgroundColor = [UIColor whiteColor];
    [SVProgressHUD setFont:[UIFont SVProgressHUDFont]];
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD setForegroundColor:[UIColor blackColor]];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
    
    [LBXControllerServices setViewWillAppearWhiteNavigationController:self];
    [LBXControllerServices setSearchBar:_searchController.searchBar withTextColor:[UIColor whiteColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont searchPlaceholderFont]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor blackColor]];
    
    // Check for changes to the pull list
    NSArray *previousArray = _pullListArray;
    [self fillPullListArray];
    if (previousArray != _pullListArray) {
        NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:_pullListArray
                                                    previousArray:previousArray];
        [self.tableView wml_applyBatchChanges:diffs
                                    inSection:0
                             withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    if (!_pullListArray.count) {
        self.tableView.hidden = YES;
        [self.view insertSubview:_loadingView aboveSubview:self.tableView];
        [SVProgressHUD showAtPosY:self.view.frame.size.height/2];
    }
    
    [self refresh];
    
    [LBXControllerServices setViewDidAppearWhiteNavigationController:self];
    self.navigationController.navigationBar.topItem.title = @"Pull List";
    
    [self.tableView flashScrollIndicators];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.tableView stopPullToRefreshAnimation];
    [SVProgressHUD dismiss];
    [SVProgressHUD setForegroundColor: [UIColor blackColor]];
    [SVProgressHUD setBackgroundColor: [UIColor whiteColor]];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

#pragma mark - PrivateMethods

- (void)setupSearchView {
    // If already scrolled to top, show search
    if (self.tableView.contentOffset.y == -(self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height)) {
        self.searchController.active = YES;
        _searchController.searchBar.hidden = NO;
    }
    else {
        // Else scroll to top
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    }

}

// Called after view has reached the top
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    self.searchController.active = YES;
    _searchController.searchBar.hidden = NO;
}

- (void)searchLongboxedWithText:(NSString *)searchText {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    // Search
    [self.client fetchAutocompleteForTitle:searchText withCompletion:^(NSArray *newSearchResultsArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            // Create an array of titles names already in pull list so the can't be added twice
            [_alreadyExistingTitles removeAllObjects];
            _alreadyExistingTitles = [NSMutableArray new];
            for (LBXPullListTitle *searchTitle in newSearchResultsArray) {
                BOOL match = NO;
                for (LBXPullListTitle *pullListTitle in _pullListArray) {
                    if ([searchTitle.name isEqualToString:pullListTitle.name]) {
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
            NSArray *previousResultsArray = self.searchResultsArray;
            self.searchResultsArray = newSearchResultsArray;
            if (newSearchResultsArray.count && previousResultsArray.count) {
                NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:newSearchResultsArray
                                                            previousArray:previousResultsArray];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.searchResultsController.tableView wml_applyBatchChanges:diffs
                                                                        inSection:0
                                                                 withRowAnimation:UITableViewRowAnimationAutomatic];
                });
            }
            else [self.searchResultsController.tableView reloadData];
        }
    }];
}

- (void)fillPullListArray
{
    _pullListArray = [NSMutableArray arrayWithArray:[NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
}

- (void)refresh
{
    NSArray *oldArray = _pullListArray;
    [self fillPullListArray];
    self.searchResultsArray = _pullListArray;
    if (oldArray != _pullListArray) {
        NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:_pullListArray
                                                    previousArray:oldArray];
        [self.tableView wml_applyBatchChanges:diffs
                                    inSection:0
                             withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else [self.tableView reloadData];
    
    if (_pullListArray.count == 0) {
        self.tableView.contentOffset = CGPointMake(0, -self.navigationController.navigationBar.frame.size.height);
    }
    
    oldArray = _pullListArray;
    if (oldArray.count < _pullListArray.count) [self fillPullListArray];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (oldArray != _pullListArray) {
            NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:_pullListArray
                                                        previousArray:oldArray];
            [self.tableView wml_applyBatchChanges:diffs
                                        inSection:0
                                 withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else [self.tableView reloadData];
    });
    
    // Fetch pull list titles
    [self.client fetchPullListWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        NSArray *prevArray = _pullListArray;
        if (!error) {
            [self fillPullListArray];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (oldArray != _pullListArray) {
                NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:_pullListArray
                                                            previousArray:prevArray];
                [self.tableView wml_applyBatchChanges:diffs
                                            inSection:0
                                     withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else [self.tableView reloadData];
            [self.tableView stopPullToRefreshAnimation];
            if (self.tableView.hidden) {
                [_loadingView removeFromSuperview];
                self.tableView.hidden = NO;
                
                // First let's remove any existing animations
                CALayer *layer = self.view.layer;
                [layer pop_removeAllAnimations];
                
                POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
                anim.fromValue = @(self.view.frame.size.height*2);
                anim.toValue = @(0 + [UIApplication sharedApplication].statusBarFrame.size.height + self.view.frame.size.height/2);
                anim.springBounciness = 12.0;
                anim.springSpeed = 18.0;
                anim.velocity = @(2000.);
                
                [layer pop_addAnimation:anim forKey:@"origin.y"];
                
                // Add empty view if there the pull list is empty
                if (!_pullListArray.count) {
                    LBXEmptyPullListViewController *controller = [LBXEmptyPullListViewController new];
                    controller.view.frame = self.tableView.frame;
                    self.tableView.backgroundView = controller.view;
                }
                
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
    
    NSArray *previousPullListArray = _pullListArray;
    [self fillPullListArray];
    
    if (previousPullListArray.count) {
        NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:_pullListArray
                                                    previousArray:previousPullListArray];
        [self.tableView wml_applyBatchChanges:diffs
                                    inSection:0
                             withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else {
        [self.tableView reloadData];
        self.tableView.backgroundView = nil;
    }
    __block typeof(self) bself = self;
    [self.client addTitleToPullList:title.titleID withCompletion:^(NSArray *pullListArray, AFHTTPRequestOperation *response, NSError *error) {
        if (!error) {
            [bself fillPullListArray];
        }
        [bself.tableView reloadData];
    }];
}

- (void)deleteTitle:(LBXPullListTitle *)title
{
    // Fetch pull list titles
    [self.client removeTitleFromPullList:title.titleID withCompletion:^(NSArray *pullListArray, AFHTTPRequestOperation *response, NSError *error) {
        [self.tableView stopPullToRefreshAnimation];
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.client fetchBundleResourcesWithDate:[NSDate thisWednesdayOfDate:[NSDate localDate]] page:@1 count:@1 completion:^(NSArray *bundleArray, RKObjectRequestOperation *response, NSError *error) {}];
                [self fillPullListArray];
                if (!_pullListArray.count) {
                    LBXEmptyPullListViewController *controller = [LBXEmptyPullListViewController new];
                    controller.view.frame = self.tableView.frame;
                    self.tableView.backgroundView = controller.view;
                }
            });
        }
    }];
}

#pragma mark UITableView methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchResultsController.tableView) {
        // Return the number of rows in the section.
        return [_searchResultsArray count];
    }
    else {
        return _pullListArray.count;
    }
}

// Change the Height of the Cell [Default is 44]:
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (tableView == self.searchResultsController.tableView) {
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
    if (tableView != self.searchResultsController.tableView) {
        LBXTitle *title = [_pullListArray objectAtIndex:indexPath.row];
        [self setTableViewStylesWithCell:cell andTitle:title];
        [LBXControllerServices setPullListCell:cell withTitle:title];
    }
    else if (_searchResultsArray.count == 0) {
        cell.imageViewSeparatorLabel.hidden = YES;
        cell.latestIssueImageView.hidden = YES;
        cell.titleLabel.hidden = YES;
        cell.subtitleLabel.hidden = YES;
    }
    else {
        LBXTitle *title = [_searchResultsArray objectAtIndex:indexPath.row];
        [self setTableViewStylesWithCell:cell andTitle:title];
        
        
        // Dim the cell if the title is already in the pull list
        if ([[_alreadyExistingTitles objectAtIndex:indexPath.row] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            [LBXControllerServices setAddToPullListSearchCell:cell withTitle:title darkenImage:YES];
            cell.titleLabel.textColor = [UIColor lightGrayColor];
            cell.subtitleLabel.textColor = [UIColor lightGrayColor];
            
        }
        else {
            
            [LBXControllerServices setAddToPullListSearchCell:cell withTitle:title darkenImage:NO];
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
    if (tableView == self.searchResultsController.tableView) {
        
        // Do nothing if the title is already in the pull list
        if ([[_alreadyExistingTitles objectAtIndex:indexPath.row] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            [LBXControllerServices showAlertWithTitle:@"Already Added" andMessage:@"This title is already in your pull list."];
            return;
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        LBXTitle *selectedTitle = [_searchResultsArray objectAtIndex:indexPath.row];
        _selectedTitle = [_searchResultsArray objectAtIndex:indexPath.row];
        
        [self addTitle:selectedTitle];
        self.searchController.active = NO;
    }
    else {
        _selectedTitle = [_pullListArray objectAtIndex:indexPath.row];
        
        LBXPullListTableViewCell *cell = (LBXPullListTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        LBXTitleDetailViewController *titleViewController = [[LBXTitleDetailViewController alloc] initWithTitle:(LBXTitle *)_selectedTitle];
        [LBXLogging logMessage:[NSString stringWithFormat:@"Selected title in pull list:\n %@", _selectedTitle.description]];
        titleViewController.titleID = _selectedTitle.titleID;
        titleViewController.latestIssueImage = cell.latestIssueImageView.image;
        [self.navigationController pushViewController:titleViewController animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchResultsController.tableView) {
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
        LBXPullListTitle *titleToDelete = [_pullListArray objectAtIndex:[self.tableView indexPathForCell:[self.tableView cellForRowAtIndexPath:_indexPath]].row];
        [_pullListArray removeObject:titleToDelete];
        [self deleteTitle:titleToDelete];
        [tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[[self.tableView indexPathForCell:[self.tableView cellForRowAtIndexPath:_indexPath]]] withRowAnimation:UITableViewRowAnimationLeft];
        [tableView endUpdates];
    }
}

#pragma mark UISearchControllerDelegate Methods

- (void)willPresentSearchController:(UISearchController *)searchController
{
    [_searchController.searchBar becomeFirstResponder];
    
    // SearchBar cancel button font
    [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:[UIColor blackColor]];
    NSDictionary *fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [UIFont searchCancelFont], NSFontAttributeName, [UIColor blackColor], NSForegroundColorAttributeName, nil];
    [[UIBarButtonItem appearance] setTitleTextAttributes:fontDict forState:UIControlStateNormal];
    
    UIView *statusBarView = [UIView new];
    statusBarView.alpha = 0.0;
    statusBarView.backgroundColor = [UIColor whiteColor];
    statusBarView.frame = CGRectMake([UIApplication sharedApplication].statusBarFrame.origin.x, [UIApplication sharedApplication].statusBarFrame.origin.y, [UIApplication sharedApplication].statusBarFrame.size.width, [UIApplication sharedApplication].statusBarFrame.size.height + searchController.searchBar.frame.size.height);
    [self.view addSubview:statusBarView];
    [searchController.view insertSubview:statusBarView aboveSubview:searchController.searchBar];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [statusBarView setAlpha:1.0];
    [UIView commitAnimations];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setBackgroundColor:[UIColor LBXVeryLightGrayColor]];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    [LBXControllerServices setSearchBar:searchController.searchBar withTextColor:[UIColor blackColor]];
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor grayColor]];
    _searchResultsArray = nil;
    
}

- (void)didPresentSearchController:(UISearchController *)searchController
{
    _searchResultsArray = nil;
    self.searchResultsController.refreshControl = nil;
    
    [self.searchResultsController.tableView reloadData];
    
    // Hair line below the search bar
    UIView *onePxView = [[UIView alloc] initWithFrame:CGRectMake(0, _searchController.searchBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height + 0.5f, [UIScreen mainScreen].bounds.size.width, 0.5f)];
    onePxView.backgroundColor = [UIColor lightGrayColor];
    [self.searchController.view addSubview:onePxView];
    
    self.searchResultsController.tableView.scrollIndicatorInsets = self.searchResultsController.tableView.contentInset;
}

- (void)willDismissSearchController:(UISearchController *)searchController
{
    _searchController.searchBar.hidden = YES;
    _searchController.searchBar.backgroundImage = [[UIImage alloc] init];
    _searchController.searchBar.backgroundColor = [UIColor clearColor];
    [LBXControllerServices setSearchBar:searchController.searchBar withTextColor:[UIColor whiteColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setBackgroundColor:nil];
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.tableView.contentOffset = CGPointMake(0, -(self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height));
}

#pragma mark UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Delays on making the actor API calls
    if(searchText.length) {
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
    else {
        _searchResultsArray = nil;
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [LBXControllerServices setViewWillAppearWhiteNavigationController:self];
    _searchResultsArray = nil;
}

@end
