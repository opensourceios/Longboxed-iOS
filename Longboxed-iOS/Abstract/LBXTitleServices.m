//
//  LBXTitleServices.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXTitleServices.h"

#import "NSDate+DateUtilities.h"

#import <UIImageView+AFNetworking.h>

@implementation LBXTitleServices

+ (NSString *)timeSinceLastIssueForTitle:(LBXTitle *)title
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title.titleID == %@", title.titleID];
    NSArray *allIssuesArray = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    
    if (allIssuesArray.count != 0) {
        LBXIssue *issue = allIssuesArray[0];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        [formatter setDateFormat:@"MM-dd-yyyy"];
        NSString *timeStamp = [formatter stringFromDate:issue.releaseDate];
        NSDate *gmtReleaseDate = [formatter dateFromString:timeStamp];
        // Add four hours because date is set to 20:00 by RestKit
        NSTimeInterval secondsInFourHours = 4 * 60 * 60;
        return [NSString stringWithFormat:@"%@", [NSDate fuzzyTimeBetweenStartDate:[gmtReleaseDate dateByAddingTimeInterval:secondsInFourHours] andEndDate:[NSDate date]]];
    }
    return @"";
}

+ (NSNumber *)lastIssueNumberForTitle:(LBXTitle *)title
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title.titleID == %@", title.titleID];
    NSArray *allIssuesArray = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    if (allIssuesArray.count != 0) {
        LBXIssue *issue = allIssuesArray[0];
        return issue.issueNumber;
    }
    return nil;
}

+ (LBXIssue *)lastIssueForTitle:(LBXTitle *)title
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title.titleID == %@", title.titleID];
    NSArray *allIssuesArray = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    if (allIssuesArray.count != 0) {
        return allIssuesArray[0];
    }
    return nil;
}

+ (void)setCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title
{
    if ([LBXTitleServices lastIssueForTitle:title] != nil) {
        LBXIssue *issue = [LBXTitleServices lastIssueForTitle:title];
        NSString *subtitleString = [NSString stringWithFormat:@"%@  •  Issue %@, %@", title.publisher.name, issue.issueNumber, [LBXTitleServices timeSinceLastIssueForTitle:title]];
        
        cell.titleLabel.text = title.name;
        cell.subtitleLabel.text = [subtitleString uppercaseString];
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[UIImage imageNamed:@"clear"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [UIView transitionWithView:cell.imageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[cell.latestIssueImageView setImage:image];}
                            completion:NULL];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            cell.titleLabel.text = title.name;
            cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@  •  No Issues", title.publisher.name] uppercaseString];
            cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
        }];
    }
    else {
        cell.titleLabel.text = title.name;
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@  •  No Issues", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
    }
}

+ (void)setCell:(LBXPullListTableViewCell *)cell withIssue:(LBXIssue *)issue
{
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterLongStyle];
        NSString *subtitleString = [NSString stringWithFormat:@"%@  •  $%@", [formatter stringFromDate:issue.releaseDate], issue.price];
        
        cell.titleLabel.text = issue.completeTitle;
        cell.subtitleLabel.text = [subtitleString uppercaseString];
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[UIImage imageNamed:@"clear"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [UIView transitionWithView:cell.imageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[cell.latestIssueImageView setImage:image];}
                            completion:NULL];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
        }];
}

@end
