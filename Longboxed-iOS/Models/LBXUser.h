//
//  LBXUser.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/7/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBXUser : NSObject

@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSNumber *userID;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *roles;

@end
