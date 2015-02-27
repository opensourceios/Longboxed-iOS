//
//  TableViewCell.h
//  Pulse
//
//  Created by Bushra on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LBXTopTableViewCell : UITableViewCell <UITableViewDataSource, UITableViewDelegate> {
    
    UITableView *horizontalTableView;
}
@property (nonatomic, retain) IBOutlet UITableView *horizontalTableView;
@property (nonatomic, retain) NSArray *contentArray;
@property (nonatomic, retain) NSArray *previousContentArray;

- (NSString *) reuseIdentifier;

@end
