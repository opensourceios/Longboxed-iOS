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
#import "LBXControllerServices.h"
#import "LBXIssue.h"
#import <Doppelganger.h>

#import "UIImage+LBXCreateImage.h"

#import <UIImageView+AFNetworking.h>

@implementation LBXBottomTableViewCell
@synthesize horizontalTableView;

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
    // First, reload any cells if the image has changed/appeared
    for (LBXIssue *issue in _contentArray) {
        if ([_previousContentArray containsObject:issue]) {
            NSUInteger previousIndex = [_previousContentArray indexOfObject:issue];
            NSUInteger currentIndex = [_contentArray indexOfObject:issue];
            LBXIssue *prevIssue = [_previousContentArray objectAtIndex:previousIndex];
            if (previousIndex && [issue.coverImage isEqualToString:prevIssue.coverImage] && issue.issueID == prevIssue.issueID && [self.horizontalTableView numberOfRowsInSection:0] <= currentIndex && [self.horizontalTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0]]) {
                [self.horizontalTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:currentIndex inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }
    
    // Then, insert/remove any cells necessary
    if (_contentArray.count && _previousContentArray.count) {
        NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:_contentArray
                                                    previousArray:_previousContentArray];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.horizontalTableView wml_applyBatchChanges:diffs
                                                  inSection:0
                                           withRowAnimation:UITableViewRowAnimationFade];
        });
    }
    else [self.horizontalTableView reloadData];
}

- (void)setContentArray:(NSArray *)newContentArray {
    _previousContentArray = _contentArray;
    _contentArray = newContentArray;
}

- (NSString *) reuseIdentifier {
    return @"Cell";
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _contentArray.count;
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
    
    LBXIssue *issue = [_contentArray objectAtIndex:indexPath.row];
    
    __weak typeof(cell) weakCell = cell;
    [cell.coverImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[UIImage defaultCoverImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (request) {
            [UIView transitionWithView:weakCell.coverImageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[weakCell.coverImageView setImage:image];}
                            completion:NULL];
        }
        else {
            weakCell.coverImageView.image = image;
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        weakCell.coverImageView.image = [UIImage defaultCoverImage];
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
    LBXIssue *issue = [_contentArray objectAtIndex:indexPath.row];
    ActualTableViewCell *cell = (ActualTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    NSDictionary *dict = @{@"issue" : issue,
                           @"image" : cell.coverImageView.image};
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"pushToIssueWithDict"
     object:self userInfo:dict];
}



@end
