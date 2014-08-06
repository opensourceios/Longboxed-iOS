//
//  LBXPullListCollectionViewController.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Jay Hickey. All rights reserved.
//

@import UIKit;

@interface LBXPullListViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *pullListArray;

- (void)refresh;

@end
