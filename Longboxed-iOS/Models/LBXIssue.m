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
@dynamic alternates;
@dynamic isParent;
@dynamic issueNumber;
@dynamic subtitle;
@dynamic price;
@dynamic publisher;
@dynamic releaseDate;
@dynamic title;

- (NSString *)description
{
    return [NSString stringWithFormat:@"Complete Title: %@\nID: %@\nPublisher: %@\nRelease Date: %@", self.completeTitle, self.issueID, self.publisher.name, self.releaseDate];
}

@end
