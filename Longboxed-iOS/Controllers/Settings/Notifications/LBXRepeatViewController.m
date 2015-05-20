//
//  LBXRepeatViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 5/18/15.
//  Copyright (c) 2015 Longboxed. All rights reserved.
//

#import "LBXRepeatViewController.h"
#import "UIFont+LBXCustomFonts.h"
#import "LBXConstants.h"

@interface LBXRepeatViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSMutableArray *dayArray;

@end

@implementation LBXRepeatViewController

static NSArray *daysOfWeek = nil;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    daysOfWeek = @[@"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday", @"Sunday"];
    
    self.title = @"Repeat";
    
    NSArray *days = [[NSUserDefaults standardUserDefaults] objectForKey:notificationDaysKey];
    self.dayArray = (days) ? [NSMutableArray arrayWithArray:days] : [NSMutableArray new];
    
    // Tableview setup
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new]; // Hide the extra rows
    self.tableView.alwaysBounceVertical = NO; // Disable scrolling
    [[UITableViewCell appearance] setTintColor:[UIColor blackColor]]; // Black checkmarks
    [self.view addSubview:self.tableView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.dayArray removeAllObjects];
    for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:0]; ++i) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
            [self.dayArray addObject:[daysOfWeek objectAtIndex:i]];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[self.dayArray copy] forKey:notificationDaysKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    static NSString *cellIdentifier = @"cell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSString *currentValue = [NSString stringWithFormat:@"Every %@", [daysOfWeek objectAtIndex:indexPath.row]];
    [[cell textLabel]setText:currentValue];
    
    // Set the checkmark state
    if ([self.dayArray containsObject:[daysOfWeek objectAtIndex:indexPath.row]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    // Uncheck all the other rows
//    for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:0]; ++i) {
//        NSIndexPath *ip = [NSIndexPath indexPathForRow:i inSection:0];
//        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
//        if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
//            cell.accessoryType = UITableViewCellAccessoryNone;
//        }
//    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = (cell.accessoryType == UITableViewCellAccessoryCheckmark) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
