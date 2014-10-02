//
//  LBXSearchTableViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 10/1/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXSearchTableViewController.h"
#import "LBXClient.h"

@interface LBXSearchTableViewController () 

@property (nonatomic) LBXClient *client;
@property (nonatomic) NSArray *searchResultsArray;

@end

@implementation LBXSearchTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UISearchResultsUpdating delegate methods

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSLog(@"text changed!");
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 10;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/



@end
