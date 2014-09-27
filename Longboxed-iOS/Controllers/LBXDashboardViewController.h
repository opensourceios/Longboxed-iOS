//
//  LBXDashboardViewController.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/27/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TableViewCell;

@interface LBXDashboardViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate> 

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) IBOutlet UITableView *topTableView;
@property (nonatomic, retain) IBOutlet UITableView *bottomTableView;
@property (nonatomic, retain) IBOutlet TableViewCell *tableViewCell;

@end