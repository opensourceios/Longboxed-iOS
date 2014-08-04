//
//  LBXPullListCollectionViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Jay Hickey. All rights reserved.
//

#import "LBXPullListCollectionViewController.h"
#import "LBXCustomTitleTableViewCell.h"
#import "LBXClient.h"
#import "LBXPullListTitle.h"
#import "ParallaxFlowLayout.h"
#import "ParallaxPhotoCell.h"
#import "LBXNavigationViewController.h"
#import "SVWebViewController.h"
#import "UIImage+ImageEffects.h"

#import <UIImageView+AFNetworking.h>
#import <TWMessageBarManager.h>

@interface LBXPullListCollectionViewController () <UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UILabel *noResultsLabel;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchBarController;
@property (nonatomic, strong) UIImageView *blurImageView;

@property (nonatomic) NSArray *pullListArray;
@property (nonatomic) NSArray *searchResultsArray;
@property (nonatomic) NSMutableArray *alreadyExistingTitles;
@property (nonatomic) LBXClient *client;

@end


@implementation LBXPullListCollectionViewController

LBXNavigationViewController *navigationController;

// 2 comics: 252    3 comics: 168    4 comics: 126
static const NSUInteger TABLE_HEIGHT_FOUR = 126;
static const NSUInteger TABLE_HEIGHT_THREE = 168;
static const NSUInteger TABLE_HEIGHT_TWO = 252;
static const NSUInteger TABLE_HEIGHT_ONE = 504;
static const NSUInteger TITLE_FONT_SIZE = 36;

static const NSUInteger SEARCH_TABLE_HEIGHT = 66;

NSInteger tableViewRows;
CGFloat cellWidth;

- (id)init
{
    ParallaxFlowLayout *layout = [[ParallaxFlowLayout alloc] init];
    layout.minimumLineSpacing = 0; // Spacing between each cell
    //layout.sectionInset = UIEdgeInsetsMake(16, 16, 16, 16); // Cell insets
    
    self = [super initWithCollectionViewLayout:layout];
    
    if (self == nil) {
        return nil;
    }
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(setupSearchView)];
    self.navigationItem.leftBarButtonItem = actionButton;
    [self.navigationItem.leftBarButtonItem setTintColor:[UIColor blackColor]];

    return self;
}

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    return [self init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    _noResultsLabel = [UILabel new];
    
    // TODO: Use autolayout constraints
    _noResultsLabel.frame = CGRectMake(self.view.frame.origin.x + 30, self.view.frame.origin.y, self.view.frame.size.width - 60, self.view.frame.size.height);
    _noResultsLabel.textAlignment = NSTextAlignmentCenter;
    _noResultsLabel.textColor = [UIColor whiteColor];
    _noResultsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:24];
    _noResultsLabel.numberOfLines = 0;
    
    _noResultsLabel.frame = CGRectMake(self.view.frame.origin.x + 20, self.view.frame.origin.y, self.view.frame.size.width - 40, self.view.frame.size.height);
    _noResultsLabel.alpha = 0.0;
    
    _noResultsLabel.text = @"No Results";

    [self.view addSubview:_noResultsLabel];
    
    // Calls perferredStatusBarStyle
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.collectionView.alwaysBounceVertical = YES;
    [self.collectionView registerClass:[ParallaxPhotoCell class] forCellWithReuseIdentifier:@"PhotoCell"];
    
    // Special attribute set for title text color
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    tableViewRows = 0;
    
    // Add refresh
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refresh)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:_refreshControl];
    
    _client = [LBXClient new];
    
    _pullListArray = [self sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"];
    
    if (_pullListArray.count == 0) {
        // Refresh the table view
        [self refresh];
    }
    else {
        tableViewRows = _pullListArray.count;
        [self.collectionView reloadData];
    }
    
    _searchBar = [UISearchBar new];
    _searchBarController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar
                                                             contentsController:self];
    _searchBarController.delegate = self;
    _searchBarController.searchResultsDataSource = self;
    _searchBarController.searchResultsDelegate = self;
    
    [self.view addSubview:_searchBar];
    _searchBar.delegate = self;
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

