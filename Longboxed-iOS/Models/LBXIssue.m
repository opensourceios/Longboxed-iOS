//
//  LBXIssue.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/6/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXIssue.h"

@implementation LBXIssue

- (NSString *)description
{
    return [NSString stringWithFormat:@"\n\nComplete Title: %@\n\nID: %@\n\nPublisher: %@\n\nDescription: %@\n\nRelease Date: %@\n\n", _completeTitle, _longboxedID, _publisher.name, _issueDescription, _releaseDate];
}


@end
