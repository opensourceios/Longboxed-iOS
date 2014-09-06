//
//  LBXTitleServices.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXTitleAndPublisherServices.h"
#import "UIFont+customFonts.h"

#import "NSDate+DateUtilities.h"
#import "UIColor+customColors.h"

#import <UIImageView+AFNetworking.h>
#import <SVProgressHUD.h>

@interface LBXTitleAndPublisherServices ()

@end

@implementation LBXTitleAndPublisherServices

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

// This is for the publisher list
+ (void)setPublisherCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title
{
    cell.titleLabel.text = title.name;
    
    NSString *subtitleString;
    switch ([title.subscribers integerValue]) {
        case 1: {
            subtitleString = [NSString stringWithFormat:@"%@ Subscriber", title.subscribers].uppercaseString;
            break;
        }
        default: {
            subtitleString = [NSString stringWithFormat:@"%@ Subscribers", title.subscribers].uppercaseString;
            break;
        }
    }
    
    if (title.latestIssue != nil) {
        cell.subtitleLabel.text = subtitleString;
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:title.latestIssue.coverImage]] placeholderImage:[UIImage imageNamed:@"loadingCoverTransparent"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
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
    else if (title.latestIssue.title.issueCount == 0) {
        cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
        cell.subtitleLabel.text = subtitleString;
    }
    else {
        cell.latestIssueImageView.image = [UIImage imageNamed:@"loadingCoverTransparent"];
        cell.subtitleLabel.text = subtitleString;
    }
}

// This is for the pull list
+ (void)setPullListCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title
{
    cell.titleLabel.text = title.name;
    NSLog(@"%@", title.latestIssue.completeTitle);
    if (title.latestIssue != nil) {
        NSString *subtitleString = [NSString stringWithFormat:@"%@  •  %@", title.latestIssue.publisher.name, [LBXTitleAndPublisherServices timeSinceLastIssueForTitle:title]];
        
        cell.subtitleLabel.text = [subtitleString uppercaseString];
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:title.latestIssue.coverImage]] placeholderImage:[UIImage imageNamed:@"loadingCoverTransparent"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
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
    else if (title.latestIssue.title.issueCount == 0) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
    }
    else {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"loadingCoverTransparent"];
    }
}

// This is for the title view
+ (void)setTitleCell:(LBXPullListTableViewCell *)cell withIssue:(LBXIssue *)issue
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

+ (void)setLabel:(UILabel *)textView
      withString:(NSString *)string
  inBoundsOfView:(UIView *)view
{
    UIFont *textFont = [UIFont new];
    textFont = [UIFont collectionTitleFont];
    
    textView.font = textFont;
    
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = NSLineBreakByWordWrapping;
    textStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName:textFont, NSParagraphStyleAttributeName: textStyle};
    CGRect bound = [string boundingRectWithSize:CGSizeMake(view.bounds.size.width-30, view.bounds.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    
    textView.numberOfLines = 2;
    textView.bounds = bound;
    textView.text = string;
}

+ (UIImage *)generateImageForPublisher:(LBXPublisher *)publisher size:(CGSize)size
{
    // Set the background color to the gradient
    UIColor *primaryColor;
    if (publisher.primaryColor) {
        primaryColor = [UIColor colorWithHex:publisher.primaryColor];
    }
    else {
        primaryColor = [UIColor lightGrayColor];
    }
    
    UIColor *secondaryColor;
    if (publisher.secondaryColor) {
        secondaryColor = [UIColor colorWithHex:publisher.secondaryColor];
    }
    else {
        secondaryColor = [UIColor lightGrayColor];
    }
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    size_t gradientNumberOfLocations = 2;
    CGFloat gradientLocations[2] = { 0.0, 1.0 };
    CGFloat gradientComponents[8] = {CGColorGetComponents(primaryColor.CGColor)[0], CGColorGetComponents(primaryColor.CGColor)[1], CGColorGetComponents(primaryColor.CGColor)[2], 1.0,     // Start color
        CGColorGetComponents(secondaryColor.CGColor)[0], CGColorGetComponents(secondaryColor.CGColor)[1], CGColorGetComponents(secondaryColor.CGColor)[2], 1.0, };  // End color
    CGGradientRef gradient = CGGradientCreateWithColorComponents (colorspace, gradientComponents, gradientLocations, gradientNumberOfLocations);
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, size.height), 0);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
