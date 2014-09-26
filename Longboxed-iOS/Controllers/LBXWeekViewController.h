//
//  LBXWeekTableViewController.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LBXWeekViewController : UIViewController

- (instancetype)initWithDate:(NSDate *)date andShowThisAndNextWeek:(BOOL)segmentedShowBool;

@end
