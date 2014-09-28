//
//  TableViewCell.m
//  Pulse
//
//  Created by Bushra on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LBXBottomTableViewCell.h"
#import "ActualTableViewCell.h"
#import "LBXDashboardViewController.h"
#import "LBXIssue.h"

#import <UIImageView+AFNetworking.h>

@implementation LBXBottomTableViewCell
@synthesize horizontalTableView;
@synthesize contentArray;

- (void)awakeFromNib {
    // Initialization code
    self.horizontalTableView.frame = CGRectMake(self.horizontalTableView.frame.origin.x, self.horizontalTableView.frame.origin.y, 0, self.horizontalTableView.frame.size.height);
    self.horizontalTableView.rowHeight = 200;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTableView)
                                                 name:@"reloadBottomTableView"
                                               object:nil];
}

- (void)reloadTableView
{
    [self.horizontalTableView reloadData];
}

- (NSString *) reuseIdentifier {
    return @"Cell";
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return contentArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ActualTableViewCell";
    ActualTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ActualTableViewCell"
                                                     owner:self options:nil];
        for (id oneObject in nib) if ([oneObject isKindOfClass:[ActualTableViewCell class]])
            cell = (ActualTableViewCell *)oneObject;
    }
    
    LBXIssue *issue = [contentArray objectAtIndex:indexPath.row];
    
    __weak typeof(cell) weakCell = cell;
    [cell.coverImage setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[UIImage imageNamed:@"loadingCoverTransparent"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
        [UIView transitionWithView:weakCell.imageView
                          duration:0.5f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{[weakCell.coverImage setImage:image];}
                        completion:NULL];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        weakCell.coverImage.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
    }];
    
    [cell.titleName setText:issue.completeTitle];
    CGAffineTransform rotate= CGAffineTransformMakeRotation(M_PI_2);
    cell.transform=rotate;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.horizontalTableView.frame.size.height / 1.7;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LBXIssue *issue = [contentArray objectAtIndex:indexPath.row];
    ActualTableViewCell *cell = (ActualTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    NSDictionary *dict = @{@"issue" : issue,
                           @"image" : cell.coverImage.image};
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"pushToIssueWithDict"
     object:self userInfo:dict];
}



@end
