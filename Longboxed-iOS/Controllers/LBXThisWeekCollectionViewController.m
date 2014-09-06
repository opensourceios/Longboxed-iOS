//
//  LBXThisWeekCollectionViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Jay Hickey. All rights reserved.
//

#import "LBXThisWeekCollectionViewController.h"
#import "LBXClient.h"
#import "ParallaxFlowLayout.h"
#import "ParallaxPhotoCell.h"
#import "LBXNavigationViewController.h"
#import "LBXTitleAndPublisherServices.h"
#import "SVWebViewController.h"
#import "LBXMessageBar.h"
#import "UIFont+customFonts.h"

#import <UIImageView+AFNetworking.h>
#import <TWMessageBarManager.h>

@interface LBXThisWeekCollectionViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic) LBXClient *client;
@property (nonatomic) NSArray *thisWeeksComicsArray;
@property (nonatomic) NSDate *thisWeekDate;
@property (nonatomic, strong) UIFont *textFont;
@property (nonatomic, strong) UILabel *noResultsLabel;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end


@implementation LBXThisWeekCollectionViewController

LBXNavigationViewController *navigationController;

// 2 comics: 252    3 comics: 168    4 comics: 126
static const NSUInteger TABLE_HEIGHT_FOUR = 126;
static const NSUInteger TABLE_HEIGHT_THREE = 168;
static const NSUInteger TABLE_HEIGHT_TWO = 252;
static const NSUInteger TABLE_HEIGHT_ONE = 504;

NSInteger tableViewRows;
CGFloat cellWidth;
BOOL endOfThisWeeksComics;
int page;

- (id)init
{
    ParallaxFlowLayout *layout = [[ParallaxFlowLayout alloc] init];
    layout.minimumLineSpacing = 0; // Spacing between each cell
    //layout.sectionInset = UIEdgeInsetsMake(16, 16, 16, 16); // Cell insets
    
    self = [super initWithCollectionViewLayout:layout];
    
    if (self == nil) {
        return nil;
    }

    return self;
}

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    return [self init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _textFont = [UIFont new];
    _textFont = [UIFont collectionTitleFontUltraLight];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
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
    
    page = 1;
    endOfThisWeeksComics = NO;
    
    // Calls perferredStatusBarStyle
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.collectionView.alwaysBounceVertical = YES;
    [self.collectionView registerClass:[ParallaxPhotoCell class] forCellWithReuseIdentifier:@"PhotoCell"];
    
    // Special attribute set for title text color
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    
    tableViewRows = 0;
    
    // Add refresh
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refreshControlAction)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:_refreshControl];
    
    // Add a footer loading spinner
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    spinner.frame = CGRectMake(0, 0, 320, 44);
    
    _thisWeeksComicsArray = [NSArray new];
    
    _client = [LBXClient new];
    
    [self setThisWeeksComicsArrayWithLatestIssues];
    
    tableViewRows = _thisWeeksComicsArray.count;
    [self.collectionView reloadData];
    [_refreshControl endRefreshing];
    
    // Refresh the collection view
    [self refreshControlAction];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar.backItem.backBarButtonItem setImageInsets:UIEdgeInsetsMake(40, 40, -40, 40)];
    [self.navigationController.navigationBar setBackIndicatorImage:
     [UIImage imageNamed:@"arrow"]];
    [self.navigationController.navigationBar setBackIndicatorTransitionMaskImage:
     [UIImage imageNamed:@"arrow"]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.topItem.title = @"This Week";
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    navigationController = (LBXNavigationViewController *)self.navigationController;
    [navigationController.menu setNeedsLayout];
}

#pragma mark - PrivateMethods

- (void)refreshControlAction
{
    [_refreshControl beginRefreshing];
    [self refreshViewWithPage:@1];
}

- (void)refreshViewWithPage:(NSNumber *)page
{
    // Fetch this weeks comics
    [self.client fetchThisWeeksComicsWithPage:page completion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            if (pullListArray.count == 0) {
                endOfThisWeeksComics = YES;
            }
            else {
                // Get this week date for fetching
                // from core data later
                LBXIssue *issue = pullListArray[0];
                _thisWeekDate = issue.releaseDate;
            }
           
            [self setThisWeeksComicsArrayWithLatestIssues];
            
            tableViewRows = _thisWeeksComicsArray.count;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
                [_refreshControl endRefreshing];
            });
        }
        else {
            //[LBXMessageBar displayError:error];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_refreshControl endRefreshing];
            });
        }
    }];
}



