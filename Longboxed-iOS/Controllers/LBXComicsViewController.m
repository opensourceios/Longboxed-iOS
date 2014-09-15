//
//  LBXComicsViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/14/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXComicsViewController.h"
#import "LBXComicTableViewCell.h"
#import "LBXNavigationViewController.h"
#import "LBXTitleAndPublisherServices.h"
#import "LBXPublisherCollectionViewController.h"
#import "LBXWeekViewController.h"

#import "UIFont+customFonts.h"
#import "UIColor+customColors.h"

@interface LBXComicsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation LBXComicsViewController

LBXNavigationViewController *navigationController;

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
    navigationController = (LBXNavigationViewController *)self.navigationController;
    [navigationController.menu setNeedsLayout];

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

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return (self.view.frame.size.height - (self.navigationController.navigationBar.frame.size.height + self.searchBarController.searchBar.frame.size.height + 21)) / 2;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0)
        return 2;
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ComicCell";
    
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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

@end
