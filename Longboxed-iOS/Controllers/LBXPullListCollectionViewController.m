//
//  LBXPullListCollectionViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Jay Hickey. All rights reserved.
//

#import "LBXPullListCollectionViewController.h"
#import "LBXDataStore.h"
#import "LBXPullList.h"
#import "ParallaxFlowLayout.h"
#import "ParallaxPhotoCell.h"
#import "LBXNavigationViewController.h"
#import "SVWebViewController.h"

#import <UIImageView+AFNetworking.h>
#import <TWMessageBarManager.h>

@interface LBXPullListCollectionViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UILabel *noResultsLabel;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic) LBXPullList *pullListComics;

@end


@implementation LBXPullListCollectionViewController

LBXNavigationViewController *navigationController;
// 2 comics: 252    3 comics: 168    4 comics: 126
static const NSUInteger TABLE_HEIGHT_FOUR = 126;
static const NSUInteger TABLE_HEIGHT_THREE = 168;
static const NSUInteger TABLE_HEIGHT_TWO = 252;
static const NSUInteger TABLE_HEIGHT_ONE = 504;
static const NSUInteger TITLE_FONT_SIZE = 36;

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
    
    self.title = @"Pull List";
    NSDictionary *fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [UIFont fontWithName:@"HelveticaNeue-Thin" size:20.0], NSFontAttributeName,nil];
    [[UINavigationBar appearance] setTitleTextAttributes: fontDict];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hamburger-button"] style:UIBarButtonItemStyleBordered target:self.navigationController action:@selector(toggleMenu)];
    [self.navigationItem.rightBarButtonItem setTintColor:[UIColor lightGrayColor]];
    fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [UIFont fontWithName:@"HelveticaNeue-Thin" size:18.0], NSFontAttributeName, [UIColor blackColor], NSForegroundColorAttributeName, nil];
    [[UIBarButtonItem appearance] setTitleTextAttributes:fontDict forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dropCollectionView)
                                                 name:@"dropCollectionView"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(raiseCollectionView)
                                                 name:@"raiseCollectionView"
                                               object:nil];


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
    
    // Refresh the table view
    [self refresh];
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

- (void)dropCollectionView
{
    // Taken from the REMenu
    [UIView animateWithDuration:navigationController.menu.animationDuration+navigationController.menu.bounceAnimationDuration
                          delay:0.0
         usingSpringWithDamping:0.6
          initialSpringVelocity:4.0
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGRect frame = self.view.frame;
                         frame.origin.y = self.view.frame.origin.y + navigationController.menu.combinedHeight - navigationController.navigationBar.frame.size.height;
                         self.collectionView.frame = frame;
                     } completion:nil];
}

- (void)raiseCollectionView
{
    // Taken from the REMenu
    void (^closeMenu)(void) = ^{
        [UIView animateWithDuration:navigationController.menu.animationDuration
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                         animations:^ {
                             CGRect frame = self.view.frame;
                             frame.origin.y = self.view.frame.origin.y;
                             self.collectionView.frame = frame;
                         } completion:nil];
        
    };

    [UIView animateWithDuration:navigationController.menu.bounceAnimationDuration animations:^{
        CGRect frame = self.collectionView.frame;
        frame.origin.y = navigationController.menu.combinedHeight - navigationController.navigationBar.frame.size.height + 20.0;
        self.collectionView.frame = frame;
    } completion:^(BOOL finished) {
        closeMenu();
    }];
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
    
    // grab bound for contentView
    CGRect contentViewBound = cell.comicImageView.bounds;
    
    NSString *titleString = [_pullListComics.names objectAtIndex:indexPath.row];
    NSString *publisherString = [_pullListComics.publishers objectAtIndex:indexPath.row];
    NSString *issueString;
    if (![[NSString stringWithFormat:@"%@", [_pullListComics.subscribers objectAtIndex:indexPath.row]] isEqualToString:@""]) {
        issueString = [NSString stringWithFormat:@"%@ Issues", [_pullListComics.issueCount objectAtIndex:indexPath.row]];
    }
    else {
        issueString = [_pullListComics.subscribers objectAtIndex:indexPath.row];
    }
    
    // If an image exists, fetch it. Else use the generated UIImage
    if (1==2) {
        
        NSString *urlString = nil;
        
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
                                    [self setLabel:cell.comicTitleLabel withString:titleString inBoundsOfView:cell.comicImageView];}
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
                [self setLabel:cell.comicTitleLabel withString:titleString inBoundsOfView:cell.comicImageView];
                cell.comicImageView.image = image;
                cell.comicPublisherLabel.text = publisherString;
                cell.comicIssueLabel.text = issueString;
            }
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            
            [cell.activityIndicator stopAnimating];
            
            // Hide the network activity icon
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            // Don't show the error for NSURLErrorDomain -999 because that's just a cancelled image request due to scrolling
            if ([error.localizedDescription rangeOfString:@"NSURLErrorDomain error -999"].location == NSNotFound) {
                [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Network Error"
                                                               description:@"Check your network connection."
                                                                      type:TWMessageBarMessageTypeError];
            }
        }];

        CGRect imageViewFrame = cell.comicImageView.frame;
        // change x position
        imageViewFrame.origin.y = contentViewBound.size.height - imageViewFrame.size.height;
        // assign the new frame
        cell.comicImageView.frame = imageViewFrame;
        cell.comicImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    else {
        UIImage *defaultImage = nil;
        cell.backgroundColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:0.2];
        
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
        [self setLabel:cell.comicTitleLabel withString:titleString inBoundsOfView:cell.comicImageView];
    }

    
    // Pass the maximum parallax offset to the cell.
    // The cell needs this information to configure the constraints for its image view.
    ParallaxFlowLayout *layout = (ParallaxFlowLayout *)self.collectionViewLayout;
    cell.maxParallaxOffset = layout.maxParallaxOffset;
    
    
    return cell;
}

- (void)refresh
{
    [[LBXDataStore sharedStore] fetchPullList:^(NSArray *response, NSError *error) {
        _pullListComics = [[LBXPullList alloc] initPullList:response];
        tableViewRows = _pullListComics.longboxedIDs.count;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
            [_refreshControl endRefreshing];
        });
    }];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *diamondID = [_pullListComics.longboxedIDs objectAtIndex:indexPath.row];
    
    if (![diamondID isEqualToString:@""]) {
        NSString *webURL = [@"http://www.longboxed.com/issue/" stringByAppendingString:diamondID];
        SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:webURL];
        webViewController.modalPresentationStyle = UIModalPresentationPageSheet;
        webViewController.barsTintColor = [UIColor blackColor];
        [self presentViewController:webViewController animated:YES completion:NULL];
    }
    else {
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Can't Open Webpage"
                                                       description:@"No Longboxed page exists for this movie."
                                                              type:TWMessageBarMessageTypeError];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Compute cell size according to image aspect ratio.
    // Cell height must take maximum possible parallax offset into account.
    ParallaxFlowLayout *layout = (ParallaxFlowLayout *)self.collectionViewLayout;
    cellWidth = CGRectGetWidth(self.collectionView.bounds) - layout.sectionInset.left - layout.sectionInset.right;
    switch (_pullListComics.longboxedIDs.count) {
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