- (void)setThisWeeksComicsArrayWithLatestIssues
{
    // Get the latest issue in the database
    NSArray *issues = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO];
    if (issues.count && _thisWeekDate) {
        // Subtract one day from it
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(releaseDate == %@) AND (isParent == 1)", _thisWeekDate];
        _thisWeeksComicsArray = [LBXIssue MR_findAllSortedBy:@"publisher" ascending:YES withPredicate:predicate];
    }
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
    
    LBXIssue *issue = [_thisWeeksComicsArray objectAtIndex:indexPath.row];
    
    // grab bound for contentView
    CGRect contentViewBound = cell.comicImageView.bounds;
    
    NSString *titleString = issue.title.name;
    NSString *publisherString = issue.publisher.name;
    NSString *issueString;
    if (![[NSString stringWithFormat:@"%@", issue.issueNumber] isEqualToString:@""]) {
        issueString = [NSString stringWithFormat:@"Issue %@", issue.issueNumber];
    }
    else {
        issueString = @"";
    }
    
    // If an image exists, fetch it. Else use the generated UIImage
    if (issue.coverImage != (id)[NSNull null]) {
        
        NSString *urlString = issue.coverImage;
        
        // Show the network activity icon
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        cell.comicTitleLabel.text = nil;
        cell.comicPublisherLabel.text = nil;
        cell.comicIssueLabel.text = nil;
        
        [cell.activityIndicator startAnimating];
        
        // Get the image from the URL and set it
        [cell.comicImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] placeholderImage:[UIImage imageNamed:@"black"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [cell.activityIndicator stopAnimating];
            
            // Darken the image
            UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.comicImageView.frame.size.width, cell.comicImageView.frame.size.height*2)];
            [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
            NSArray *viewsToRemove = [cell.comicImageView subviews];
            for (UIView *v in viewsToRemove) [v removeFromSuperview];
            [cell.comicImageView addSubview:overlay];
            
            // Hide the network activity icon
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            if (request) {
                
                // Hide the network activity icon
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                
                [UIView transitionWithView:cell.comicImageView
                                  duration:0.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{[cell.comicImageView setImage:image];}
                                completion:NULL];
                
                [UIView transitionWithView:cell.comicTitleLabel
                                  duration:0.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{// Set the image label properties to center it in the cell
                                    [LBXTitleAndPublisherServices setLabel:cell.comicTitleLabel withString:titleString font:_textFont inBoundsOfView:cell.comicImageView];}
                                completion:NULL];
                
                [UIView transitionWithView:cell.comicPublisherLabel
                                  duration:0.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{[cell.comicPublisherLabel setText:publisherString];}
                                completion:NULL];
                
                [UIView transitionWithView:cell.comicIssueLabel
                                  duration:0.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{[cell.comicIssueLabel setText:issueString];}
                                completion:NULL];
            }
            else {
                // Set the image label properties to center it in the cell
                [LBXTitleAndPublisherServices setLabel:cell.comicTitleLabel withString:titleString font:_textFont inBoundsOfView:cell.comicImageView];
                cell.comicImageView.image = image;
                cell.comicPublisherLabel.text = publisherString;
                cell.comicIssueLabel.text = issueString;
            }
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            
            [cell.activityIndicator stopAnimating];
            
            // Hide the network activity icon
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [self setIssue:issue forCell:cell];
        }];

        CGRect imageViewFrame = cell.comicImageView.frame;
        // change x position
        imageViewFrame.origin.y = contentViewBound.size.height - imageViewFrame.size.height;
        // assign the new frame
        cell.comicImageView.frame = imageViewFrame;
        cell.comicImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    else {
        [self setIssue:issue forCell:cell];
    }

    
    // Pass the maximum parallax offset to the cell.
    // The cell needs this information to configure the constraints for its image view.
    ParallaxFlowLayout *layout = (ParallaxFlowLayout *)self.collectionViewLayout;
    cell.maxParallaxOffset = layout.maxParallaxOffset;
    
    if ([indexPath row] == _thisWeeksComicsArray.count - 1 && !endOfThisWeeksComics) {
        page += 1;
        [self refreshViewWithPage:[NSNumber numberWithInt:page]];
    }
    
    
    return cell;
}

- (void)setIssue:(LBXIssue *)issue forCell:(ParallaxPhotoCell *)cell
{
    
    NSString *titleString = issue.title.name;
    NSString *publisherString = issue.publisher.name;
    NSString *issueString;
    if (![[NSString stringWithFormat:@"%@", issue.issueNumber] isEqualToString:@""]) {
        issueString = [NSString stringWithFormat:@"Issue %@", issue.issueNumber];
    }
    else {
        issueString = @"";
    }
    
    UIImage *defaultImage = [UIImage imageNamed:@"black"];
    
    cell.comicPublisherLabel.text = publisherString;
    cell.comicIssueLabel.text = issueString;
    
    // Darken the image
    UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.comicImageView.frame.size.width, cell.comicImageView.frame.size.height*2)];
    [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
    NSArray *viewsToRemove = [cell.comicImageView subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];
    [cell.comicImageView addSubview:overlay];
    
    cell.comicImageView.image = defaultImage;
    
    // Set the image label properties to center it in the cell
    [LBXTitleAndPublisherServices setLabel:cell.comicTitleLabel withString:titleString font:_textFont inBoundsOfView:cell.comicImageView];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    LBXIssue *issue = [_thisWeeksComicsArray objectAtIndex:indexPath.row];
    NSString *diamondID = issue.diamondID;
    
    if (![diamondID isEqualToString:@""]) {
        NSString *webURL = [@"http://www.longboxed.com/issue/" stringByAppendingString:diamondID];
        SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:webURL];
        webViewController.modalPresentationStyle = UIModalPresentationPageSheet;
        webViewController.barsTintColor = [UIColor blackColor];
        [self presentViewController:webViewController animated:YES completion:NULL];
    }
    else {
        [LBXMessageBar longboxedWebPageError];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Compute cell size according to image aspect ratio.
    // Cell height must take maximum possible parallax offset into account.
    ParallaxFlowLayout *layout = (ParallaxFlowLayout *)self.collectionViewLayout;
    cellWidth = CGRectGetWidth(self.collectionView.bounds) - layout.sectionInset.left - layout.sectionInset.right;
    switch (_thisWeeksComicsArray.count) {
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

@end
