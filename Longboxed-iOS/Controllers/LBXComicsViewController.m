//
//  LBXComicsViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/14/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXComicsViewController.h"
#import "LBXComicTableViewCell.h"
#import "LBXTitleAndPublisherServices.h"
#import "LBXPublisherCollectionViewController.h"
#import "LBXWeekViewController.h"
#import "LBXClient.h"
#import "LBXSearchTableViewCell.h"

#import "UIFont+customFonts.h"
#import "UIColor+customColors.h"
#import "UIImage+ImageEffects.h"

@interface LBXComicsViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, copy) LBXClient *client;
@property (nonatomic, strong) NSArray *searchResultsArray;
@property (nonatomic, strong) NSMutableArray *alreadyExistingTitles;
@property (nonatomic, strong) UIImageView *blurImageView;

@end

@implementation LBXComicsViewController

static const NSUInteger SEARCH_TABLE_HEIGHT = 66;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Do stuff
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.scrollEnabled = NO;
    self.tableView.tableFooterView = nil;
    self.tableView.tableHeaderView = nil;
    [self.tableView reloadData];
    
    _searchBarController.delegate = self;
    _searchBarController.searchResultsDataSource = self;
    _searchBarController.searchResultsDelegate = self;
    _searchBarController.searchBar.delegate = self;
    
    _client = [LBXClient new];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
    self.searchBarController.searchBar.backgroundColor = [UIColor LBXGrayNavigationBarColor];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.topItem.title = @"Comics";
}