- (void)setLabel:(UILabel *)textView
      withString:(NSString *)string
  inBoundsOfView:(UIView *)view
{
    UIFont *textFont = [UIFont new];
    textFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:TITLE_FONT_SIZE];
    
    textView.font = textFont;
    
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = NSLineBreakByWordWrapping;
    textStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName:textFont, NSParagraphStyleAttributeName: textStyle};
    CGRect bound = [string boundingRectWithSize:CGSizeMake(view.bounds.size.width-30, view.bounds.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    
    textView.numberOfLines = 2;
    textView.bounds = bound;
    textView.text = string;
}

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
    [self.searchDisplayController setActive:YES animated:YES];

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
            _pullListArray = [self sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"];
            tableViewRows = _pullListArray.count;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
                [_refreshControl endRefreshing];
            });
        }
        else if ([error.localizedDescription rangeOfString:@"NSURLErrorDomain error -999"].location == NSNotFound) {
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Network Error"
                                                           description:@"Check your network connection."
                                                                  type:TWMessageBarMessageTypeError];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_refreshControl endRefreshing];
            });
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
    UIGraphicsBeginImageContextWithOptions(self.view.frame.size, YES, screen.scale);
    
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:NO];
    
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurImage = [snapshot applyDarkEffect];
    UIGraphicsEndImageContext();
    
    // Blur the current screen
    _blurImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _blurImageView.image = blurImage;
    _blurImageView.contentMode = UIViewContentModeBottom;
    _blurImageView.clipsToBounds = YES;
    [self.view addSubview:_blurImageView];
    
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return tableViewRows;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"PhotoCell";
    __weak ParallaxPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    LBXPullListTitle *title = [_pullListArray objectAtIndex:indexPath.row];
    
    NSString *titleString = title.name;
    NSString *publisherString = title.publisher.name;
    NSString *subscriberString;
    if (![[NSString stringWithFormat:@"%@", title.subscribers] isEqualToString:@""]) {
        subscriberString = [NSString stringWithFormat:@"#%@", title.subscribers];
    }
    else {
        subscriberString = @"";
    }
    
    UIImage *defaultImage = nil;
    cell.backgroundColor = [UIColor colorWithRed:74/255.0 green:74/255.0 blue:74/255.0 alpha:0.9];
    
    cell.comicPublisherLabel.text = publisherString;
    cell.comicIssueLabel.text = subscriberString;
    
    // Darken the image
    UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.comicImageView.frame.size.width, cell.comicImageView.frame.size.height*2)];
    [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
    NSArray *viewsToRemove = [cell.comicImageView subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];
    [cell.comicImageView addSubview:overlay];
    
    cell.comicImageView.image = defaultImage;
    
    // Set the image label properties to center it in the cell
    [self setLabel:cell.comicTitleLabel withString:titleString inBoundsOfView:cell.comicImageView];

    
    // Pass the maximum parallax offset to the cell.
    // The cell needs this information to configure the constraints for its image view.
    ParallaxFlowLayout *layout = (ParallaxFlowLayout *)self.collectionViewLayout;
    cell.maxParallaxOffset = layout.maxParallaxOffset;
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Compute cell size according to image aspect ratio.
    // Cell height must take maximum possible parallax offset into account.
    ParallaxFlowLayout *layout = (ParallaxFlowLayout *)self.collectionViewLayout;
    cellWidth = CGRectGetWidth(self.collectionView.bounds) - layout.sectionInset.left - layout.sectionInset.right;
    switch (_pullListArray.count) {
        case 0:
        case 1:
            return CGSizeMake(cellWidth, TABLE_HEIGHT_ONE);
            break;
        case 2:
            return CGSizeMake(cellWidth, TABLE_HEIGHT_TWO);
            break;
        case 3:
            return CGSizeMake(cellWidth, TABLE_HEIGHT_THREE);
            break;
        default:
            return CGSizeMake(cellWidth, TABLE_HEIGHT_FOUR);
            break;
    }
    return CGSizeMake(cellWidth, TABLE_HEIGHT_FOUR);
}

#pragma mark UITableView methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_searchResultsArray count];
}

// Change the Height of the Cell [Default is 44]:
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return SEARCH_TABLE_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:20];
    
    // Make the added images circles in the search table view
    cell.imageView.layer.cornerRadius = cell.imageView.frame.size.height/2;
    cell.imageView.layer.borderWidth = 0;
    
    cell.imageView.backgroundColor = [UIColor clearColor];
    // Make the search table view test and cell separators white
    LBXTitle *title = [_searchResultsArray objectAtIndex:indexPath.row];
    
    NSString *text = title.name;
    if ([[_alreadyExistingTitles objectAtIndex:indexPath.row] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
        NSLog(@"IndexPath.row: %li\nalreadyExistingTitles: %@ ln=%li\nTitle name: %@\n\n", (long)indexPath.row, [_alreadyExistingTitles objectAtIndex:indexPath.row], (unsigned long)_alreadyExistingTitles.count, title.name);
        cell.imageView.image = [UIImage imageNamed:@"check"];
        
        // Disable selection of the row
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.textLabel.text = text;
    cell.textLabel.textColor = [UIColor whiteColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchDisplayController setActive:NO animated:NO];

    LBXTitle *selectedTitle = [_searchResultsArray objectAtIndex:indexPath.row];
    
    __block typeof(self) bself = self;
    [self.client addTitleToPullList:selectedTitle.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Success!"
                                                           description:[NSString stringWithFormat:@"%@ has been added to your pull list", selectedTitle.name]
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

#pragma mark UISearchBar methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.searchBarController.searchResultsTableView setContentOffset:CGPointMake(self.searchBarController.searchResultsTableView.contentOffset.x, 0) animated:YES];
    
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

- (void)refreshSearchTableView
{
    [[self.searchBarController searchResultsTableView] reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self endSearch];
}

#pragma mark UISearchDisplayController methods

// Added to fix UITableView bottom bounds in UISearchDisplayController
- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    // Added to fix UITableView bottom bounds in UISearchDisplayController
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
    
    // If you scroll down in the search table view, this puts it back to the top next time you search
    [self.searchDisplayController.searchResultsTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    
    // Remove the line separators if there is no results
    self.searchDisplayController.searchResultsTableView.tableFooterView = [UIView new];
}

// Added to fix UITableView bottom bounds in UISearchDisplayController
- (void)keyboardWillHide
{
    UITableView *tableView = [[self searchDisplayController] searchResultsTableView];
    [tableView setContentInset:UIEdgeInsetsZero];
    [tableView setScrollIndicatorInsets:UIEdgeInsetsZero];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    // Added to fix UITableView bottom bounds in UISearchDisplayController
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
    
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
