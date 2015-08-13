//
//  LBXDashboardViewController.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/27/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HorizontalTableView;

@interface LBXDashboardViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate> 

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) IBOutlet HorizontalTableView *topTableView;
@property (nonatomic, retain) IBOutlet HorizontalTableView *bottomTableView;
@property (nonatomic, retain) IBOutlet UIView *topView;
@property (nonatomic, retain) IBOutlet UIView *bottomView;
@property (nonatomic, retain) IBOutlet UITableView *browseTableView;
@property (nonatomic, retain) IBOutlet UIButton *bundleButton;
@property (nonatomic, retain) IBOutlet UIButton *popularButton;
@property (nonatomic, retain) IBOutlet UIButton *featuredIssueCoverButton;
@property (nonatomic, retain) IBOutlet UIButton *largeFeaturedIssueButton;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIView *separatorView;
@property (nonatomic, retain) IBOutlet UILabel *thisWeekLabel;
@property (nonatomic, retain) IBOutlet UILabel *featuredIssueTitleLabel;
@property (nonatomic, retain) IBOutlet UILabel *featuredDescriptionLabel;
@property (nonatomic, retain) IBOutlet UIImageView *featuredBlurredImageView;
@property (nonatomic, retain) IBOutlet UIView *thisWeekView;

@end