#pragma mark Private Methods

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)searchLongboxedWithText:(NSString *)searchText {
    // Search
    [self.client fetchAutocompleteForTitle:searchText withCompletion:^(NSArray *newSearchResultsArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            // Create an array of titles names already in pull list so the can't be added twice
            [_alreadyExistingTitles removeAllObjects];
            _alreadyExistingTitles = [NSMutableArray new];
            
            [self refreshTableView:[self.searchBarController searchResultsTableView] withOldSearchResults:self.searchResultsArray newResults:newSearchResultsArray animation:UITableViewRowAnimationFade];
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

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return SEARCH_TABLE_HEIGHT;
    }
    else {
        return (self.view.frame.size.height - (self.navigationController.navigationBar.frame.size.height + self.searchBarController.searchBar.frame.size.height + 21)) / 2;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [_searchResultsArray count];
    }
    else {
        if(section == 0)
            return 2;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ComicCell";
    
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
        [_searchBarController.searchResultsTableView setSeparatorInset:UIEdgeInsetsZero];
        
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
        
        cell.textLabel.text = text;
        cell.textLabel.textColor = [UIColor whiteColor];
        return cell;
    }
    else {
        LBXComicTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            // Custom cell as explained here: https://medium.com/p/9bee5824e722
            [tableView registerNib:[UINib nibWithNibName:@"LBXComicTableViewCell" bundle:nil] forCellReuseIdentifier:@"ComicCell"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"ComicCell"];
        }
        
        cell.titleLabel.font = [UIFont comicsViewFontUltraLight];
        cell.titleLabel.numberOfLines = 1;
        
        // grab bound for contentView
        CGRect contentViewBound = cell.backgroundImageView.bounds;
        CGRect imageViewFrame = cell.backgroundImageView.frame;
        // change x position
        imageViewFrame.origin.y = contentViewBound.size.height - imageViewFrame.size.height;
        // assign the new frame
        cell.backgroundImageView.frame = imageViewFrame;
        cell.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        
        // Darken the image
        UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.backgroundImageView.frame.size.width, cell.backgroundImageView.frame.size.height*2)];
        [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
        NSArray *viewsToRemove = [cell.backgroundImageView subviews];
        for (UIView *v in viewsToRemove) [v removeFromSuperview];
        [cell.backgroundImageView addSubview:overlay];
        
        switch (indexPath.row) {
            case 0: {
                cell.backgroundImageView.image = [UIImage imageNamed:@"thor-hulk.jpg"];
                [LBXTitleAndPublisherServices setLabel:cell.titleLabel withString:@"Publishers" font:[UIFont comicsViewFontUltraLight] inBoundsOfView:cell.backgroundImageView];
                break;
            }
            case 1: {
                cell.backgroundImageView.image = [UIImage imageNamed:@"black-spiderman.jpg"];
                [LBXTitleAndPublisherServices setLabel:cell.titleLabel withString:@"Releases" font:[UIFont comicsViewFontUltraLight] inBoundsOfView:cell.backgroundImageView];
                break;
            }
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
    }
    else {
        //    LBXPublisherCollectionViewController *controller = [LBXPublisherCollectionViewController new];
        switch (indexPath.row) {
            case 0: {
                LBXPublisherCollectionViewController *controller = [LBXPublisherCollectionViewController new];
                [self.navigationController pushViewController:controller animated:YES];
                break;
            }
            case 1: {
                LBXWeekViewController *controller = [LBXWeekViewController new];
                [self.navigationController pushViewController:controller animated:YES];
                break;
            }
        }
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

//- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
//{
//    // If you scroll down in the search table view, this puts it back to the top next time you search
//    [self.searchDisplayController.searchResultsTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
//    
//    // Remove the line separators if there is no results
//    self.searchDisplayController.searchResultsTableView.tableFooterView = [UIView new];
//}
//
//- (void)correctSearchDisplayFrames {
//    // Update search bar frame.
//    CGRect superviewFrame = self.searchDisplayController.searchBar.superview.frame;
//    superviewFrame.origin.y = 0.f;
//    self.searchDisplayController.searchBar.superview.frame = self.view.frame;
//    
//    // Strech dimming view.
////    UIView *dimmingView = PSPDFViewWithSuffix(self.view, @"DimmingView");
////    if (dimmingView) {
////        CGRect dimmingFrame = dimmingView.superview.frame;
////        dimmingFrame.origin.y = self.searchDisplayController.searchBar.frame.size.height;
////        dimmingFrame.size.height = self.view.frame.size.height - dimmingFrame.origin.y;
////        dimmingView.superview.frame = dimmingFrame;
////    }
//}
//
//- (void)setAllViewsExceptSearchHidden:(BOOL)hidden animated:(BOOL)animated {
//    [UIView animateWithDuration:animated ? 0.25f : 0.f animations:^{
//        for (UIView *view in self.tableView.subviews) {
//            if (view != self.searchDisplayController.searchResultsTableView &&
//                view != self.searchDisplayController.searchBar) {
//                view.alpha = hidden ? 0.f : 1.f;
//            }
//        }
//    }];
//}
//
//// This fixes UISearchBarController on iOS 7. rdar://14800556
//- (void)correctFramesForSearchDisplayControllerBeginSearch:(BOOL)beginSearch {
//    [self.navigationController setNavigationBarHidden:beginSearch animated:YES];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self correctSearchDisplayFrames];
//    });
//    [self setAllViewsExceptSearchHidden:beginSearch animated:YES];
//    [UIView animateWithDuration:0.25f animations:^{
//        self.searchDisplayController.searchResultsTableView.alpha = beginSearch ? 1.f : 0.f;
//    }];
//}
//
//- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
//    //[self correctFramesForSearchDisplayControllerBeginSearch:YES];
//    //move the search bar up to the correct location eg
//
//    // Blur the current screen
//    [self blurScreen];
//    // Put the search bar in front of the blurred view
//    [self.view bringSubviewToFront:self.searchBarController.searchBar];
//    
//    // Show the search bar
//    self.searchBarController.searchBar.hidden = NO;
//    self.searchBarController.searchBar.translucent = YES;
//    self.searchBarController.searchBar.backgroundImage = [UIImage new];
//    self.searchBarController.searchBar.scopeBarBackgroundImage = [UIImage new];
//    [self.searchBarController.searchBar becomeFirstResponder];
//    [self.searchDisplayController setActive:YES animated:NO];
//}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    //move the search bar up to the correct location eg
    [UIView animateWithDuration:.4
                     animations:^{
                         searchBar.frame = CGRectMake(searchBar.frame.origin.x,
                                                      0,
                                                      searchBar.frame.size.width,
                                                      searchBar.frame.size.height);
                     }
                     completion:^(BOOL finished){
                         //whatever else you may need to do
                     }];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    //move the search bar down to the correct location eg
    [UIView animateWithDuration:.4
                     animations:^{
                         [searchBar setNeedsDisplay];
                     }
                     completion:^(BOOL finished){
                         //whatever else you may need to do
                     }];
    return YES;
}

//- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
//{
//    // Make the background of the search results transparent
//    UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
//    backView.backgroundColor = [UIColor clearColor];
//    controller.searchResultsTableView.backgroundView = backView;
//    controller.searchResultsTableView.backgroundColor = [UIColor clearColor];
//}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [self endSearch];
}

- (void)endSearch
{
    // Hide the search bar when searching is completed
    [self.searchDisplayController setActive:NO animated:NO];
    [_blurImageView removeFromSuperview];
}

@end
