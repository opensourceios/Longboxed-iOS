//
//  LBXNotificationsViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 5/18/15.
//  Copyright (c) 2015 Longboxed. All rights reserved.
//

#import "LBXNotificationsViewController.h"
#import "UIFont+LBXCustomFonts.h"
#import "LBXDateTableViewCell.h"
#import "LBXConstants.h"
#import "LBXRepeatViewController.h"

@interface LBXNotificationsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) LBXDateTableViewCell *datePickerCell;
@property (nonatomic) UISwitch *enabledSwitch;

@end

@implementation LBXNotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UILabel *label = [UILabel new];
    label.text = @"Notifications";
    label.font = [UIFont navTitleFont];
    [label sizeToFit];
    
    self.navigationItem.titleView = label;
    
    // Tableview setup
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new]; // Hide the extra rows
    self.tableView.alwaysBounceVertical = NO; // Disable scrolling
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0); // For the header being 1.0f (heightForHeaderInSection)
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSUserDefaults standardUserDefaults] setObject:self.datePickerCell.datePicker.date forKey:notificationTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 162;
    }
    else return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) return 1.0f;
    return 32.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"LBXDateTableViewCell";
        
        self.datePickerCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (self.datePickerCell == nil) {
            // Custom cell as explained here: https://medium.com/p/9bee5824e722
            [tableView registerNib:[UINib nibWithNibName:@"LBXDateTableViewCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
            self.datePickerCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        }
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:notificationTimeKey]) {
            self.datePickerCell.datePicker.date = [[NSUserDefaults standardUserDefaults] objectForKey:notificationTimeKey];
        }
        
        return self.datePickerCell;
        
    }
    else {
        static NSString *cellIdentifier = @"cell";
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        }
        
        NSString *currentValue = @"";
        if (indexPath.row == 0) {
            currentValue = @"Repeat";
            NSArray *days = [[NSUserDefaults standardUserDefaults] objectForKey:notificationDaysKey];
            if (days) {
                // Every day
                if (days.count == 7) {
                    cell.detailTextLabel.text = @"Every day";
                }
                // Weekdays
                else if (days.count == 5 && ![days containsObject:@"Sunday"] && ![days containsObject:@"Saturday"]) {
                    cell.detailTextLabel.text = @"Weekdays";
                }
                // Weekends
                else if (days.count == 2 && [days containsObject:@"Sunday"] && [days containsObject:@"Saturday"]) {
                    cell.detailTextLabel.text = @"Weekends";
                }
                // Other
                else {
                    NSMutableString *daysString = [NSMutableString stringWithString:@""];
                    for (NSString *day in days) {
                        [daysString appendString:[NSString stringWithFormat:@" %@", [day substringToIndex:3]]];
                    }
                    cell.detailTextLabel.text = [daysString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
            }
            else {
                [[NSUserDefaults standardUserDefaults] setObject:@[@"Wednesday"] forKey:notificationDaysKey];
                cell.detailTextLabel.text = @"Wednesday";
            }
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (indexPath.row == 1) {
            currentValue = @"Enabled";
            self.enabledSwitch = [UISwitch new];
            [self.enabledSwitch setOn:([[NSUserDefaults standardUserDefaults] boolForKey:notificationsEnabledKey])];
            [self.enabledSwitch addTarget:self action:@selector(stateChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = self.enabledSwitch;
            [self.enabledSwitch setOnTintColor:[UIColor blackColor]];
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        [[cell textLabel]setText:currentValue];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row == 0) {
        LBXRepeatViewController *repeatVC = [LBXRepeatViewController new];
        [self.navigationController pushViewController:repeatVC animated:YES];
    }
}

- (void)stateChanged:(id)sender
{
    BOOL state = [sender isOn];
    [[NSUserDefaults standardUserDefaults] setBool:state forKey:notificationsEnabledKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
