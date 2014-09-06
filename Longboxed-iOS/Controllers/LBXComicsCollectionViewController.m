//
//  LBXComicsCollectionViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/6/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXComicsCollectionViewController.h"
#import "LBXClient.h"
#import "ParallaxFlowLayout.h"
#import "ParallaxPhotoCell.h"
#import "LBXNavigationViewController.h"
#import "LBXTitleAndPublisherServices.h"
#import "LBXPublisherCollectionViewController.h"
#import "LBXThisWeekCollectionViewController.h"
#import "LBXNextWeekCollectionViewController.h"

#import "UIFont+customFonts.h"

@interface LBXComicsCollectionViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UILabel *noResultsLabel;
@property (nonatomic, strong) UIFont *textFont;

@end

@implementation LBXComicsCollectionViewController

LBXNavigationViewController *navigationController;

// 2 rows: 252    3 rows: 168    4 rows: 126
static const NSUInteger TABLE_HEIGHT_FOUR = 126;
static const NSUInteger TABLE_HEIGHT_THREE = 168;
static const NSUInteger TABLE_HEIGHT_TWO = 252;
static const NSUInteger TABLE_HEIGHT_ONE = 504;

NSInteger tableViewRows;
CGFloat cellWidth;

- (id)init
{
    ParallaxFlowLayout *layout = [[ParallaxFlowLayout alloc] init];
    layout.minimumLineSpacing = 0; // Spacing between each cell
    //layout.sectionInset = UIEdgeInsetsMake(16, 16, 16, 16); // Cell insets
    
    tableViewRows = 3;
    
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
    // Do any additional setup after loading the view.
    
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
    
    // Calls perferredStatusBarStyle
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.collectionView.alwaysBounceVertical = YES;
    [self.collectionView registerClass:[ParallaxPhotoCell class] forCellWithReuseIdentifier:@"PhotoCell"];
    
    // Special attribute set for title text color
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.collectionView.scrollEnabled = NO;
    [self.collectionView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.shadowImage = nil;
    self.navigationController.navigationBar.topItem.title = @"Comics";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
    
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    navigationController = (LBXNavigationViewController *)self.navigationController;
    [navigationController.menu setNeedsLayout];
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
    CGRect imageViewFrame = cell.comicImageView.frame;
    // change x position
    imageViewFrame.origin.y = contentViewBound.size.height - imageViewFrame.size.height;
    // assign the new frame
    cell.comicImageView.frame = imageViewFrame;
    cell.comicImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    // Darken the image
    UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.comicImageView.frame.size.width, cell.comicImageView.frame.size.height*2)];
    [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
    NSArray *viewsToRemove = [cell.comicImageView subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];
    [cell.comicImageView addSubview:overlay];
    
    switch (indexPath.row) {
        case 0: {
            cell.comicImageView.image = [UIImage imageNamed:@"header-bg.jpg"];
            [LBXTitleAndPublisherServices setLabel:cell.comicTitleLabel withString:@"Publishers" font:_textFont inBoundsOfView:cell.comicImageView];
            break;
        }
        case 1: {
            cell.comicImageView.image = [UIImage imageNamed:@"black-spiderman.jpg"];
            [LBXTitleAndPublisherServices setLabel:cell.comicTitleLabel withString:@"This Week" font:_textFont inBoundsOfView:cell.comicImageView];
            break;
        }
        case 2: {
            cell.comicImageView.image = [UIImage imageNamed:@"thor-hulk.jpg"];
            [LBXTitleAndPublisherServices setLabel:cell.comicTitleLabel withString:@"Next Week" font:_textFont inBoundsOfView:cell.comicImageView];
            break;
        }
    }
    
    // Pass the maximum parallax offset to the cell.
    // The cell needs this information to configure the constraints for its image view.
    ParallaxFlowLayout *layout = (ParallaxFlowLayout *)self.collectionViewLayout;
    cell.maxParallaxOffset = layout.maxParallaxOffset;

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    LBXPublisherCollectionViewController *controller = [LBXPublisherCollectionViewController new];
    switch (indexPath.row) {
        case 0: {
            LBXPublisherCollectionViewController *controller = [LBXPublisherCollectionViewController new];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case 1: {
            LBXThisWeekCollectionViewController *controller = [LBXThisWeekCollectionViewController new];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case 2: {
            LBXNextWeekCollectionViewController *controller = [LBXNextWeekCollectionViewController new];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
    }
    

}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Compute cell size according to image aspect ratio.
    // Cell height must take maximum possible parallax offset into account.
    ParallaxFlowLayout *layout = (ParallaxFlowLayout *)self.collectionViewLayout;
    cellWidth = CGRectGetWidth(self.collectionView.bounds) - layout.sectionInset.left - layout.sectionInset.right;
    switch (tableViewRows) {
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
