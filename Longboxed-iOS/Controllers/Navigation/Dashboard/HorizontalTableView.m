//
//  HorizontalTableView.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/12/15.
//  Copyright (c) 2015 Longboxed. All rights reserved.
//

#import "HorizontalTableView.h"
#import "HorizontalTableViewCell.h"
#import "LBXIssue.h"
#import "UIImage+LBXCreateImage.h"

#import <UIImageView+AFNetworking.h>
#import <Doppelganger.h>

@interface HorizontalTableView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) NSArray *previousIssuesArray;

@end

@implementation HorizontalTableView

#pragma mark Overrides

- (void)makeHorizontal
{
    self.transform = CGAffineTransformMakeRotation(-M_PI * 0.5);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self makeHorizontal];
        self.userInteractionEnabled = YES;
        self.delegate = self;
        self.dataSource = self;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    if (self)
    {
        [self makeHorizontal];
        self.userInteractionEnabled = YES;
        self.delegate = self;
        self.dataSource = self;
    }
    
    return self;
}

- (void)updateConstraints {
    [self setWidthConstraint:[[UIScreen mainScreen] bounds].size.width];
    [super updateConstraints];
}

#pragma mark Setter Methods

- (void)setIssuesArray:(NSArray *)issuesArray {
    self.previousIssuesArray = _issuesArray;
    _issuesArray = issuesArray;
    [self reloadTableView];
}

#pragma mark Public Methods

- (void)setWidthConstraint:(CGFloat)width {
    
    // Set the width of the horizontal view
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                       attribute:NSLayoutAttributeHeight
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:nil
                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                      multiplier:1.0
                                                        constant:width]];
}

#pragma mark Private Methods

- (void)reloadTableView
{
    // First, reload any cells if the image has changed/appeared
    for (LBXIssue *issue in self.issuesArray) {
        if ([self.previousIssuesArray containsObject:issue]) {
            NSUInteger previousIndex = [self.previousIssuesArray indexOfObject:issue];
            NSUInteger currentIndex = [self.issuesArray indexOfObject:issue];
            LBXIssue *prevIssue = [self.previousIssuesArray objectAtIndex:previousIndex];
            if (previousIndex && [issue.coverImage isEqualToString:prevIssue.coverImage] && issue.issueID == prevIssue.issueID && [self numberOfRowsInSection:0] <= currentIndex && [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0]]) {
                [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:currentIndex inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }
    
    // Then, insert/remove any cells necessary
    if (self.issuesArray.count && self.previousIssuesArray.count) {
        NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:self.issuesArray
                                                    previousArray:self.previousIssuesArray];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self wml_applyBatchChanges:diffs
                              inSection:0
                       withRowAnimation:UITableViewRowAnimationFade];
        });
    }
    else [self reloadData];
}

#pragma mark UITableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.issuesArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 1.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1.0;
}

-(UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

-(UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.frame.size.width/3.6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* CellIdentifier = @"HorizontalTableViewCell";
    HorizontalTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        [tableView registerNib:[UINib nibWithNibName:CellIdentifier bundle:nil] forCellReuseIdentifier:CellIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    LBXIssue *issue = [self.issuesArray objectAtIndex:indexPath.row];
    
    __weak typeof(cell) weakCell = cell;
    [cell.imgView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[UIImage defaultCoverImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (request) {
            [UIView transitionWithView:weakCell.imgView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[weakCell.imgView setImage:image];}
                            completion:NULL];
        }
        else {
            weakCell.imgView.image = image;
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        weakCell.imgView.image = [UIImage defaultCoverImage];
    }];
    
    [cell.label setText:issue.completeTitle];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LBXIssue *issue = [self.issuesArray objectAtIndex:indexPath.row];
    HorizontalTableViewCell *cell = (HorizontalTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    NSDictionary *dict = @{@"issue" : issue,
                           @"image" : cell.imgView.image};
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"pushToIssueWithDict"
     object:self userInfo:dict];
}


@end
