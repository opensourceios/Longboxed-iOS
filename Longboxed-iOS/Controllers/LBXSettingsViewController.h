//
//  LBXLoginViewController.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/30/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LBXDashboardViewController.h"

@interface LBXSettingsViewController : UIViewController

@property (nonatomic, retain) LBXDashboardViewController *dashController; // So it can be pushed back onto the view hierarchy and isn't deallocated

@end
