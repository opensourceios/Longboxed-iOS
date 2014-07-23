//
//  LBXIssue.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/6/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXIssue.h"

@implementation LBXIssue

@dynamic completeTitle;
@dynamic coverImage;
@dynamic issueDescription;
@dynamic diamondID;
@dynamic issueID;
@dynamic issueNumber;
@dynamic price;
@dynamic publisher;
@dynamic releaseDate;
@dynamic title;

- (NSString *)description
{
    return [NSString stringWithFormat:@"\n\nComplete Title: %@\n\nID: %@\n\nPublisher: %@\n\nDescription: %@\n\nRelease Date: %@\n\n", self.completeTitle, self.issueID, self.publisher.name, self.issueDescription, self.releaseDate];
}


@end
