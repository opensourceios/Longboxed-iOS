//
//  LBXPublisher.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/6/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBXPublisher : NSObject

@property (nonatomic, copy) NSNumber *publisherID;
@property (nonatomic, copy) NSNumber *issueCount;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSNumber *titleCount;

@end
