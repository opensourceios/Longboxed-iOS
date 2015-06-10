//
//  LBXSearchTableViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 10/1/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXSearchTableViewController.h"
#import "LBXControllerServices.h"
#import "LBXPullListTableViewCell.h"
#import "LBXTitle.h"
#import "UIFont+LBXCustomFonts.h"
#import "LBXClient.h"

@interface LBXSearchTableViewController () 

@property (nonatomic) LBXClient *client;
@property (nonatomic) NSArray *searchResultsArray;

@end

@implementation LBXSearchTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.rowHeight = 88;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


#pragma mark - UISearchResultsUpdating delegate methods

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    
    if(searchController.searchBar.text.length == 0){
        [self.tableView reloadData];
    }

//    if (searchController.searchBar.text.length) {
//        [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:[UIColor blackColor]];
//        NSDictionary *fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
//                                  [UIFont searchCancelFont], NSFontAttributeName, [UIColor blackColor], NSForegroundColorAttributeName, nil];
//        [[UIBarButtonItem appearance] setTitleTextAttributes:fontDict forState:UIControlStateNormal];
//        [searchController.searchBar setNeedsDisplay];
//    }
}

#pragma mark - Table view data source



@end
