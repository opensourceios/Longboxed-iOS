//
//  LBXDashboardViewController.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/27/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LBXTopTableViewCell;
@class LBXBottomTableViewCell;

@interface LBXDashboardViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate> 

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) IBOutlet UITableView *topTableView;
@property (nonatomic, retain) IBOutlet UITableView *bottomTableView;
@property (nonatomic, retain) IBOutlet UITableView *browseTableView;
@property (nonatomic, retain) IBOutlet UIButton *bundleButton;
@property (nonatomic, retain) IBOutlet UIButton *popularButton;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet LBXTopTableViewCell *topTableViewCell;
@property (nonatomic, retain) IBOutlet LBXBottomTableViewCell *bottomTableViewCell;

@end