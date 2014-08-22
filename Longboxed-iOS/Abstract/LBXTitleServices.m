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
#import <SVProgressHUD.h>

@interface LBXTitleServices ()

@end

@implementation LBXTitleServices

// This is for the pull list view
+ (NSString *)timeSinceLastIssueForTitle:(LBXTitle *)title
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title.titleID == %@", title.titleID];
    NSArray *allIssuesArray = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    
    if (allIssuesArray.count != 0) {
        
        LBXIssue *issue = allIssuesArray[0];
        
        // Get an NSDate with the local time: http://stackoverflow.com/questions/3901474/iphone-nsdate-convert-gmt-to-local-time
        NSDate* localDateTime = [NSDate dateWithTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT]
                                                   sinceDate:[NSDate date]];
        return [NSString stringWithFormat:@"%@", [NSDate fuzzyTimeBetweenStartDate:issue.releaseDate andEndDate:localDateTime]];
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

+ (NSString *)localTimeZoneStringWithDate:(NSDate *)date
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    [numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numFormatter setMinimumFractionDigits:2];
    return [formatter stringFromDate:date];
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
        NSString *subtitleString = [NSString stringWithFormat:@"%@  •  %@", title.publisher.name, [LBXTitleServices timeSinceLastIssueForTitle:title]];
        
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
            cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@  •  %@ Issues", title.publisher.name, issue.issueNumber] uppercaseString];
            cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
        }];
    }
    else {
        cell.titleLabel.text = title.name;
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
    }
}

// This is for the title view
+ (void)setCell:(LBXPullListTableViewCell *)cell withIssue:(LBXIssue *)issue
{
    NSString *subtitleString = [NSString stringWithFormat:@"%@", [self localTimeZoneStringWithDate:issue.releaseDate]];
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@", issue.completeTitle];
    cell.subtitleLabel.text = [subtitleString uppercaseString];
    
    // For issues without a release date
    if ([subtitleString isEqualToString:@"(null)"]) {
        cell.subtitleLabel.text = @"Release Date Unknown";
    }
    
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
