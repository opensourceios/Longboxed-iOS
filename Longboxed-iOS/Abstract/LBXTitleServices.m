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
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(title.titleID == %@) AND (isParent == 1)", title.titleID];
    NSArray *initialFind = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    
    // Not all parents are actually the parents (sometimes a variant is a parent due to API bug)
    // so correct this by getting the issue with the shortest title
    // TODO: Get Tim to fix this
    NSMutableArray *correctedArray = [NSMutableArray new];
    for (LBXIssue *issue in initialFind) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(title == %@) AND (issueNumber == %@)", issue.title, issue.issueNumber];
        NSArray *issuesArray = [LBXIssue MR_findAllSortedBy:@"completeTitle" ascending:YES withPredicate:predicate];
        [correctedArray addObject:issuesArray[0]];
    }
    
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:correctedArray];
    
    NSSortDescriptor *sortByIssueID = [NSSortDescriptor sortDescriptorWithKey:@"issueID" ascending:NO];
    NSSortDescriptor *sortByIssueNumber = [NSSortDescriptor sortDescriptorWithKey:@"issueNumber" ascending:NO];
    NSSortDescriptor *sortByIssueReleaseDate = [NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:NO];
    
    // Combine the two
    NSArray *sortDescriptors = @[sortByIssueReleaseDate, sortByIssueNumber, sortByIssueID];
    NSArray *sortedArray = [mutableArray sortedArrayUsingDescriptors:sortDescriptors];

    if (sortedArray.count != 0) {
        return sortedArray[0];
    }
    return nil;
}

// This is for the pull list
+ (void)setCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title
{
    LBXIssue *issue = [self lastIssueForTitle:title];
    cell.titleLabel.text = title.name;
    if (issue != nil) {
        NSString *subtitleString = [NSString stringWithFormat:@"%@  •  %@", title.publisher.name, [LBXTitleServices timeSinceLastIssueForTitle:title]];
        
        cell.subtitleLabel.text = [subtitleString uppercaseString];
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[UIImage imageNamed:@"loadingCoverTransparent"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [UIView transitionWithView:cell.imageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[cell.latestIssueImageView setImage:image];}
                            completion:NULL];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
        }];
    }
    else if (!title.publisher.name) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"Loading..."] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"loadingCoverTransparent"];
    }
    else if (issue.title.issueCount == 0) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
    }
    else {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"loadingCoverTransparent"];
    }
}

// This is for the title view
+ (void)setCell:(LBXPullListTableViewCell *)cell withIssue:(LBXIssue *)issue
{
    NSString *subtitleString = [NSString stringWithFormat:@"%@", [self localTimeZoneStringWithDate:issue.releaseDate]];
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"&#?[a-zA-Z0-9z]+;" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *modifiedTitleString = [regex stringByReplacingMatchesInString:issue.completeTitle options:0 range:NSMakeRange(0, [issue.completeTitle length]) withTemplate:@""];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(issueNumber == %@) AND (title == %@)", issue.issueNumber, issue.title];
    NSArray *initialFind = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@  •  %i variant covers", subtitleString, initialFind.count - 1].uppercaseString;
    if (initialFind.count == 1) {
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@", subtitleString].uppercaseString;
    }
    else if (initialFind.count == 2) {
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@  •  %i variant cover", subtitleString, initialFind.count - 1].uppercaseString;
    }
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@", modifiedTitleString];
    
    
    // For issues without a release date
    if ([subtitleString isEqualToString:@"(null)"]) {
        cell.subtitleLabel.text = @"Release Date Unknown";
    }
    
    // Get the image from the URL and set it
    [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[UIImage imageNamed:@"loadingCoverTransparent"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
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
